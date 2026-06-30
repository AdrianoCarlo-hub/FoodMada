// lib/data/datasources/admin/admin_remote_datasource.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:mada_food_app/data/models/commande_model.dart';
import 'package:mada_food_app/core/network/dio_client.dart';
import '../../../domain/entities/restaurant_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../models/restaurant_model.dart';
import '../../models/user_model.dart';

class AdminRemoteDatasource {
  final DioClient _dioClient;

  AdminRemoteDatasource(this._dioClient);

  // ============================================================
  // DASHBOARD STATS
  // ============================================================

  /// Récupère les statistiques du tableau de bord
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _dioClient.dio.get('/api/admin/stats');
      final data = response.data as Map<String, dynamic>;
      return data['data'] ?? {};
    } catch (e) {
      throw Exception('Erreur lors du chargement des statistiques: $e');
    }
  }

  // ============================================================
  // RESTAURANTS
  // ============================================================

  /// Récupère tous les restaurants
  Future<List<RestaurantModel>> getAllRestaurants() async {
    try {
      final response = await _dioClient.dio.get('/api/admin/restaurants');
      final data = response.data as Map<String, dynamic>;
      final list = data['data'] as List? ?? [];
      return list.map((json) => RestaurantModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des restaurants: $e');
    }
  }

  /// Crée un nouveau restaurant
  Future<RestaurantModel?> createRestaurant({
    required String nom,
    required String adresse,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/admin/restaurants',
        data: {
          'nom': nom,
          'adresse': adresse,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return RestaurantModel.fromJson(data['data']);
    } catch (e) {
      throw Exception('Erreur lors de la création du restaurant: $e');
    }
  }

  /// Met à jour le statut d'un restaurant (Ouvert/Fermé)
  Future<bool> updateRestaurantStatus(String id, bool estOuvert) async {
    try {
      final response = await _dioClient.dio.put(
        '/api/admin/restaurants/$id',
        data: {'est_ouvert': estOuvert},
      );
      return true;
    } on DioException catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut: ${e.response?.data?['error'] ?? e.message}');
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }

  /// Met à jour les informations d'un restaurant
  Future<RestaurantModel?> updateRestaurant(String id, {
    required String nom,
    required String adresse,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _dioClient.dio.put(
        '/api/admin/restaurants/$id',
        data: {
          'nom': nom,
          'adresse': adresse,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return RestaurantModel.fromJson(data['data']);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du restaurant: $e');
    }
  }

  /// Supprime un restaurant
  Future<bool> deleteRestaurant(String id) async {
    try {
      await _dioClient.dio.delete('/api/admin/restaurants/$id');
      return true;
    } catch (e) {
      throw Exception('Erreur lors de la suppression du restaurant: $e');
    }
  }

  // ============================================================
  // UTILISATEURS
  // ============================================================

  /// Récupère tous les utilisateurs (avec filtre optionnel par rôle)
  Future<List<UserModel>> getAllUsers({String? role}) async {
    try {
      final url = role != null ? '/api/admin/users?role=$role' : '/api/admin/users';
      final response = await _dioClient.dio.get(url);
      final data = response.data as Map<String, dynamic>;
      final list = data['data'] as List? ?? [];
      return list.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des utilisateurs: $e');
    }
  }

  /// Récupère les restaurateurs disponibles (sans restaurant assigné)
  Future<List<UserModel>> getAvailableRestaurateurs() async {
    try {
      final response = await _dioClient.dio.get('/api/admin/users?role=RESTAURATEUR');
      final data = response.data as Map<String, dynamic>;
      final list = data['data'] as List? ?? [];
      
      return list
          .map((json) => UserModel.fromJson(json))
          .where((user) => user.restaurantId == null || user.restaurantId!.isEmpty)
          .toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des restaurateurs: $e');
    }
  }

  /// Affecte un restaurateur à un restaurant
  Future<bool> assignRestaurateur(String userId, String restaurantId) async {
    try {
      await _dioClient.dio.patch(
        '/api/admin/user/$userId/restaurant',
        data: {'restaurant_id': restaurantId},
      );
      return true;
    } catch (e) {
      throw Exception('Erreur lors de l\'affectation du restaurateur: $e');
    }
  }

  /// Met à jour le rôle d'un utilisateur
  Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      await _dioClient.dio.patch(
        '/api/admin/user/$userId/role',
        data: {'role': newRole},
      );
      return true;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du rôle: $e');
    }
  }

  /// Supprime un utilisateur
  Future<bool> deleteUser(String userId) async {
    try {
      await _dioClient.dio.delete('/api/admin/user/$userId');
      return true;
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'utilisateur: $e');
    }
  }

  /// Met à jour les informations d'un utilisateur (nom, téléphone)
  Future<bool> updateUser(String userId, {required String nom, required String telephone}) async {
    try {
      await _dioClient.dio.put(
        '/api/admin/user/$userId',
        data: {
          'nom': nom,
          'telephone': telephone,
        },
      );
      return true;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'utilisateur: $e');
    }
  }

  /// Crée un restaurateur (via la route d'inscription)
  Future<UserModel> createRestaurateur({
    required String nom,
    required String telephone,
    required String motDePasse,
    required String restaurantId,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/auth/register',
        data: {
          'nom': nom,
          'telephone': telephone,
          'mot_de_passe': motDePasse,
          'role': 'RESTAURATEUR',
          'restaurant_id': restaurantId,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return UserModel.fromJson(data['data']['user']);
    } catch (e) {
      throw Exception('Erreur lors de la création du restaurateur: $e');
    }
  }

// ============================================================
  // COMMANDES
  // ============================================================

  /// Récupère toutes les commandes (pour l'admin)
  Future<List<CommandeModel>> getAllCommandes({String? statut, String? restaurantId}) async {
    try {
      String url = '/api/admin/commandes';
      final params = <String, String>{};
      if (statut != null && statut != 'Toutes') {
        params['statut'] = statut;
      }
      if (restaurantId != null && restaurantId.isNotEmpty) {
        params['restaurant_id'] = restaurantId;
      }
      if (params.isNotEmpty) {
        url += '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      }

      final response = await _dioClient.dio.get(url);
      final data = response.data as Map<String, dynamic>;
      final list = data['data'] as List? ?? [];
      return list.map((json) => CommandeModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des commandes: $e');
    }
  }

  /// Récupère les détails d'une commande spécifique
  Future<CommandeModel?> getCommandeById(String id) async {
    try {
      final response = await _dioClient.dio.get('/api/admin/commandes/$id');
      final data = response.data as Map<String, dynamic>;
      return CommandeModel.fromJson(data['data']);
    } catch (e) {
      throw Exception('Erreur lors du chargement des détails de la commande: $e');
    }
  }

}