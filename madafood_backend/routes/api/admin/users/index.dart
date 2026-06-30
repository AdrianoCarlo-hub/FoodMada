// routes/api/admin/users/index.dart
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/core/security/admin_middleware.dart';
import 'package:madafood_backend/core/database_client.dart';
import 'package:madafood_backend/data/models/user_model.dart';
import 'package:postgres/postgres.dart';

Handler middleware(Handler handler) {
  return handler.use(adminMiddleware);
}

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final dbClient = context.read<DatabaseClient>();
    final params = context.request.uri.queryParameters;
    final role = params['role'];
    
    String sql = 'SELECT * FROM utilisateurs';
    if (role != null) {
      sql += " WHERE role = '$role'";
    }
    sql += ' ORDER BY date_creation DESC';

    final result = await dbClient.pool.execute(Sql.named(sql));
    
    final users = result.map((row) => UserModel.fromJson(row.toColumnMap())).toList();

    return Response.json(
      body: {
        'success': true,
        'data': users.map((user) => user.toJson()).toList(),
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