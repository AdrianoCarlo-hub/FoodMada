// lib/data/repositories/client/client_repository_impl.dart
import '../../../domain/entities/restaurant_entity.dart';
import '../../../domain/entities/plat.dart';
import '../../../domain/entities/commande.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/client/i_client_repository.dart';
import '../../datasources/client/client_remote_datasource.dart';

class ClientRepositoryImpl implements IClientRepository {
  final ClientRemoteDatasource _datasource;

  ClientRepositoryImpl(this._datasource);

  @override
  Future<List<RestaurantEntity>> getRestaurants() async {
    final models = await _datasource.getRestaurants();
    return models;
  }

  @override
  Future<RestaurantEntity?> getRestaurantById(String id) async {
    return await _datasource.getRestaurantById(id);
  }

  @override
  Future<List<Plat>> getPlatsByRestaurant(String restaurantId) async {
    final models = await _datasource.getPlatsByRestaurant(restaurantId);
    return models;
  }

  @override
  Future<Commande> createOrder({
    required String clientId,
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required double fraisLivraison,
    String? adresseLivraison,
    String? modePaiement,
  }) async {
    return await _datasource.createOrder(
      clientId: clientId,
      restaurantId: restaurantId,
      items: items,
      fraisLivraison: fraisLivraison,
      adresseLivraison: adresseLivraison,
      modePaiement: modePaiement,
    );
  }

  @override
  Future<List<Commande>> getOrderHistory(String clientId) async {
    final models = await _datasource.getOrderHistory(clientId);
    return models;
  }

  @override
  Future<Commande?> getOrderById(String id) async {
    return await _datasource.getOrderById(id);
  }

  @override
  Future<UserEntity?> getProfile(String userId) async {
    return await _datasource.getProfile(userId);
  }
}