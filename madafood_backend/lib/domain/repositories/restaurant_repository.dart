import 'package:madafood_backend/domain/entities/restaurant.dart';

abstract class RestaurantRepository {
  /// Récupère la liste de tous les restaurants
  Future<List<Restaurant>> getAllRestaurants();

  /// Récupère un restaurant par son ID
  Future<Restaurant?> getRestaurantById(String id);

  /// Crée un nouveau restaurant
  Future<Restaurant?> createRestaurant({
    required String nom,
    required String adresse,
    double? latitude,
    double? longitude,
  });
  
  /// Met à jour le statut d'ouverture d'un restaurant
  Future<Restaurant?> updateStatus(String id, bool estOuvert);
}