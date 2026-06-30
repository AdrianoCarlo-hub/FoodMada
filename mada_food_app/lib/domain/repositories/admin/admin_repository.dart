// lib/domain/repositories/admin/admin_repository.dart
import '../../entities/restaurant_entity.dart';
import '../../entities/user_entity.dart';
import '../../entities/commande.dart';

abstract class AdminRepository {
  // Dashboard KPIs
  Future<Map<String, dynamic>> getDashboardStats();

  // Restaurants
  Future<List<RestaurantEntity>> getAllRestaurants();
  Future<RestaurantEntity?> createRestaurant({
    required String nom,
    required String adresse,
    double? latitude,
    double? longitude,
  });
  Future<bool> updateRestaurantStatus(String id, bool estOuvert);
  Future<RestaurantEntity?> updateRestaurant(String id, {
    required String nom,
    required String adresse,
    double? latitude,
    double? longitude,
  });
  Future<bool> deleteRestaurant(String id);
  Future<List<UserEntity>> getAvailableRestaurateurs();
  Future<bool> assignRestaurateur(String userId, String restaurantId);

  // Users
  Future<List<UserEntity>> getAllUsers({String? role});
  Future<bool> updateUserRole(String userId, String newRole);
  Future<bool> deleteUser(String userId);
  Future<bool> updateUser(String userId, {required String nom, required String telephone});

  // Create Restaurateur
  Future<UserEntity> createRestaurateur({
    required String nom,
    required String telephone,
    required String motDePasse,
    required String restaurantId,
  });

  //  Commandes
  Future<List<Commande>> getAllCommandes({String? statut, String? restaurantId});
  Future<Commande?> getCommandeById(String id);
}