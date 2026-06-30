// lib/presentation/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/dio_client.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';

// 1. Fournisseurs
final dioClientProvider = Provider<DioClient>((ref) => DioClient());

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthRepositoryImpl(dioClient);
});

// 2. Gestionnaire d'état de l'authentification
class AuthNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  final IAuthRepository _repository;
  final _storage = const FlutterSecureStorage();

  AuthNotifier(this._repository) : super(const AsyncValue.data(null)) {
    // ✅ RESTAURER LA SESSION AU DÉMARRAGE
    _restoreSession();
  }

  // ✅ RESTAURER LA SESSION
  Future<void> _restoreSession() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      print('🔑 Token au démarrage: ${token?.substring(0, 20)}...');
      
      if (token != null && token.isNotEmpty) {
        // ✅ Essayer de récupérer l'utilisateur via un endpoint /me
        // Pour l'instant, on garde l'état loading
        // L'utilisateur devra se reconnecter si le token est invalide
        print('✅ Session existante trouvée');
        // On ne peut pas récupérer l'utilisateur sans faire une requête
        // Mais on garde le token pour les futures requêtes
      }
    } catch (e) {
      print('❌ Erreur restauration session: $e');
    }
  }

  Future<void> login(String telephone, String password) async {
    state = const AsyncValue.loading();
    try {
      print('🔄 Login en cours pour: $telephone');
      final user = await _repository.login(telephone, password);
      
      final token = await _storage.read(key: 'jwt_token');
      print('🔑 Token après login: ${token?.substring(0, 20)}...');
      print('👤 Utilisateur: ${user.nom} (${user.role})');
      
      state = AsyncValue.data(user);
    } catch (e, stack) {
      print('❌ Erreur login: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> register({
    required String nom,
    required String telephone,
    required String password,
    required String role,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.register(
        nom: nom,
        telephone: telephone,
        password: password,
        role: role,
      );
      
      final token = await _storage.read(key: 'jwt_token');
      print('🔑 Token après register: ${token?.substring(0, 20)}...');
      
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void logout() async {
    await _storage.delete(key: 'jwt_token');
    print('🔴 Déconnexion - Token supprimé');
    state = const AsyncValue.data(null);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }
}

// 3. Provider global
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserEntity?>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});