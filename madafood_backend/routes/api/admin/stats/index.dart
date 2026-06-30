// routes/api/admin/stats/index.dart
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/core/security/admin_middleware.dart';
import 'package:madafood_backend/core/database_client.dart';

Handler middleware(Handler handler) {
  return handler.use(adminMiddleware);
}

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final dbClient = context.read<DatabaseClient>();
    
    // 1. Nombre total de restaurants
    final restaurantsResult = await dbClient.pool.execute(
      'SELECT COUNT(*) as total FROM restaurants'
    );
    final totalRestaurants = int.tryParse(restaurantsResult.first.toColumnMap()['total']?.toString() ?? '0') ?? 0;

    // 2. Nombre total d'utilisateurs
    final usersResult = await dbClient.pool.execute(
      'SELECT COUNT(*) as total FROM utilisateurs'
    );
    final totalUsers = int.tryParse(usersResult.first.toColumnMap()['total']?.toString() ?? '0') ?? 0;

    // 3. Nombre total de commandes
    final ordersResult = await dbClient.pool.execute(
      'SELECT COUNT(*) as total FROM commandes'
    );
    final totalOrders = int.tryParse(ordersResult.first.toColumnMap()['total']?.toString() ?? '0') ?? 0;

    // 4. Chiffre d'affaires total
    final revenueResult = await dbClient.pool.execute(
      "SELECT COALESCE(SUM(prix_total), 0) as total FROM commandes WHERE statut = 'LIVREE'"
    );
    final totalRevenue = double.tryParse(revenueResult.first.toColumnMap()['total']?.toString() ?? '0') ?? 0;

    return Response.json(
      body: {
        'success': true,
        'data': {
          'total_restaurants': totalRestaurants,
          'total_users': totalUsers,
          'total_orders': totalOrders,
          'total_revenue': totalRevenue,
        }
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': e.toString(),
      },
    );
  }
}