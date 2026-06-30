import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/core/database_client.dart';
import 'package:madafood_backend/core/security/auth_middleware.dart';
import 'package:madafood_backend/domain/entities/user.dart';
import 'package:postgres/postgres.dart';

Handler middleware(Handler handler) {
  return handler.use(authMiddleware());
}

Future<Response> onRequest(RequestContext context) async {
  // ✅ Utiliser read au lieu de maybeRead
  final user = context.read<User?>();
  final dbClient = context.read<DatabaseClient>();

  // POST - Créer une commande
  if (context.request.method == HttpMethod.post) {
    try {
      final body = await context.request.json() as Map<String, dynamic>;

      if (user == null) {
        return Response.json(
          statusCode: 401,
          body: {'error': 'Non authentifié'},
        );
      }

      final userId = user.id;
      final clientId = body['client_id']?.toString() ?? userId;
      final restaurantId = body['restaurant_id']?.toString();
      final items = body['items'] as List? ?? [];
      final modePaiement = body['mode_paiement']?.toString();

      // Validation
      if (restaurantId == null || restaurantId.isEmpty) {
        return Response.json(
          statusCode: 400,
          body: {'error': 'Le restaurant_id est requis'},
        );
      }

      if (items.isEmpty) {
        return Response.json(
          statusCode: 400,
          body: {'error': 'La commande doit contenir au moins un article'},
        );
      }

      // Calculer le total
      double prixTotal = 0;
      final List<Map<String, dynamic>> lignes = [];

      for (final item in items) {
        final platId = item['plat_id']?.toString();
        final quantite = item['quantite'] as num? ?? 1;

        if (platId == null || platId.isEmpty) {
          return Response.json(
            statusCode: 400,
            body: {'error': 'plat_id est requis pour chaque article'},
          );
        }

        // Récupérer le prix et le nom du plat
        final platResult = await dbClient.pool.execute(
          Sql.named('SELECT prix, nom FROM plats WHERE id = @pid'),
          parameters: {'pid': platId},
        );

        if (platResult.isEmpty) {
          return Response.json(
            statusCode: 400,
            body: {'error': 'Plat non trouvé: $platId'},
          );
        }

        final prix = double.tryParse(platResult.first[0].toString()) ?? 0;
        final nomPlat = platResult.first[1].toString();
        final sousTotal = prix * quantite;
        prixTotal += sousTotal;

        lignes.add({
          'plat_id': platId,
          'nom_plat': nomPlat,
          'quantite': quantite,
          'prix_unitaire': prix,
        });
      }

      // Insérer la commande
      final result = await dbClient.pool.execute(
        Sql.named('''
          INSERT INTO commandes 
          (client_id, restaurant_id, prix_total, methode_paiement, statut, date_creation)
          VALUES (@client_id, @restaurant_id, @prix_total, @methode_paiement, 'EN_ATTENTE', CURRENT_TIMESTAMP)
          RETURNING id, date_creation
        '''),
        parameters: {
          'client_id': clientId,
          'restaurant_id': restaurantId,
          'prix_total': prixTotal,
          'methode_paiement': modePaiement ?? 'CARTE',
        },
      );

      final commandeId = result.first[0].toString();
      final dateCreation = result.first[1];

      // Insérer les lignes de commande
      for (final ligne in lignes) {
        await dbClient.pool.execute(
          Sql.named('''
            INSERT INTO lignes_commande 
            (commande_id, plat_id, quantite, prix_unitaire)
            VALUES (@commande_id, @plat_id, @quantite, @prix_unitaire)
          '''),
          parameters: {
            'commande_id': commandeId,
            'plat_id': ligne['plat_id'],
            'quantite': ligne['quantite'],
            'prix_unitaire': ligne['prix_unitaire'],
          },
        );
      }

      // Récupérer la commande complète
      final commandeResult = await dbClient.pool.execute(
        Sql.named('''
          SELECT c.id, c.client_id, c.restaurant_id, c.prix_total, c.methode_paiement,
                 c.statut::text, c.date_creation, r.nom as restaurant_nom,
                 u.nom as client_nom
          FROM commandes c
          LEFT JOIN restaurants r ON c.restaurant_id = r.id
          LEFT JOIN utilisateurs u ON c.client_id = u.id
          WHERE c.id = @cid
        '''),
        parameters: {'cid': commandeId},
      );

      if (commandeResult.isEmpty) {
        return Response.json(
          statusCode: 404,
          body: {'error': 'Commande non trouvée'},
        );
      }

      final commandeRow = commandeResult.first;
      final map = commandeRow.toColumnMap();

      // Récupérer les lignes de commande avec le nom via la jointure
      final lignesResult = await dbClient.pool.execute(
        Sql.named('''
          SELECT l.id, l.plat_id, l.quantite, l.prix_unitaire, p.nom as nom_plat
          FROM lignes_commande l
          LEFT JOIN plats p ON l.plat_id = p.id
          WHERE l.commande_id = @cid
        '''),
        parameters: {'cid': commandeId},
      );

      final itemsList = lignesResult.map((row) {
        final lMap = row.toColumnMap();
        return {
          'id': lMap['id'].toString(),
          'plat_id': lMap['plat_id'].toString(),
          'nom_plat': lMap['nom_plat']?.toString() ?? 'Plat',
          'quantite': int.tryParse(lMap['quantite'].toString()) ?? 1,
          'prix_unitaire': double.tryParse(lMap['prix_unitaire'].toString() ?? '0') ?? 0,
        };
      }).toList();

      return Response.json(
        statusCode: 201,
        body: {
          'success': true,
          'data': {
            'id': map['id'].toString(),
            'client_id': map['client_id'].toString(),
            'restaurant_id': map['restaurant_id'].toString(),
            'prix_total': double.tryParse(map['prix_total']?.toString() ?? '0') ?? 0,
            'methode_paiement': map['methode_paiement']?.toString(),
            'statut': map['statut']?.toString() ?? 'EN_ATTENTE',
            'date_creation': map['date_creation'].toString(),
            'restaurant_nom': map['restaurant_nom']?.toString(),
            'client_nom': map['client_nom']?.toString(),
            'items': itemsList,
          },
          'message': 'Commande créée avec succès',
        },
      );
    } catch (e, stack) {
      print('❌ Erreur création commande: $e');
      print('��� Stack: $stack');
      return Response.json(
        statusCode: 500,
        body: {'error': 'Erreur lors de la création de la commande: $e'},
      );
    }
  }

  // GET - Récupérer les commandes du client
  if (context.request.method == HttpMethod.get) {
    // Vérifier si c'est une requête pour une commande spécifique
    final pathSegments = context.request.uri.pathSegments;
    if (pathSegments.length > 1 && pathSegments.last.isNotEmpty && pathSegments.last != 'commandes') {
      return await _getCommandeById(context, user, dbClient);
    }

    try {
      if (user == null) {
        return Response.json(
          statusCode: 401,
          body: {'error': 'Non authentifié'},
        );
      }

      final userId = user.id;
      final clientId = context.request.uri.queryParameters['client_id'] ?? userId;

      final result = await dbClient.pool.execute(
        Sql.named('''
          SELECT c.id, c.client_id, c.restaurant_id, c.prix_total, c.methode_paiement,
                 c.statut::text, c.date_creation, r.nom as restaurant_nom,
                 u.nom as client_nom
          FROM commandes c
          LEFT JOIN restaurants r ON c.restaurant_id = r.id
          LEFT JOIN utilisateurs u ON c.client_id = u.id
          WHERE c.client_id = @client_id
          ORDER BY c.date_creation DESC
        '''),
        parameters: {'client_id': clientId},
      );

      final commandes = result.map((row) {
        final map = row.toColumnMap();
        return {
          'id': map['id'].toString(),
          'client_id': map['client_id'].toString(),
          'restaurant_id': map['restaurant_id'].toString(),
          'prix_total': double.tryParse(map['prix_total']?.toString() ?? '0') ?? 0,
          'methode_paiement': map['methode_paiement']?.toString(),
          'statut': map['statut']?.toString() ?? 'EN_ATTENTE',
          'date_creation': map['date_creation'].toString(),
          'restaurant_nom': map['restaurant_nom']?.toString(),
          'client_nom': map['client_nom']?.toString(),
        };
      }).toList();

      return Response.json(
        statusCode: 200,
        body: {
          'success': true,
          'data': commandes,
        },
      );
    } catch (e, stack) {
      print('❌ Erreur récupération commandes: $e');
      print('��� Stack: $stack');
      return Response.json(
        statusCode: 500,
        body: {'error': 'Erreur lors de la récupération des commandes: $e'},
      );
    }
  }

  return Response.json(
    statusCode: 405,
    body: {'error': 'Méthode non autorisée. Utilisez GET ou POST'},
  );
}

