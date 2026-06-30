// lib/presentation/providers/admin/admin_dashboard_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mada_food_app/domain/entities/restaurant_entity.dart';
import 'package:mada_food_app/domain/entities/user_entity.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/datasources/admin/admin_remote_datasource.dart';
import '../../../data/repositories/admin_repository_impl.dart';
import '../../../domain/repositories/admin/admin_repository.dart';

// Provider du repository
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final dioClient = DioClient();
  final datasource = AdminRemoteDatasource(dioClient);
  return AdminRepositoryImpl(datasource);
});

// Provider des statistiques
final adminDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return await repo.getDashboardStats();
});

// Provider de la liste des restaurants
final adminRestaurantsProvider = FutureProvider<List<RestaurantEntity>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return await repo.getAllRestaurants();
});

// Provider de la liste des utilisateurs
final adminUsersProvider = FutureProvider.family<List<UserEntity>, String?>((ref, role) async {
  final repo = ref.read(adminRepositoryProvider);
  return await repo.getAllUsers(role: role);
});