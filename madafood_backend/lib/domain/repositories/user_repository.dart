// lib/domain/repositories/user_repository.dart

import '../entities/user.dart';
// lib/domain/repositories/user_repository.dart
abstract class UserRepository {
  Future<User?> getUserByPhone(String telephone);
  Future<User> createUser({
    required String nom,
    required String telephone,
    required String motDePasse,
    required String role,
  });
  Future<User?> getUserById(String id);
  Future<bool> updateRole(String id, String nouveauRole);
  Future<bool> banUser(String id);
  
  // ✅ AJOUTER CES MÉTHODES
  Future<bool> updateUser(String id, {required String nom, required String telephone});
  Future<bool> deleteUser(String id);
}