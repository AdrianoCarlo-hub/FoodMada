// lib/domain/repositories/i_auth_repository.dart
abstract class IAuthRepository {
  /// Inscrit un nouvel utilisateur et retourne l'utilisateur + son token JWT
  Future<Map<String, dynamic>?> register({
    required String nom,
    required String telephone,
    required String motDePasse,
    String role = 'CLIENT', // ✅ AJOUT : rôle avec valeur par défaut
  });

  /// Connecte un utilisateur existant et retourne l'utilisateur + son token JWT
  Future<Map<String, dynamic>?> login({
    required String telephone,
    required String motDePasse,
  });
}