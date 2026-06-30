import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:madafood_backend/core/security/auth_middleware.dart';
import 'package:madafood_backend/core/security/restaurateur_middleware.dart';
import 'package:madafood_backend/core/database_client.dart';
import 'package:madafood_backend/domain/entities/user.dart';

Handler middleware(Handler handler) {
  return handler.use(restaurateurMiddleware);
}

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Méthode non autorisée'},
    );
  }

  try {
    final user = context.read<User?>();
    final dbClient = context.read<DatabaseClient>();

    if (user == null) {
      return Response.json(
        statusCode: 401,
        body: {'error': 'Non authentifié'},
      );
    }

    // ✅ Récupérer le restaurant du restaurateur connecté
    final userId = user.id;
    
    final result = await dbClient.pool.execute(
      Sql.named('''
        SELECT r.id, r.nom, r.adresse, r.latitude, r.longitude, r.est_ouvert, r.date_creation
        FROM restaurants r
        INNER JOIN utilisateurs u ON u.restaurant_id = r.id
        WHERE u.id = @user_id
      '''),
      parameters: {'user_id': userId},
    );

    final restaurants = result.map((row) {
      return {
        'id': row[0].toString(),
        'nom': row[1].toString(),
        'adresse': row[2].toString(),
        'latitude': row[3] != null ? double.tryParse(row[3].toString()) : null,
        'longitude': row[4] != null ? double.tryParse(row[4].toString()) : null,
        'est_ouvert': row[5] ?? true,
        'date_creation': row[6].toString(),
        'proprietaire_id': userId,  // ✅ Ajouter l'ID du propriétaire
      };
    }).toList();

    return Response.json(
      statusCode: 200,
      body: {
        'success': true,
        'data': restaurants,
      },
    );
  } catch (e, stack) {
    print('❌ Erreur getRestaurateurRestaurants: $e');
    print('��� Stack: $stack');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Erreur lors de la récupération des restaurants: $e'},
    );
  }
}
