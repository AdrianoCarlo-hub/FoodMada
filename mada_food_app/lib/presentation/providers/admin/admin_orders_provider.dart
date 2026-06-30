// lib/presentation/providers/admin/admin_orders_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/datasources/admin/admin_remote_datasource.dart';
import '../../../data/repositories/admin_repository_impl.dart';
import '../../../domain/entities/commande.dart';
import '../../../domain/repositories/admin/admin_repository.dart';

// Provider du repository
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final dioClient = DioClient();
  final datasource = AdminRemoteDatasource(dioClient);
  return AdminRepositoryImpl(datasource);
});

// Provider pour la liste des commandes
final adminOrdersProvider = FutureProvider.family<List<Commande>, String?>((ref, statut) async {
  final repo = ref.read(adminRepositoryProvider);
  return await repo.getAllCommandes(statut: statut);
});

// Provider pour les détails d'une commande
final adminOrderDetailsProvider = FutureProvider.family<Commande?, String>((ref, orderId) async {
  final repo = ref.read(adminRepositoryProvider);
  return await repo.getCommandeById(orderId);
});