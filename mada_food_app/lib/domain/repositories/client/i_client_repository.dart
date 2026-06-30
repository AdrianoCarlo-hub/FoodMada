// lib/domain/repositories/client/i_client_repository.dart
import '../../entities/restaurant_entity.dart';
import '../../entities/plat.dart';
import '../../entities/commande.dart';
import '../../entities/user_entity.dart';

abstract class IClientRepository {
  // Restaurants
  Future<List<RestaurantEntity>> getRestaurants();
  Future<RestaurantEntity?> getRestaurantById(String id);
  
  // Plats
  Future<List<Plat>> getPlatsByRestaurant(String restaurantId);
  
  // Commandes
  Future<Commande> createOrder({
    required String clientId,
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required double fraisLivraison,
    String? adresseLivraison,
    String? modePaiement,
  });
  Future<List<Commande>> getOrderHistory(String clientId);
  Future<Commande?> getOrderById(String id);
  
  // Profil
  Future<UserEntity?> getProfile(String userId);
}