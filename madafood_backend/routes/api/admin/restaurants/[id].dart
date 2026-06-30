// routes/api/admin/restaurants/[id].dart
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/core/security/admin_middleware.dart';
import 'package:madafood_backend/core/database_client.dart';
import 'package:madafood_backend/data/models/restaurant_model.dart';
import 'package:postgres/postgres.dart';

Handler middleware(Handler handler) {
  return handler.use(adminMiddleware);
}

Future<Response> onRequest(RequestContext context, String id) async {
  final method = context.request.method;

  // ✅ PUT : Mettre à jour un restaurant (statut ou infos)
  if (method == HttpMethod.put) {
    return _updateRestaurant(context, id);
  }
  
  // ✅ DELETE : Supprimer un restaurant
  if (method == HttpMethod.delete) {
    return _deleteRestaurant(context, id);
  }

  return Response(
    statusCode: HttpStatus.methodNotAllowed,
    body: 'Méthode non autorisée. Utilisez PUT ou DELETE.',
  );
}

Future<Response> _updateRestaurant(RequestContext context, String id) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    print('🔍 [UPDATE_RESTAURANT] ID: $id');
    print('🔍 [UPDATE_RESTAURANT] Body: $body');

    final dbClient = context.read<DatabaseClient>();

    // ✅ Vérifier si le restaurant existe
    final checkResult = await dbClient.pool.execute(
      Sql.named('SELECT id FROM restaurants WHERE id = @id'),
      parameters: {'id': id},
    );

    if (checkResult.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'Restaurant non trouvé'},
      );
    }

    // ✅ Construire la requête dynamiquement
    // Si seul 'est_ouvert' est présent, ne mettre à jour que le statut
    // Sinon, mettre à jour toutes les infos
    final hasOnlyStatus = body.keys.length == 1 && body.containsKey('est_ouvert');

    String sql;
    Map<String, dynamic> params = {'id': id};

    if (hasOnlyStatus) {
      // ✅ Mise à jour du statut uniquement
      final estOuvert = body['est_ouvert'] as bool;
      sql = '''
        UPDATE restaurants SET est_ouvert = @est_ouvert
        WHERE id = @id
        RETURNING *
      ''';
      params['est_ouvert'] = estOuvert;
    } else {
      // ✅ Mise à jour complète
      final nom = body['nom'] as String?;
      final adresse = body['adresse'] as String?;
      final latitude = body['latitude'] as double?;
      final longitude = body['longitude'] as double?;

      // ✅ Vérifier les champs obligatoires
      if (nom == null || nom.trim().isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': 'Le nom est requis'},
        );
      }

      if (adresse == null || adresse.trim().isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': 'L\'adresse est requise'},
        );
      }

      sql = '''
        UPDATE restaurants SET
          nom = @nom,
          adresse = @adresse,
          latitude = @latitude,
          longitude = @longitude
        WHERE id = @id
        RETURNING *
      ''';
      params['nom'] = nom.trim();
      params['adresse'] = adresse.trim();
      params['latitude'] = latitude;
      params['longitude'] = longitude;
    }

    final result = await dbClient.pool.execute(
      Sql.named(sql),
      parameters: params,
    );

    if (result.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'Erreur lors de la mise à jour'},
      );
    }

    final restaurant = RestaurantModel.fromJson(result.first.toColumnMap());

    return Response.json(
      body: {
        'success': true,
        'message': hasOnlyStatus ? 'Statut mis à jour avec succès' : 'Restaurant mis à jour avec succès',
        'data': restaurant.toJson(),
      },
    );
  } catch (e) {
    print('❌ Erreur updateRestaurant: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': 'Erreur: ${e.toString()}'},
    );
  }
}

Future<Response> _deleteRestaurant(RequestContext context, String id) async {
  try {
    final dbClient = context.read<DatabaseClient>();

    // ✅ Vérifier si le restaurant existe
    final checkResult = await dbClient.pool.execute(
      Sql.named('SELECT id FROM restaurants WHERE id = @id'),
      parameters: {'id': id},
    );

    if (checkResult.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'Restaurant non trouvé'},
      );
    }

    // ✅ Supprimer le restaurant (les plats seront supprimés en cascade)
    await dbClient.pool.execute(
      Sql.named('DELETE FROM restaurants WHERE id = @id'),
      parameters: {'id': id},
    );

    return Response.json(
      body: {
        'success': true,
        'message': 'Restaurant supprimé avec succès',
      },
    );
  } catch (e) {
    print('❌ Erreur deleteRestaurant: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': 'Erreur: ${e.toString()}'},
    );
  }
}