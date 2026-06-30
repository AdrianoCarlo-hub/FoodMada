// lib/data/datasources/restaurateur/restaurateur_remote_datasource.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../domain/entities/plat.dart';
import '../../../domain/entities/commande.dart';
import '../../../domain/entities/restaurant_entity.dart';
import '../../models/plat_model.dart';
import '../../models/commande_model.dart';
import '../../models/restaurant_model.dart';

class RestaurateurRemoteDatasource {
  final DioClient _dioClient;

  RestaurateurRemoteDatasource(this._dioClient);

  // === DASHBOARD ===
  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _dioClient.dio.get('/api/restaurateur/stats');
      final data = response.data as Map<String, dynamic>;
      return data['data'] ?? {};
    } catch (e) {
      throw Exception('Erreur lors du chargement des statistiques: $e');
    }
  }

  // === RESTAURANTS ===
  Future<List<RestaurantEntity>> getRestaurants() async {
    try {
      final response = await _dioClient.dio.get('/api/restaurateur/restaurants');
      final data = response.data as Map<String, dynamic>;
      final list = data['data'] as List? ?? [];
      return list.map((json) => RestaurantModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des restaurants: $e');
    }
  }

  // === PLATS ===
  Future<List<Plat>> getPlats() async {
    try {
      final response = await _dioClient.dio.get('/api/restaurateur/plats');
      final data = response.data as Map<String, dynamic>;
      final list = data['plats'] as List? ?? [];
      return list.map((json) => PlatModel.fromJson(json)).toList();
    } catch (e) {
      print('Erreur getPlats: $e');
      throw Exception('Erreur lors du chargement des plats: $e');
    }
  }

  Future<Plat?> createPlat(Plat plat) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/restaurateur/plats',
        data: {
          'nom': plat.nom,
          'description': plat.description,
          'prix': plat.prix,
          'est_disponible': plat.estDisponible,
          'categorie': plat.categorie,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return PlatModel.fromJson(data['data']);
    } catch (e) {
      print('Erreur createPlat: $e');
      throw Exception('Erreur lors de la creation du plat: $e');
    }
  }

  Future<Plat?> updatePlat(String id, Plat plat) async {
    try {
      final response = await _dioClient.dio.put(
        '/api/restaurateur/plats/$id',
        data: {
          'nom': plat.nom,
          'description': plat.description,
          'prix': plat.prix,
          'est_disponible': plat.estDisponible,
          'categorie': plat.categorie,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return PlatModel.fromJson(data['data']);
    } catch (e) {
      print('Erreur updatePlat: $e');
      throw Exception('Erreur lors de la mise a jour du plat: $e');
    }
  }

  Future<bool> deletePlat(String id) async {
    try {
      await _dioClient.dio.delete('/api/restaurateur/plats/$id');
      return true;
    } catch (e) {
      print('Erreur deletePlat: $e');
      throw Exception('Erreur lors de la suppression du plat: $e');
    }
  }

  // === COMMANDES ===
  Future<List<Commande>> getCommandes() async {
    try {
      final response = await _dioClient.dio.get('/api/restaurateur/commandes');
      final data = response.data as Map<String, dynamic>;
      final list = data['commandes'] as List? ?? [];
      return list.map((json) => CommandeModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des commandes: $e');
    }
  }

  Future<Commande?> getCommandeById(String id) async {
    try {
      final response = await _dioClient.dio.get('/api/restaurateur/commandes/$id');
      final data = response.data as Map<String, dynamic>;
      return CommandeModel.fromJson(data);
    } catch (e) {
      throw Exception('Erreur lors du chargement de la commande: $e');
    }
  }

  Future<Commande?> updateOrderStatus(String commandeId, String newStatus) async {
    try {
      // Utiliser print standard sans caracteres speciaux
      print('[updateOrderStatus] Commande: $commandeId, Nouveau statut: $newStatus');
      
      final response = await _dioClient.dio.post(
        '/api/restaurateur/commandes/$commandeId',
        data: {'statut': newStatus},
      );
      
      print('Reponse: ${response.statusCode}');
      final data = response.data as Map<String, dynamic>;
      return CommandeModel.fromJson(data['data']);
    } on DioException catch (e) {
      print('Erreur Dio: ${e.response?.statusCode} - ${e.response?.data}');
      throw Exception('Erreur lors de la mise a jour du statut: ${e.response?.data?['error'] ?? e.message}');
    } catch (e) {
      print('Erreur: $e');
      throw Exception('Erreur lors de la mise a jour du statut: $e');
    }
  }
}