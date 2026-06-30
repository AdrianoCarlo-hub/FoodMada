// routes/api/restaurateur/plats/index.dart
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/core/security/restaurateur_middleware.dart';
import 'package:madafood_backend/core/database_client.dart';
import 'package:madafood_backend/data/models/plat_model.dart';
import 'package:madafood_backend/domain/entities/user.dart';
import 'package:postgres/postgres.dart';

Handler middleware(Handler handler) {
  return handler.use(restaurateurMiddleware);
}

Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method;

  if (method == HttpMethod.get) {
    return _getPlats(context);
  } else if (method == HttpMethod.post) {
    return _createPlat(context);
  }

  return Response(
    statusCode: HttpStatus.methodNotAllowed,
    body: 'M√©thode non autoris√©e. Utilisez GET ou POST.',
  );
}

// GET : R√©cup√©rer tous les plats du restaurant
Future<Response> _getPlats(RequestContext context) async {
  try {
    final user = context.read<User?>();
    
    print('Ì¥ç [GET Plats] User: ${user?.nom ?? 'null'}');
    print('Ì¥ç [GET Plats] Restaurant ID: ${user?.restaurantId ?? 'null'}');
    
    // ‚úÖ R√©cup√©rer le restaurant_id depuis l'utilisateur
    final restaurantId = user?.restaurantId;

    if (restaurantId == null || restaurantId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'Restaurant non associ√© √† cet utilisateur',
          'plats': [],
        },
      );
    }

    final dbClient = context.read<DatabaseClient>();
    final result = await dbClient.pool.execute(
      Sql.named('''
        SELECT id, restaurant_id, nom, description, prix, 
               est_disponible, date_creation
        FROM plats 
        WHERE restaurant_id = @rid 
        ORDER BY date_creation DESC
      '''),
      parameters: {'rid': restaurantId},
    );

    final plats = result.map((row) {
      return {
        'id': row[0].toString(),
        'restaurant_id': row[1].toString(),
        'nom': row[2].toString(),
        'description': row[3]?.toString(),
        'prix': double.tryParse(row[4].toString()) ?? 0,
        'est_disponible': row[5] ?? true,
        'date_creation': row[6].toString(),
      };
    }).toList();

    return Response.json(
      body: {
        'success': true,
        'plats': plats,
      },
    );
  } catch (e, stack) {
    print('‚ùå Erreur getPlats: $e');
    print('Ì≥ö Stack: $stack');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Erreur lors de la r√©cup√©ration des plats: $e',
        'plats': [],
      },
    );
  }
}

// POST : Cr√©er un nouveau plat
Future<Response> _createPlat(RequestContext context) async {
  try {
    final user = context.read<User?>();
    final restaurantId = user?.restaurantId;

    if (restaurantId == null || restaurantId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'Restaurant non associ√© √† cet utilisateur',
        },
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;
    final dbClient = context.read<DatabaseClient>();

    final nom = body['nom'] as String?;
    final prix = body['prix'];

    if (nom == null || nom.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'Le nom du plat est requis'},
      );
    }

    final prixDouble = prix is num ? prix.toDouble() : double.tryParse(prix.toString());
    if (prixDouble == null || prixDouble <= 0) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'Le prix doit √™tre un nombre positif'},
      );
    }

    final result = await dbClient.pool.execute(
      Sql.named('''
        INSERT INTO plats (restaurant_id, nom, description, prix, est_disponible)
        VALUES (@rid, @nom, @desc, @prix, @dispo)
        RETURNING id, date_creation
      '''),
      parameters: {
        'rid': restaurantId,
        'nom': nom,
        'desc': body['description'] as String?,
        'prix': prixDouble,
        'dispo': body['est_disponible'] ?? true,
      },
    );

    if (result.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {
          'success': false,
          'error': '√âchec de la cr√©ation du plat',
        },
      );
    }

    final id = result.first[0].toString();
    final dateCreation = result.first[1];

    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'success': true,
        'data': {
          'id': id,
          'restaurant_id': restaurantId,
          'nom': nom,
          'description': body['description'] as String?,
          'prix': prixDouble,
          'est_disponible': body['est_disponible'] ?? true,
          'date_creation': dateCreation.toString(),
        },
      },
    );
  } catch (e, stack) {
    print('‚ùå Erreur createPlat: $e');
    print('Ì≥ö Stack: $stack');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Erreur lors de la cr√©ation du plat: $e',
      },
    );
  }
}
