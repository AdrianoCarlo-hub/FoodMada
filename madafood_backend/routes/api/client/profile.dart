import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/domain/entities/user.dart';
import 'package:madafood_backend/core/security/auth_middleware.dart';

// Appliquez votre middleware d'authentification ici
Handler middleware(Handler handler) => handler.use(authMiddleware());

Future<Response> onRequest(RequestContext context) async {
  final user = context.read<User?>();
  
  if (user == null) {
    return Response.json(statusCode: 401, body: {'error': 'Non autorisé'});
  }

  return Response.json(body: {
    'success': true,
    'data': {
      'id': user.id,
      'nom': user.nom,
      'telephone': user.telephone,
    }
  });
}