// routes/api/restaurateur/plats/[id].dart
import 'dart:io';
import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:madafood_backend/core/security/restaurateur_middleware.dart';
import 'package:madafood_backend/core/database_client.dart';
import 'package:madafood_backend/core/helpers/decoder_helper.dart';
import 'package:madafood_backend/domain/entities/user.dart';
import 'package:madafood_backend/data/models/plat_model.dart';

Handler middleware(Handler handler) {
  return handler.use(restaurateurMiddleware);
}

Future<Response> onRequest(RequestContext context, String id) async {
  final method = context.request.method;

  print('🔍 [PLAT] ===== REQUÊTE REÇUE =====');
  print('🔍 [PLAT] ID: $id');
  print('🔍 [PLAT] Méthode: $method');
  print('🔍 [PLAT] Headers: ${context.request.headers}');

  if (method == HttpMethod.put) {
    return _updatePlat(context, id);
  } else if (method == HttpMethod.delete) {
    return _deletePlat(context, id);
  }

  return Response(
    statusCode: HttpStatus.methodNotAllowed,
    body: 'Méthode non autorisée. Utilisez PUT ou DELETE.',
  );
}

/// ✅ Mettre à jour un plat
Future<Response> _updatePlat(RequestContext context, String id) async {
  try {
    print('🔍 [UPDATE_PLAT] ===== DÉBUT MISE À JOUR =====');
    print('🔍 [UPDATE_PLAT] ID du plat: $id');

    // 1. Récupérer l'utilisateur
    final user = context.read<User?>();
    
    if (user == null) {
      print('❌ [UPDATE_PLAT] User est null');
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Utilisateur non authentifié'},
      );
    }

    final restaurantId = user.restaurantId;

    print('🔍 [UPDATE_PLAT] User: ${user.nom}');
    print('🔍 [UPDATE_PLAT] Restaurant ID: $restaurantId');
    print('🔍 [UPDATE_PLAT] Rôle: ${user.role}');

    if (restaurantId == null || restaurantId.isEmpty) {
      print('❌ [UPDATE_PLAT] Restaurant ID est null ou vide');
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'Restaurant non associé à cet utilisateur',
        },
      );
    }

    // 2. Lire le corps de la requête
    // ✅ IMPORTANT: Lire le body comme String puis le décoder
    final bodyString = await context.request.body();
    print('🔍 [UPDATE_PLAT] Body brut: $bodyString');

    if (bodyString.isEmpty) {
      print('❌ [UPDATE_PLAT] Body est vide');
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'Corps de requête vide'},
      );
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(bodyString) as Map<String, dynamic>;
      print('🔍 [UPDATE_PLAT] Body décodé: $body');
    } catch (e) {
      print('❌ [UPDATE_PLAT] Erreur décodage JSON: $e');
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'JSON invalide: ${e.toString()}'},
      );
    }

    // 3. Extraire et valider les données
    final nom = body['nom'] as String?;
    final description = body['description'] as String?;
    final prix = body['prix'];
    final estDisponible = body['est_disponible'] ?? true;

    print('🔍 [UPDATE_PLAT] nom: "$nom"');
    print('🔍 [UPDATE_PLAT] description: "$description"');
    print('🔍 [UPDATE_PLAT] prix: $prix (type: ${prix.runtimeType})');
    print('🔍 [UPDATE_PLAT] estDisponible: $estDisponible');

    if (nom == null || nom.trim().isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'Le nom du plat est requis'},
      );
    }

    // ✅ Convertir le prix correctement
    double prixDouble;
    if (prix is int) {
      prixDouble = prix.toDouble();
    } else if (prix is double) {
      prixDouble = prix;
    } else if (prix is String) {
      prixDouble = double.tryParse(prix) ?? 0;
    } else if (prix is num) {
      prixDouble = prix.toDouble();
    } else {
      prixDouble = 0;
    }

    print('🔍 [UPDATE_PLAT] prixDouble: $prixDouble');

    if (prixDouble <= 0) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'Le prix doit être supérieur à 0'},
      );
    }

    final dbClient = context.read<DatabaseClient>();

    // 4. Vérifier que le plat existe et appartient au restaurant
    print('🔍 [UPDATE_PLAT] Vérification du plat...');
    final checkResult = await dbClient.pool.execute(
      Sql.named('''
        SELECT id FROM plats 
        WHERE id = @id AND restaurant_id = @rid
      '''),
      parameters: {'id': id, 'rid': restaurantId},
    );

    if (checkResult.isEmpty) {
      print('❌ [UPDATE_PLAT] Plat non trouvé');
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {
          'success': false,
          'error': 'Plat non trouvé ou vous n\'avez pas les droits',
        },
      );
    }

    print('✅ [UPDATE_PLAT] Plat trouvé, mise à jour...');

    // 5. Mettre à jour
    final result = await dbClient.pool.execute(
      Sql.named('''
        UPDATE plats 
        SET nom = @nom, 
            description = @desc, 
            prix = @prix, 
            est_disponible = @dispo
        WHERE id = @id AND restaurant_id = @rid
        RETURNING id, restaurant_id, nom, description, prix, est_disponible, date_creation
      '''),
      parameters: {
        'id': id,
        'rid': restaurantId,
        'nom': nom.trim(),
        'desc': description?.trim(),
        'prix': prixDouble,
        'dispo': estDisponible,
      },
    );

    if (result.isEmpty) {
      print('❌ [UPDATE_PLAT] Échec de la mise à jour (resultat vide)');
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {
          'success': false,
          'error': 'Erreur lors de la mise à jour du plat',
        },
      );
    }

    final row = result.first.toColumnMap();

    print('✅ [UPDATE_PLAT] Plat mis à jour avec succès');
    print('🔍 [UPDATE_PLAT] Résultat: $row');

    // 6. Retourner la réponse
    return Response.json(
      body: {
        'success': true,
        'message': 'Plat mis à jour avec succès',
        'data': {
          'id': row['id'].toString(),
          'restaurant_id': row['restaurant_id'].toString(),
          'nom': row['nom'].toString(),
          'description': row['description']?.toString(),
          'prix': double.tryParse(row['prix'].toString()) ?? 0,
          'est_disponible': row['est_disponible'] ?? true,
          'date_creation': row['date_creation'].toString(),
        },
      },
    );
  } catch (e, stackTrace) {
    print('❌ [UPDATE_PLAT] ERREUR: $e');
    print('📚 [UPDATE_PLAT] Stack: $stackTrace');
    
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Erreur lors de la mise à jour: ${e.toString()}',
      },
    );
  }
}

