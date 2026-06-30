import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/core/security/restaurateur_middleware.dart';
import 'package:madafood_backend/core/database_client.dart';
import 'package:madafood_backend/core/helpers/decoder_helper.dart';
import 'package:madafood_backend/domain/entities/user.dart';
import 'package:postgres/postgres.dart';

Handler middleware(Handler handler) {
  return handler.use(restaurateurMiddleware);
}

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final user = context.read<User?>();
    final restaurantId = user?.restaurantId;

    if (restaurantId == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'Restaurant non associé à cet utilisateur',
        },
      );
    }

    final dbClient = context.read<DatabaseClient>();
    final result = await dbClient.pool.execute(
      Sql.named('''
        SELECT c.id, c.client_id, c.restaurant_id, c.prix_total, c.methode_paiement, 
               c.statut::text, c.date_creation,
               u.nom as client_nom, u.telephone as client_telephone
        FROM commandes c
        LEFT JOIN utilisateurs u ON c.client_id = u.id
        WHERE c.restaurant_id = @rid 
        ORDER BY c.date_creation DESC
      '''),
      parameters: {'rid': restaurantId},
    );

    final commandes = result.map((row) {
      final map = row.toColumnMap();
      return {
        'id': map['id'].toString(),
        'client_id': map['client_id'].toString(),
        'restaurant_id': map['restaurant_id'].toString(),
        'prix_total': double.tryParse(map['prix_total']?.toString() ?? '0') ?? 0,
        'methode_paiement': map['methode_paiement']?.toString(),
        'statut': decodeStatus(map['statut']),
        'date_creation': map['date_creation'] is DateTime
            ? (map['date_creation'] as DateTime).toIso8601String()
            : map['date_creation'].toString(),
        'client_nom': map['client_nom']?.toString(),
        'client_telephone': map['client_telephone']?.toString(),
      };
    }).toList();

    return Response.json(
      body: {
        'success': true,
        'commandes': commandes,
      },
    );
  } catch (e, stackTrace) {
    print('❌ Erreur getRestaurateurCommandes: $e');
    print('📚 Stack: $stackTrace');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      },
    );
  }
}