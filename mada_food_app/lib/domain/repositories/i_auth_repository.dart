import '../entities/user_entity.dart';

abstract class IAuthRepository {
  Future<UserEntity> login(String telephone, String password);
  Future<UserEntity> register({
    required String nom,
    required String telephone,
    required String password,
    required String role, // 'CLIENT', 'ADMIN', ou 'RESTAURATEUR'
  });
}