// routes/api/restaurants/index.dart

import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/domain/repositories/restaurant_repository.dart';
import 'package:madafood_backend/data/models/restaurant_model.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final restaurantRepo = context.read<RestaurantRepository>();
    final restaurants = await restaurantRepo.getAllRestaurants();
    
    // Modification ici : on utilise fromEntity au lieu du cast direct "as RestaurantModel"
    final jsonList = restaurants
        .map((r) => RestaurantModel.fromEntity(r).toJson())
        .toList();

    return Response.json(
      body: {
        'success': true,
        'message': 'Liste des restaurants récupérée avec succès',
        'data': jsonList,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Erreur lors de la récupération des restaurants : $e',
      },
    );
  }
}