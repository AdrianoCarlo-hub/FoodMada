// lib/presentation/providers/client/order_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/datasources/client/client_remote_datasource.dart';
import '../../../data/repositories/client/client_repository_impl.dart';
import '../../../domain/repositories/client/i_client_repository.dart';
import '../../../domain/entities/commande.dart';
import '../../providers/auth_provider.dart';

final clientOrderDioProvider = Provider<DioClient>((ref) => DioClient());

final clientOrderRepositoryProvider = Provider<IClientRepository>((ref) {
  final dio = ref.watch(clientOrderDioProvider);
  final datasource = ClientRemoteDatasource(dio);
  return ClientRepositoryImpl(datasource);
});

final clientOrdersProvider = FutureProvider<List<Commande>>((ref) async {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) throw Exception('Utilisateur non connecté');
  
  final repo = ref.read(clientOrderRepositoryProvider);
  return await repo.getOrderHistory(user.id);
});

final clientOrderDetailsProvider = FutureProvider.family<Commande?, String>((ref, orderId) async {
  final repo = ref.read(clientOrderRepositoryProvider);
  return await repo.getOrderById(orderId);
});