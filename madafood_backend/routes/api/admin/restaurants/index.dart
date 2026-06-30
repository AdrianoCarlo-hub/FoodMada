// routes/api/admin/restaurants/index.dart
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/core/security/admin_middleware.dart';
import 'package:madafood_backend/domain/repositories/restaurant_repository.dart';
import 'package:madafood_backend/data/models/restaurant_model.dart';

Handler middleware(Handler handler) {
  return handler.use(adminMiddleware);
}

Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method;

  // ✅ Gérer GET et POST
  if (method == HttpMethod.get) {
    return _getRestaurants(context);
  } else if (method == HttpMethod.post) {
    return _createRestaurant(context);
  }

  return Response(
    statusCode: HttpStatus.methodNotAllowed,
    body: 'Méthode non autorisée. Utilisez GET ou POST.',
  );
}

// ✅ NOUVEAU : Récupérer tous les restaurants
Future<Response> _getRestaurants(RequestContext context) async {
  try {
    final repo = context.read<RestaurantRepository>();
    final restaurants = await repo.getAllRestaurants();

    final jsonList = restaurants
        .map((r) => RestaurantModel.fromEntity(r).toJson())
        .toList();

    return Response.json(
      body: {
        'success': true,
        'data': jsonList,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Erreur lors du chargement des restaurants : $e',
      },
    );
  }
}

// ✅ EXISTANT : Créer un restaurant
Future<Response> _createRestaurant(RequestContext context) async {
  final repo = context.read<RestaurantRepository>();
  final body = await context.request.json() as Map<String, dynamic>;

  try {
    final restaurant = await repo.createRestaurant(
      nom: body['nom'] as String,
      adresse: body['adresse'] as String,
      latitude: double.tryParse(body['latitude']?.toString() ?? ''),
      longitude: double.tryParse(body['longitude']?.toString() ?? ''),
    );

    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'success': true,
        'data': restaurant != null 
            ? RestaurantModel.fromEntity(restaurant).toJson() 
            : null,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': e.toString()},
    );
  }
}