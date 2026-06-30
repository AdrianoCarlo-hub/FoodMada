// lib/domain/repositories/restaurateur/i_restaurateur_repository.dart
import '../../entities/plat.dart';
import '../../entities/commande.dart';
import '../../entities/restaurant_entity.dart';

abstract class IRestaurateurRepository {
  Future<Map<String, dynamic>> getStats();
  Future<List<RestaurantEntity>> getRestaurants();
  Future<List<Plat>> getPlats();
  Future<Plat?> createPlat(Plat plat);
  Future<Plat?> updatePlat(String id, Plat plat);
  Future<bool> deletePlat(String id);
  Future<List<Commande>> getCommandes();
  Future<Commande?> getCommandeById(String id);
  Future<Commande?> updateOrderStatus(String commandeId, String newStatus);
}