/// ✅ Supprimer un plat
Future<Response> _deletePlat(RequestContext context, String id) async {
  try {
    print('🔍 [DELETE_PLAT] Suppression du plat: $id');

    final user = context.read<User?>();
    final restaurantId = user?.restaurantId;

    if (restaurantId == null || restaurantId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'Restaurant non associé à cet utilisateur',
        },
      );
    }

    final dbClient = context.read<DatabaseClient>();

    // ✅ Vérifier que le plat appartient au restaurant
    final checkResult = await dbClient.pool.execute(
      Sql.named('''
        SELECT id FROM plats 
        WHERE id = @id AND restaurant_id = @rid
      '''),
      parameters: {'id': id, 'rid': restaurantId},
    );

    if (checkResult.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {
          'success': false,
          'error': 'Plat non trouvé ou vous n\'avez pas les droits',
        },
      );
    }

    // ✅ Supprimer le plat
    await dbClient.pool.execute(
      Sql.named('''
        DELETE FROM plats WHERE id = @id AND restaurant_id = @rid
      '''),
      parameters: {'id': id, 'rid': restaurantId},
    );

    print('✅ [DELETE_PLAT] Plat supprimé avec succès');

    return Response.json(
      body: {
        'success': true,
        'message': 'Plat supprimé avec succès',
      },
    );
  } catch (e) {
    print('❌ [DELETE_PLAT] Erreur: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Erreur lors de la suppression: ${e.toString()}',
      },
    );
  }
}