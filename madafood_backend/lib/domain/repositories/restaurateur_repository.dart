import 'package:madafood_backend/domain/entities/plat.dart';
import 'package:madafood_backend/domain/entities/commande.dart';

abstract class RestaurateurRepository {
  Future<List<Plat>> getPlatsByRestaurant(String restaurantId);
  Future<List<Commande>> getCommandesByRestaurant(String restaurantId);
}