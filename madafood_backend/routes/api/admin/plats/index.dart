import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/core/security/admin_middleware.dart';
import 'package:madafood_backend/domain/repositories/plat_repository.dart';
import 'package:madafood_backend/data/models/plat_model.dart';

// Protection : seul un utilisateur avec le rôle ADMIN peut accéder à ces routes
Handler middleware(Handler handler) {
  return handler.use(adminMiddleware);
}

Future<Response> onRequest(RequestContext context) async {
  final platRepo = context.read<PlatRepository>();

  // Routage basé sur la méthode HTTP
  switch (context.request.method) {
    case HttpMethod.get:
      return _getPlats(context, platRepo);
    case HttpMethod.post:
      return _createPlat(context, platRepo);
    default:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

/// Gère la récupération paginée des plats
Future<Response> _getPlats(RequestContext context, PlatRepository repo) async {
  final query = context.request.uri.queryParameters;
  final page = int.tryParse(query['page'] ?? '1') ?? 1;
  final limit = int.tryParse(query['limit'] ?? '10') ?? 10;
  final restaurantId = query['restaurant_id'];

  final plats = await repo.getPlatsPaginated(
    restaurantId: restaurantId,
    page: page,
    limit: limit,
  );

  // Conversion en JSON
  final jsonList = plats.map((p) {
    // Si votre Plat est un modèle (PlatModel), on appelle toJson() directement
    // Si c'est une entité, assurez-vous d'utiliser une méthode de conversion
    return (p is PlatModel) ? p.toJson() : PlatModel.fromEntity(p).toJson();
  }).toList();

  return Response.json(body: {
    'data': jsonList, 
    'meta': {'page': page, 'limit': limit}
  });
}

/// Gère la création d'un nouveau plat
Future<Response> _createPlat(RequestContext context, PlatRepository repo) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final plat = PlatModel.fromJson(body);
    
    await repo.createPlat(plat);

    return Response.json(
      statusCode: HttpStatus.created,
      body: {'success': true, 'message': 'Plat ajouté avec succès'},
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': 'Erreur lors de l\'ajout : $e'},
    );
  }
}