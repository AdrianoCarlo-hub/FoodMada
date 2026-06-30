// lib/presentation/providers/restaurant_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../domain/entities/restaurant_entity.dart';
import '../../domain/repositories/restaurateur/i_restaurateur_repository.dart';
import '../../data/datasources/restaurateur/restaurateur_remote_datasource.dart';
import '../../data/repositories/restaurateur/restaurateur_repository_impl.dart';

// ============================================
// 1. PROVIDER DU REPOSITORY
// ============================================

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

final restaurantRepositoryProvider = Provider<IRestaurateurRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final datasource = RestaurateurRemoteDatasource(dioClient);
  return RestaurateurRepositoryImpl(datasource);
});

// ============================================
// 2. PROVIDER DES RESTAURANTS
// ============================================

final restaurantsProvider = FutureProvider<List<RestaurantEntity>>((ref) async {
  final repo = ref.read(restaurantRepositoryProvider);
  return await repo.getRestaurants();
});

// Provider pour un restaurant spécifique
final restaurantProvider = FutureProvider.family<RestaurantEntity?, String>((ref, id) async {
  final restaurants = await ref.watch(restaurantsProvider.future);
  try {
    return restaurants.firstWhere((r) => r.id == id);
  } catch (e) {
    return null;
  }
});

// Provider pour les restaurants du restaurateur connecté
final myRestaurantsProvider = FutureProvider<List<RestaurantEntity>>((ref) async {
  // Ce provider sera utilisé après avoir l'utilisateur connecté
  final repo = ref.read(restaurantRepositoryProvider);
  final allRestaurants = await repo.getRestaurants();
  
  // TODO: Filtrer par proprietaire_id quand l'utilisateur est disponible
  // Pour l'instant, retourne tous les restaurants
  return allRestaurants;
});
