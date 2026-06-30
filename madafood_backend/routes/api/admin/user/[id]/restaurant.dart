// routes/api/admin/user/[id]/restaurant.dart
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/core/security/admin_middleware.dart';
import 'package:madafood_backend/core/database_client.dart';
import 'package:postgres/postgres.dart';

Handler middleware(Handler handler) => handler.use(adminMiddleware);

Future<Response> onRequest(RequestContext context, String id) async {
  print('🔍 [ASSIGN_RESTAURANT] User ID: $id');
  print('🔍 [ASSIGN_RESTAURANT] Méthode: ${context.request.method}');

  if (context.request.method != HttpMethod.patch) {
    return Response(
      statusCode: HttpStatus.methodNotAllowed,
      body: 'Méthode non autorisée. Utilisez PATCH.',
    );
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    print('🔍 [ASSIGN_RESTAURANT] Body: $body');

    final restaurantId = body['restaurant_id'] as String?;

    if (restaurantId == null || restaurantId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'restaurant_id est requis'},
      );
    }

    final dbClient = context.read<DatabaseClient>();

    // ✅ Vérifier que l'utilisateur existe et est un restaurateur
    final userCheck = await dbClient.pool.execute(
      Sql.named('''
        SELECT id, role FROM utilisateurs 
        WHERE id = @id AND role = 'RESTAURATEUR'
      '''),
      parameters: {'id': id},
    );

    if (userCheck.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'Utilisateur non trouvé ou n\'est pas un restaurateur'},
      );
    }

    // ✅ Vérifier que le restaurant existe
    final restaurantCheck = await dbClient.pool.execute(
      Sql.named('SELECT id FROM restaurants WHERE id = @restaurant_id'),
      parameters: {'restaurant_id': restaurantId},
    );

    if (restaurantCheck.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'Restaurant non trouvé'},
      );
    }

    // ✅ Affecter le restaurateur au restaurant
    final result = await dbClient.pool.execute(
      Sql.named('''
        UPDATE utilisateurs 
        SET restaurant_id = @restaurant_id
        WHERE id = @id
        RETURNING id, nom, restaurant_id
      '''),
      parameters: {
        'id': id,
        'restaurant_id': restaurantId,
      },
    );

    if (result.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'success': false, 'error': 'Erreur lors de l\'affectation'},
      );
    }

    final user = result.first.toColumnMap();

    return Response.json(
      body: {
        'success': true,
        'message': 'Restaurateur affecté avec succès',
        'data': {
          'id': user['id'].toString(),
          'nom': user['nom'].toString(),
          'restaurant_id': user['restaurant_id']?.toString(),
        },
      },
    );
  } catch (e) {
    print('❌ Erreur assignRestaurateur: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': 'Erreur: ${e.toString()}'},
    );
  }
}