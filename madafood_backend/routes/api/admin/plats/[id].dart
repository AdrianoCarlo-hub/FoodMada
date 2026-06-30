import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/core/security/admin_middleware.dart';
import 'package:madafood_backend/domain/repositories/plat_repository.dart';
import 'package:madafood_backend/data/models/plat_model.dart'; // Import nécessaire pour PlatModel.fromJson

Handler middleware(Handler handler) {
  return handler.use(adminMiddleware);
}

Future<Response> onRequest(RequestContext context, String id) async {
  final platRepo = context.read<PlatRepository>();

  // 1. Gestion de la Suppression (DELETE)
  if (context.request.method == HttpMethod.delete) {
    final success = await platRepo.deletePlat(id);
    return success 
      ? Response.json(body: {'success': true, 'message': 'Plat supprimé'})
      : Response.json(
          statusCode: HttpStatus.notFound, 
          body: {'error': 'Plat introuvable'},
        );
  }

  // 2. Gestion de la Modification (PUT)
  if (context.request.method == HttpMethod.put) {
    try {
      final body = await context.request.json() as Map<String, dynamic>;
      final plat = PlatModel.fromJson(body);
      
      final success = await platRepo.updatePlat(id, plat);
      
      return success
          ? Response.json(body: {'success': true, 'message': 'Plat mis à jour'})
          : Response.json(
              statusCode: HttpStatus.notFound, 
              body: {'error': 'Plat introuvable'},
            );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.badRequest, 
        body: {'error': 'Erreur de format JSON : $e'},
      );
    }
  }

  // 3. Méthode non supportée
  return Response(statusCode: HttpStatus.methodNotAllowed);
}