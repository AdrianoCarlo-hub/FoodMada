// lib/presentation/providers/client/restaurant_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/datasources/client/client_remote_datasource.dart';
import '../../../data/repositories/client/client_repository_impl.dart';
import '../../../domain/repositories/client/i_client_repository.dart';
import '../../../domain/entities/restaurant_entity.dart';
import '../../../domain/entities/plat.dart';

final clientDioProvider = Provider<DioClient>((ref) => DioClient());

final clientRepositoryProvider = Provider<IClientRepository>((ref) {
  final dio = ref.watch(clientDioProvider);
  final datasource = ClientRemoteDatasource(dio);
  return ClientRepositoryImpl(datasource);
});

final clientRestaurantsProvider = FutureProvider<List<RestaurantEntity>>((ref) async {
  final repo = ref.read(clientRepositoryProvider);
  return await repo.getRestaurants();
});

final clientRestaurantPlatsProvider = FutureProvider.family<List<Plat>, String>((ref, restaurantId) async {
  final repo = ref.read(clientRepositoryProvider);
  return await repo.getPlatsByRestaurant(restaurantId);
});