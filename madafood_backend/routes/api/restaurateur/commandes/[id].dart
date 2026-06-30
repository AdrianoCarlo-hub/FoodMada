// routes/api/restaurateur/commandes/[id].dart
import 'dart:io';
import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:madafood_backend/core/security/restaurateur_middleware.dart';
import 'package:madafood_backend/core/database_client.dart';
import 'package:madafood_backend/core/helpers/decoder_helper.dart';
import 'package:madafood_backend/domain/entities/user.dart';

Handler middleware(Handler handler) {
  return handler.use(restaurateurMiddleware);
}

Future<Response> onRequest(RequestContext context, String id) async {
  final method = context.request.method;

  if (method == HttpMethod.get) {
    return _getCommande(context, id);
  } else if (method == HttpMethod.post) {
    return _updateStatus(context, id);
  }

  return Response(
    statusCode: HttpStatus.methodNotAllowed,
    body: 'Méthode non autorisée. Utilisez GET ou POST.',
  );
}

/// ✅ Fonction de décodage robuste locale
String _safeDecode(dynamic value) {
  if (value == null) return '';
  if (value is String) return value.trim().toUpperCase();
  if (value is UndecodedBytes) {
    try {
      return value.asString.trim().toUpperCase();
    } catch (_) {
      try {
        return utf8.decode(value.bytes, allowMalformed: true).trim().toUpperCase();
      } catch (_) {
        return value.toString().trim().toUpperCase();
      }
    }
  }
  if (value is List<int>) {
    try {
      return utf8.decode(value, allowMalformed: true).trim().toUpperCase();
    } catch (_) {
      return String.fromCharCodes(value);
    }
  }
  return value.toString().trim().toUpperCase();
}

Future<Response> _getCommande(RequestContext context, String id) async {
  try {
    final user = context.read<User?>();
    final restaurantId = user?.restaurantId;

    if (restaurantId == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Restaurant non associé'},
      );
    }

    final dbClient = context.read<DatabaseClient>();
    final result = await dbClient.pool.execute(
      Sql.named('''
        SELECT id, client_id, restaurant_id, prix_total, methode_paiement, 
               statut::text, date_creation
        FROM commandes 
        WHERE id = @id AND restaurant_id = @rid
      '''),
      parameters: {'id': id, 'rid': restaurantId},
    );

    if (result.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Commande non trouvée'},
      );
    }

    final map = result.first.toColumnMap();
    
    final commandeData = {
      'id': map['id'].toString(),
      'client_id': map['client_id'].toString(),
      'restaurant_id': map['restaurant_id'].toString(),
      'prix_total': double.tryParse(map['prix_total']?.toString() ?? '0') ?? 0,
      'methode_paiement': map['methode_paiement']?.toString(),
      'statut': _safeDecode(map['statut']),
      'date_creation': map['date_creation'] is DateTime
          ? (map['date_creation'] as DateTime).toIso8601String()
          : map['date_creation'].toString(),
      'total': double.tryParse(map['prix_total']?.toString() ?? '0') ?? 0,
    };

    return Response.json(
      body: {
        'success': true,
        'data': commandeData,
      },
    );
  } catch (e, stackTrace) {
    print('❌ Erreur getCommande: $e');
    print('📚 Stack: $stackTrace');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': e.toString()},
    );
  }
}

Future<Response> _updateStatus(RequestContext context, String id) async {
  try {
    final user = context.read<User?>();
    final restaurantId = user?.restaurantId;

    if (restaurantId == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Restaurant non associé'},
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;
    final nouveauStatutBrut = body['statut'] as String?;

    if (nouveauStatutBrut == null || nouveauStatutBrut.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Le statut est requis'},
      );
    }

    final nouveauStatut = nouveauStatutBrut.trim().toUpperCase();

    const statutsAutorises = [
      'EN_ATTENTE', 
      'PREPARATION', 
      'EN_ROUTE',
      'LIVREE', 
      'ANNULEE'
    ];
    
    if (!statutsAutorises.contains(nouveauStatut)) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false, 
          'error': 'Statut invalide. Statuts autorisés: ${statutsAutorises.join(', ')}',
          'statut_recu': nouveauStatut,
        },
      );
    }

    final dbClient = context.read<DatabaseClient>();

    try {
      final result = await dbClient.pool.runTx((tx) async {
        // ✅ SELECT avec CAST explicite et FOR UPDATE
        final checkResult = await tx.execute(
          Sql.named('''
            SELECT id, statut::text FROM commandes 
            WHERE id = @id AND restaurant_id = @rid
            FOR UPDATE
          '''),
          parameters: {'id': id, 'rid': restaurantId},
        );

        if (checkResult.isEmpty) {
          throw Exception('Commande non trouvée');
        }

        // ✅ Décoder le statut avec _safeDecode
        final currentStatut = _safeDecode(checkResult.first.toColumnMap()['statut']);
        
        print('🔍 [updateStatus] Statut actuel: "$currentStatut" -> Nouveau: "$nouveauStatut"');

        // ✅ TRANSITIONS AUTORISÉES
        final transitions = {
          'EN_ATTENTE': ['PREPARATION', 'ANNULEE'],
          'PREPARATION': ['EN_ROUTE', 'ANNULEE'],
          'EN_ROUTE': ['LIVREE', 'ANNULEE'],
          'LIVREE': [],
          'ANNULEE': [],
        };

        final allowedTransitions = transitions[currentStatut] ?? [];
        if (!allowedTransitions.contains(nouveauStatut)) {
          throw Exception('Transition invalide: $currentStatut -> $nouveauStatut');
        }

        // ✅ UPDATE
        final updateResult = await tx.execute(
          Sql.named('''
            UPDATE commandes 
            SET statut = @statut::statut_commande_enum
            WHERE id = @id
            RETURNING id, statut::text
          '''),
          parameters: {
            'id': id,
            'statut': nouveauStatut,
          },
        );

        if (updateResult.isEmpty) {
          throw Exception('Échec de la mise à jour');
        }

        return updateResult.first.toColumnMap();
      });

      return Response.json(
        body: {
          'success': true,
          'message': 'Statut mis à jour avec succès',
          'data': {
            'id': result['id'].toString(),
            'statut': _safeDecode(result['statut']),
          },
        },
      );
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      
      if (errorMessage.contains('Transition invalide')) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': errorMessage},
        );
      }
      
      if (errorMessage.contains('Commande non trouvée')) {
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'success': false, 'error': errorMessage},
        );
      }

      throw Exception(errorMessage);
    }
  } catch (e, stackTrace) {
    print('❌ Erreur updateStatus: $e');
    print('📚 Stack: $stackTrace');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': e.toString()},
    );
  }
}