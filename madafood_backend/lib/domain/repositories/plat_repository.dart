import 'package:madafood_backend/domain/entities/plat.dart';

abstract class PlatRepository {
  Future<List<Plat>> getPlatsPaginated({String? restaurantId, int page, int limit});
  Future<List<Plat>> getPlatsByRestaurant(String restaurantId);
  Future<Plat?> createPlat(Plat plat);
  Future<bool> deletePlat(String id);
  Future<bool> updatePlat(String id, Plat plat);
}