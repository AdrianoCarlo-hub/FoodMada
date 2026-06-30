// lib/data/datasources/client/client_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../domain/entities/restaurant_entity.dart';
import '../../../domain/entities/plat.dart';
import '../../../domain/entities/commande.dart';
import '../../../domain/entities/user_entity.dart';
import '../../models/restaurant_model.dart';
import '../../models/plat_model.dart';
import '../../models/commande_model.dart';
import '../../models/user_model.dart';

class ClientRemoteDatasource {
  final DioClient _dioClient;

  ClientRemoteDatasource(this._dioClient);

  // === RESTAURANTS ===
  Future<List<RestaurantModel>> getRestaurants() async {
    try {
      final response = await _dioClient.dio.get('/api/restaurants');
      final data = response.data as Map<String, dynamic>;
      final list = data['data'] as List? ?? [];
      return list.map((json) => RestaurantModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des restaurants: $e');
    }
  }

  Future<RestaurantModel?> getRestaurantById(String id) async {
    try {
      final response = await _dioClient.dio.get('/api/restaurants/$id');
      final data = response.data as Map<String, dynamic>;
      return RestaurantModel.fromJson(data['data']);
    } catch (e) {
      throw Exception('Erreur lors du chargement du restaurant: $e');
    }
  }

  // === PLATS ===
  Future<List<PlatModel>> getPlatsByRestaurant(String restaurantId) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/restaurants/$restaurantId/plats'
      );
      final data = response.data as Map<String, dynamic>;
      final list = data['data'] as List? ?? [];
      return list.map((json) => PlatModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des plats: $e');
    }
  }

  // === COMMANDES ===
  Future<CommandeModel> createOrder({
    required String clientId,
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required double fraisLivraison,
    String? adresseLivraison,
    String? modePaiement,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/commandes',
        data: {
          'client_id': clientId,
          'restaurant_id': restaurantId,
          'items': items,
          'frais_livraison': fraisLivraison,
          'adresse_livraison': adresseLivraison,
          'mode_paiement': modePaiement,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return CommandeModel.fromJson(data['data']);
    } catch (e) {
      throw Exception('Erreur lors de la création de la commande: $e');
    }
  }

  Future<List<CommandeModel>> getOrderHistory(String clientId) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/commandes?client_id=$clientId'
      );
      final data = response.data as Map<String, dynamic>;
      final list = data['data'] as List? ?? [];
      return list.map((json) => CommandeModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement de l\'historique: $e');
    }
  }

  Future<CommandeModel?> getOrderById(String id) async {
    try {
      final response = await _dioClient.dio.get('/api/commandes/$id');
      final data = response.data as Map<String, dynamic>;
      return CommandeModel.fromJson(data['data']);
    } catch (e) {
      throw Exception('Erreur lors du chargement de la commande: $e');
    }
  }

  // === PROFIL ===
  Future<UserModel?> getProfile(String userId) async {
    try {
      final response = await _dioClient.dio.get('/api/client/profile');
      final data = response.data as Map<String, dynamic>;
      return UserModel.fromJson(data['data']);
    } catch (e) {
      throw Exception('Erreur lors du chargement du profil: $e');
    }
  }
}