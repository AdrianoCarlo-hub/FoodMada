// lib/data/repositories_impl/auth_repository_impl.dart
import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';
import 'package:postgres/postgres.dart';
import 'package:madafood_backend/core/database_client.dart'; 
import 'package:madafood_backend/domain/services/token_service.dart';
import 'package:madafood_backend/domain/repositories/i_auth_repository.dart';
import 'package:madafood_backend/data/models/user_model.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final DatabaseClient dbClient;
  final TokenService tokenService;

  AuthRepositoryImpl(this.dbClient, this.tokenService);

  /// ✅ Fonction utilitaire pour décoder les UndecodedBytes
  String _decodePassword(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is UndecodedBytes) {
      try {
        return value.asString;
      } catch (_) {
        try {
          return utf8.decode(value.bytes);
        } catch (_) {
          return value.toString();
        }
      }
    }
    if (value is List<int>) {
      try {
        return utf8.decode(value);
      } catch (_) {
        return String.fromCharCodes(value);
      }
    }
    return value.toString();
  }

  @override
  Future<Map<String, dynamic>?> register({
    required String nom, 
    required String telephone, 
    required String motDePasse,
    String role = 'CLIENT',
  }) async {
    try {
      final hashedPassword = BCrypt.hashpw(motDePasse, BCrypt.gensalt());
      
      final result = await dbClient.pool.execute(
        Sql.named(
          "INSERT INTO utilisateurs (nom, telephone, mot_de_passe, role) "
          "VALUES (@nom, @telephone, @password, @role::role_enum) RETURNING *"
        ),
        parameters: {
          'nom': nom, 
          'telephone': telephone, 
          'password': hashedPassword,
          'role': role,
        },
      );

      if (result.isEmpty) {
        print('❌ Échec de l\'inscription');
        return null;
      }

      final user = UserModel.fromJson(result.first.toColumnMap());
      final token = tokenService.generateToken(user.id, user.role);

      return {
        'user': user.toJson(),
        'token': token,
      };
    } catch (e) {
      print('❌ Erreur dans register: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> login({
    required String telephone, 
    required String motDePasse,
  }) async {
    try {
      print('🔍 [AuthRepository] Tentative de login: $telephone');
      
      final result = await dbClient.pool.execute(
        Sql.named('SELECT * FROM utilisateurs WHERE telephone = @telephone'),
        parameters: {'telephone': telephone},
      );

      if (result.isEmpty) {
        print('❌ [AuthRepository] Utilisateur non trouvé');
        return null;
      }

      final row = result.first.toColumnMap();
      
      // ✅ Décoder le mot de passe stocké
      final storedPassword = _decodePassword(row['mot_de_passe']);
      
      print('🔍 [AuthRepository] Mot de passe stocké décodé: ${storedPassword.substring(0, storedPassword.length > 20 ? 20 : storedPassword.length)}...');

      // ✅ Vérifier le mot de passe
      if (BCrypt.checkpw(motDePasse, storedPassword)) {
        final user = UserModel.fromJson(row);
        final token = tokenService.generateToken(user.id, user.role);
        
        print('✅ [AuthRepository] Login réussi pour: $telephone');
        
        return {
          'user': user.toJson(),
          'token': token,
        };
      }
      
      print('❌ [AuthRepository] Mot de passe incorrect');
      return null;
    } catch (e, stackTrace) {
      print('❌ [AuthRepository] Erreur dans login: $e');
      print('📚 Stack: $stackTrace');
      return null;
    }
  }

  /// ✅ Méthode utilitaire pour vérifier si un utilisateur existe
  Future<bool> userExists(String telephone) async {
    try {
      final result = await dbClient.pool.execute(
        Sql.named('SELECT id FROM utilisateurs WHERE telephone = @telephone'),
        parameters: {'telephone': telephone},
      );
      return result.isNotEmpty;
    } catch (e) {
      print('❌ [AuthRepository] Erreur userExists: $e');
      return false;
    }
  }

  /// ✅ Méthode utilitaire pour récupérer un utilisateur par téléphone
  Future<UserModel?> getUserByPhone(String telephone) async {
    try {
      final result = await dbClient.pool.execute(
        Sql.named('SELECT * FROM utilisateurs WHERE telephone = @telephone'),
        parameters: {'telephone': telephone},
      );

      if (result.isEmpty) {
        return null;
      }

      return UserModel.fromJson(result.first.toColumnMap());
    } catch (e) {
      print('❌ [AuthRepository] Erreur getUserByPhone: $e');
      return null;
    }
  }
}