// lib/data/repositories/restaurateur/restaurateur_repository_impl.dart
import '../../../domain/entities/plat.dart';
import '../../../domain/entities/commande.dart';
import '../../../domain/entities/restaurant_entity.dart';
import '../../../domain/repositories/restaurateur/i_restaurateur_repository.dart';
import '../../datasources/restaurateur/restaurateur_remote_datasource.dart';

class RestaurateurRepositoryImpl implements IRestaurateurRepository {
  final RestaurateurRemoteDatasource _datasource;

  RestaurateurRepositoryImpl(this._datasource);

  // === DASHBOARD ===
  @override
  Future<Map<String, dynamic>> getStats() async {
    return await _datasource.getStats();
  }

  // === RESTAURANTS ===
  @override
  Future<List<RestaurantEntity>> getRestaurants() async {
    return await _datasource.getRestaurants();
  }

  // === PLATS ===
  @override
  Future<List<Plat>> getPlats() async {
    return await _datasource.getPlats();
  }

  @override
  Future<Plat?> createPlat(Plat plat) async {
    return await _datasource.createPlat(plat);
  }

  @override
  Future<Plat?> updatePlat(String id, Plat plat) async {
    return await _datasource.updatePlat(id, plat);
  }

  @override
  Future<bool> deletePlat(String id) async {
    return await _datasource.deletePlat(id);
  }



  // === COMMANDES ===
  @override
  Future<List<Commande>> getCommandes() async {
    return await _datasource.getCommandes();
  }

  @override
  Future<Commande?> getCommandeById(String id) async {
    return await _datasource.getCommandeById(id);
  }

  @override
  Future<Commande?> updateOrderStatus(String commandeId, String newStatus) async {
    return await _datasource.updateOrderStatus(commandeId, newStatus);
  }
}
