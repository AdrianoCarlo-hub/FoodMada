import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  final user = context.read<Map<String, dynamic>?>();
  final db = context.read<Connection>();

  // GET - Récupérer tous les plats
  if (context.request.method == HttpMethod.get) {
    final result = await db.execute(
      'SELECT p.id, p.restaurant_id, p.nom, p.description, p.prix, '
      'p.categorie, p.est_disponible, p.date_creation, '
      'r.nom as restaurant_nom '
      'FROM plats p '
      'LEFT JOIN restaurants r ON p.restaurant_id = r.id '
      'ORDER BY p.date_creation DESC',
    );

    final plats = result.map((row) {
      return {
        'id': row[0],
        'restaurant_id': row[1],
        'nom': row[2],
        'description': row[3],
        'prix': (row[4] as num).toDouble(),
        'categorie': row[5] ?? '',
        'est_disponible': row[6] ?? true,
        'date_creation': row[7]?.toString(),
        'restaurant_nom': row[8],
      };
    }).toList();

    return Response.json(statusCode: 200, body: plats);
  }

  // POST - Créer un nouveau plat
  if (context.request.method == HttpMethod.post) {
    try {
      final body = await context.request.json() as Map<String, dynamic>;

      if (user == null) {
        return Response.json(
          statusCode: 401,
          body: {'error': 'Non authentifié'},
        );
      }

      final role = user['role'] as String?;
      if (role != 'restaurateur' && role != 'admin') {
        return Response.json(
          statusCode: 403,
          body: {'error': 'Accès non autorisé'},
        );
      }

      // Validation
      final restaurantId = body['restaurant_id']?.toString();
      final nom = body['nom']?.toString();
      final prix = body['prix'];

      if (restaurantId == null || restaurantId.isEmpty) {
        return Response.json(
          statusCode: 400,
          body: {'error': 'Le restaurant_id est requis'},
        );
      }

      if (nom == null || nom.isEmpty) {
        return Response.json(
          statusCode: 400,
          body: {'error': 'Le nom du plat est requis'},
        );
      }

      if (prix == null) {
        return Response.json(
          statusCode: 400,
          body: {'error': 'Le prix est requis'},
        );
      }

      final prixDouble = prix is num ? prix.toDouble() : double.tryParse(prix.toString());
      if (prixDouble == null || prixDouble <= 0) {
        return Response.json(
          statusCode: 400,
          body: {'error': 'Le prix doit être un nombre positif'},
        );
      }

      // ✅ Insertion sans image_url
      final result = await db.execute(
        'INSERT INTO plats '
        '(restaurant_id, nom, description, prix, categorie, est_disponible) '
        'VALUES (@restaurant_id, @nom, @description, @prix, @categorie, @est_disponible) '
        'RETURNING id, date_creation',
        parameters: {
          'restaurant_id': restaurantId,
          'nom': nom,
          'description': body['description']?.toString() ?? '',
          'prix': prixDouble,
          'categorie': body['categorie']?.toString() ?? '',
          'est_disponible': body['est_disponible'] ?? true,
        },
      );

      final id = result.first[0];
      final dateCreation = result.first[1];

      return Response.json(
        statusCode: 201,
        body: {
          'success': true,
          'id': id,
          'date_creation': dateCreation?.toString(),
          'message': 'Plat créé avec succès',
        },
      );
    } catch (e) {
      print('Erreur création plat: $e');
      return Response.json(
        statusCode: 500,
        body: {'error': 'Erreur lors de la création du plat: $e'},
      );
    }
  }

  return Response.json(
    statusCode: 405,
    body: {'error': 'Méthode non autorisée. Utilisez GET ou POST'},
  );
}