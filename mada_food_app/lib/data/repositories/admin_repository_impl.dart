// lib/data/repositories/admin_repository_impl.dart
import '../../domain/entities/restaurant_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/commande.dart';
import '../../domain/repositories/admin/admin_repository.dart';
import '../datasources/admin/admin_remote_datasource.dart';
import '../models/commande_model.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDatasource _datasource;

  AdminRepositoryImpl(this._datasource);

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    return await _datasource.getDashboardStats();
  }

  @override
  Future<List<RestaurantEntity>> getAllRestaurants() async {
    final models = await _datasource.getAllRestaurants();
    return models;
  }

  @override
  Future<RestaurantEntity?> createRestaurant({
    required String nom,
    required String adresse,
    double? latitude,
    double? longitude,
  }) async {
    return await _datasource.createRestaurant(
      nom: nom,
      adresse: adresse,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<bool> updateRestaurantStatus(String id, bool estOuvert) async {
    return await _datasource.updateRestaurantStatus(id, estOuvert);
  }

  @override
  Future<RestaurantEntity?> updateRestaurant(String id, {
    required String nom,
    required String adresse,
    double? latitude,
    double? longitude,
  }) async {
    return await _datasource.updateRestaurant(id,
      nom: nom,
      adresse: adresse,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<bool> deleteRestaurant(String id) async {
    return await _datasource.deleteRestaurant(id);
  }

  @override
  Future<List<UserEntity>> getAvailableRestaurateurs() async {
    return await _datasource.getAvailableRestaurateurs();
  }

  @override
  Future<bool> assignRestaurateur(String userId, String restaurantId) async {
    return await _datasource.assignRestaurateur(userId, restaurantId);
  }

  @override
  Future<List<UserEntity>> getAllUsers({String? role}) async {
    final models = await _datasource.getAllUsers(role: role);
    return models;
  }

  @override
  Future<bool> updateUserRole(String userId, String newRole) async {
    return await _datasource.updateUserRole(userId, newRole);
  }

  @override
  Future<bool> deleteUser(String userId) async {
    return await _datasource.deleteUser(userId);
  }

  @override
  Future<bool> updateUser(String userId, {required String nom, required String telephone}) async {
    return await _datasource.updateUser(userId, nom: nom, telephone: telephone);
  }

  @override
  Future<UserEntity> createRestaurateur({
    required String nom,
    required String telephone,
    required String motDePasse,
    required String restaurantId,
  }) async {
    return await _datasource.createRestaurateur(
      nom: nom,
      telephone: telephone,
      motDePasse: motDePasse,
      restaurantId: restaurantId,
    );
  }

  //  Commandes
  @override
  Future<List<Commande>> getAllCommandes({String? statut, String? restaurantId}) async {
    final models = await _datasource.getAllCommandes(statut: statut, restaurantId: restaurantId);
    return models;
  }

  @override
  Future<Commande?> getCommandeById(String id) async {
    return await _datasource.getCommandeById(id);
  }
}