// ✅ Fonction pour récupérer une commande par ID
Future<Response> _getCommandeById(
  RequestContext context,
  User? user,
  DatabaseClient dbClient,
) async {
  try {
    final commandeId = context.request.uri.pathSegments.last;

    if (user == null) {
      return Response.json(
        statusCode: 401,
        body: {'error': 'Non authentifié'},
      );
    }

    // Récupérer la commande
    final commandeResult = await dbClient.pool.execute(
      Sql.named('''
        SELECT c.id, c.client_id, c.restaurant_id, c.prix_total, c.methode_paiement,
               c.statut::text, c.date_creation, r.nom as restaurant_nom,
               u.nom as client_nom
        FROM commandes c
        LEFT JOIN restaurants r ON c.restaurant_id = r.id
        LEFT JOIN utilisateurs u ON c.client_id = u.id
        WHERE c.id = @cid AND c.client_id = @client_id
      '''),
      parameters: {
        'cid': commandeId,
        'client_id': user.id,
      },
    );

    if (commandeResult.isEmpty) {
      return Response.json(
        statusCode: 404,
        body: {'error': 'Commande non trouvée'},
      );
    }

    final commandeRow = commandeResult.first;
    final map = commandeRow.toColumnMap();

    // Récupérer les lignes de commande
    final lignesResult = await dbClient.pool.execute(
      Sql.named('''
        SELECT l.id, l.plat_id, l.quantite, l.prix_unitaire, p.nom as nom_plat
        FROM lignes_commande l
        LEFT JOIN plats p ON l.plat_id = p.id
        WHERE l.commande_id = @cid
      '''),
      parameters: {'cid': commandeId},
    );

    final itemsList = lignesResult.map((row) {
      final lMap = row.toColumnMap();
      return {
        'id': lMap['id'].toString(),
        'plat_id': lMap['plat_id'].toString(),
        'nom_plat': lMap['nom_plat']?.toString() ?? 'Plat',
        'quantite': int.tryParse(lMap['quantite'].toString()) ?? 1,
        'prix_unitaire': double.tryParse(lMap['prix_unitaire'].toString() ?? '0') ?? 0,
      };
    }).toList();

    return Response.json(
      statusCode: 200,
      body: {
        'success': true,
        'data': {
          'id': map['id'].toString(),
          'client_id': map['client_id'].toString(),
          'restaurant_id': map['restaurant_id'].toString(),
          'prix_total': double.tryParse(map['prix_total']?.toString() ?? '0') ?? 0,
          'methode_paiement': map['methode_paiement']?.toString(),
          'statut': map['statut']?.toString() ?? 'EN_ATTENTE',
          'date_creation': map['date_creation'].toString(),
          'restaurant_nom': map['restaurant_nom']?.toString(),
          'client_nom': map['client_nom']?.toString(),
          'items': itemsList,
        },
      },
    );
  } catch (e, stack) {
    print('❌ Erreur récupération commande: $e');
    print('��� Stack: $stack');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Erreur lors de la récupération de la commande: $e'},
    );
  }
}
