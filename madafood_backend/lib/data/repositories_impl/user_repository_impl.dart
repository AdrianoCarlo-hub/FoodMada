// lib/data/repositories_impl/user_repository_impl.dart
import 'package:bcrypt/bcrypt.dart';
import 'package:postgres/postgres.dart';
import '../../core/database_client.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import 'package:madafood_backend/core/helpers/decoder_helper.dart';

class UserRepositoryImpl implements UserRepository {
  final DatabaseClient _dbClient;

  UserRepositoryImpl(this._dbClient);

  // ============================================================
  // GETTERS
  // ============================================================

@override
Future<User?> getUserById(String id) async {
  try {
    print('🔍 [UserRepository] getUserById: $id');
    
    final result = await _dbClient.pool.execute(
      Sql.named('''
        SELECT id, nom, telephone, role, date_creation, restaurant_id
        FROM utilisateurs 
        WHERE id = @id
      '''),
      parameters: {'id': id},
    );

    if (result.isEmpty) {
      print('❌ [UserRepository] Utilisateur non trouvé');
      return null;
    }

    final row = result.first;
    print('✅ [UserRepository] Utilisateur trouvé');

    // ✅ Décoder le rôle avec decodeRole
    final role = decodeRole(row[3]);
    
    return User(
      id: row[0].toString(),
      nom: row[1].toString(),
      telephone: row[2].toString(),
      role: role, // ✅ Rôle décodé
      restaurantId: row[5]?.toString(),
      dateCreation: DateTime.parse(row[4].toString()),
    );
  } catch (e, stack) {
    print('❌ [UserRepository] Erreur getUserById: $e');
    print('📚 Stack: $stack');
    return null;
  }
}

  @override
  Future<User?> getUserByPhone(String telephone) async {
    try {
      print('🔍 [UserRepository] getUserByPhone: $telephone');
      
      final result = await _dbClient.pool.execute(
        Sql.named('''
          SELECT id, nom, telephone, role, date_creation, restaurant_id
          FROM utilisateurs 
          WHERE telephone = @telephone
        '''),
        parameters: {'telephone': telephone},
      );

      if (result.isEmpty) {
        print('❌ [UserRepository] Utilisateur non trouvé');
        return null;
      }

      final row = result.first;
      print('✅ [UserRepository] Utilisateur trouvé');

      return User(
        id: row[0].toString(),
        nom: row[1].toString(),
        telephone: row[2].toString(),
        role: row[3].toString(),
        restaurantId: row[5]?.toString(),
        dateCreation: DateTime.parse(row[4].toString()),
      );
    } catch (e) {
      print('❌ [UserRepository] Erreur getUserByPhone: $e');
      return null;
    }
  }

  // ============================================================
  // CREATE
  // ============================================================

  @override
  Future<User> createUser({
    required String nom,
    required String telephone,
    required String motDePasse,
    required String role,
  }) async {
    try {
      print('🔍 [UserRepository] createUser: $nom, $telephone, $role');
      
      final hashedPassword = BCrypt.hashpw(motDePasse, BCrypt.gensalt());

      final result = await _dbClient.pool.execute(
        Sql.named('''
          INSERT INTO utilisateurs (nom, telephone, mot_de_passe, role)
          VALUES (@nom, @telephone, @password, @role::role_enum)
          RETURNING id, nom, telephone, role, date_creation, restaurant_id
        '''),
        parameters: {
          'nom': nom,
          'telephone': telephone,
          'password': hashedPassword,
          'role': role,
        },
      );

      if (result.isEmpty) {
        throw Exception('Échec de la création de l\'utilisateur');
      }

      final row = result.first;
      print('✅ [UserRepository] Utilisateur créé avec succès');

      return User(
        id: row[0].toString(),
        nom: row[1].toString(),
        telephone: row[2].toString(),
        role: row[3].toString(),
        restaurantId: row[5]?.toString(),
        dateCreation: DateTime.parse(row[4].toString()),
        motDePasse: hashedPassword,
      );
    } catch (e) {
      print('❌ [UserRepository] Erreur createUser: $e');
      rethrow;
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  @override
  Future<bool> updateRole(String id, String nouveauRole) async {
    try {
      print('🔍 [updateRole] Mise à jour du rôle pour l\'utilisateur: $id');
      print('🔍 [updateRole] Nouveau rôle: $nouveauRole');

      // ✅ Vérifier si l'utilisateur existe
      final checkResult = await _dbClient.pool.execute(
        Sql.named('SELECT id FROM utilisateurs WHERE id = @id'),
        parameters: {'id': id},
      );

      if (checkResult.isEmpty) {
        print('❌ [updateRole] Utilisateur non trouvé');
        return false;
      }

      // ✅ Mettre à jour le rôle avec le bon cast PostgreSQL
      final result = await _dbClient.pool.execute(
        Sql.named('''
          UPDATE utilisateurs 
          SET role = @role::role_enum 
          WHERE id = @id
          RETURNING id
        '''),
        parameters: {
          'id': id,
          'role': nouveauRole,
        },
      );

      final success = result.affectedRows > 0;
      print('✅ [updateRole] Succès: $success');
      
      return success;
    } catch (e) {
      print('❌ [updateRole] Erreur: $e');
      return false;
    }
  }

  @override
  Future<bool> updateUser(String id, {
    required String nom,
    required String telephone,
  }) async {
    try {
      print('🔍 [updateUser] Mise à jour de l\'utilisateur: $id');
      print('🔍 [updateUser] Nouveau nom: $nom, Nouveau téléphone: $telephone');

      // ✅ Vérifier si l'utilisateur existe
      final checkResult = await _dbClient.pool.execute(
        Sql.named('SELECT id FROM utilisateurs WHERE id = @id'),
        parameters: {'id': id},
      );

      if (checkResult.isEmpty) {
        print('❌ [updateUser] Utilisateur non trouvé');
        return false;
      }

      // ✅ Mettre à jour l'utilisateur
      final result = await _dbClient.pool.execute(
        Sql.named('''
          UPDATE utilisateurs 
          SET nom = @nom, telephone = @telephone
          WHERE id = @id
          RETURNING id
        '''),
        parameters: {
          'id': id,
          'nom': nom,
          'telephone': telephone,
        },
      );

      final success = result.affectedRows > 0;
      print('✅ [updateUser] Succès: $success');
      
      return success;
    } catch (e) {
      print('❌ [updateUser] Erreur: $e');
      return false;
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  @override
  Future<bool> deleteUser(String id) async {
    try {
      print('🔍 [deleteUser] Suppression de l\'utilisateur: $id');

      // ✅ Vérifier si l'utilisateur existe
      final checkResult = await _dbClient.pool.execute(
        Sql.named('''
          SELECT id, role FROM utilisateurs WHERE id = @id
        '''),
        parameters: {'id': id},
      );

      if (checkResult.isEmpty) {
        print('❌ [deleteUser] Utilisateur non trouvé');
        return false;
      }

      final user = checkResult.first.toColumnMap();
      final role = user['role']?.toString() ?? '';

      // ✅ Empêcher la suppression du dernier admin
      if (role.toUpperCase() == 'ADMIN') {
        final adminCount = await _dbClient.pool.execute(
          "SELECT COUNT(*) as total FROM utilisateurs WHERE role = 'ADMIN'"
        );
        final totalAdmins = int.tryParse(
          adminCount.first.toColumnMap()['total']?.toString() ?? '0'
        ) ?? 0;
        
        if (totalAdmins <= 1) {
          print('❌ [deleteUser] Impossible de supprimer le dernier administrateur');
          return false;
        }
      }

      // ✅ Supprimer l'utilisateur
      final result = await _dbClient.pool.execute(
        Sql.named('DELETE FROM utilisateurs WHERE id = @id'),
        parameters: {'id': id},
      );

      final success = result.affectedRows > 0;
      print('✅ [deleteUser] Succès: $success');
      
      return success;
    } catch (e) {
      print('❌ [deleteUser] Erreur: $e');
      return false;
    }
  }


  @override
  Future<bool> banUser(String id) async {
    try {
      print('🔍 [banUser] Bannissement de l\'utilisateur: $id');

      // ✅ Vérifier si le champ est_banni existe dans la table
      // Si le champ n'existe pas, on peut ajouter une colonne ou ignorer
      final result = await _dbClient.pool.execute(
        Sql.named('''
          UPDATE utilisateurs 
          SET est_banni = true 
          WHERE id = @id
          RETURNING id
        '''),
        parameters: {'id': id},
      );

      final success = result.affectedRows > 0;
      print('✅ [banUser] Succès: $success');
      
      return success;
    } catch (e) {
      // ✅ Si la colonne n'existe pas, on retourne false
      print('⚠️ [banUser] Erreur (probablement colonne manquante): $e');
      return false;
    }
  }

  // ============================================================
  // MÉTHODES UTILITAIRES
  // ============================================================

  /// ✅ Vérifier si un utilisateur existe
  Future<bool> userExists(String id) async {
    try {
      final result = await _dbClient.pool.execute(
        Sql.named('SELECT id FROM utilisateurs WHERE id = @id'),
        parameters: {'id': id},
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// ✅ Récupérer tous les utilisateurs (avec filtre optionnel)
  Future<List<User>> getAllUsers({String? role}) async {
    try {
      String sql = '''
        SELECT id, nom, telephone, role, date_creation, restaurant_id
        FROM utilisateurs
      ''';
      
      final params = <String, dynamic>{};
      
      if (role != null) {
        sql += ' WHERE role = @role';
        params['role'] = role;
      }
      
      sql += ' ORDER BY date_creation DESC';

      final result = await _dbClient.pool.execute(
        Sql.named(sql),
        parameters: params,
      );

      return result.map((row) => User(
        id: row[0].toString(),
        nom: row[1].toString(),
        telephone: row[2].toString(),
        role: row[3].toString(),
        restaurantId: row[5]?.toString(),
        dateCreation: DateTime.parse(row[4].toString()),
      )).toList();
    } catch (e) {
      print('❌ [UserRepository] Erreur getAllUsers: $e');
      return [];
    }
  }

  /// ✅ Récupérer les restaurateurs sans restaurant
  Future<List<User>> getAvailableRestaurateurs() async {
    try {
      final result = await _dbClient.pool.execute(
        Sql.named('''
          SELECT id, nom, telephone, role, date_creation, restaurant_id
          FROM utilisateurs 
          WHERE role = 'RESTAURATEUR' AND restaurant_id IS NULL
          ORDER BY nom
        '''),
      );

      return result.map((row) => User(
        id: row[0].toString(),
        nom: row[1].toString(),
        telephone: row[2].toString(),
        role: row[3].toString(),
        restaurantId: row[5]?.toString(),
        dateCreation: DateTime.parse(row[4].toString()),
      )).toList();
    } catch (e) {
      print('❌ [UserRepository] Erreur getAvailableRestaurateurs: $e');
      return [];
    }
  }

  /// ✅ Affecter un restaurateur à un restaurant
  Future<bool> assignRestaurateur(String userId, String restaurantId) async {
    try {
      print('🔍 [assignRestaurateur] User: $userId, Restaurant: $restaurantId');

      final result = await _dbClient.pool.execute(
        Sql.named('''
          UPDATE utilisateurs 
          SET restaurant_id = @restaurant_id
          WHERE id = @user_id AND role = 'RESTAURATEUR'
          RETURNING id
        '''),
        parameters: {
          'user_id': userId,
          'restaurant_id': restaurantId,
        },
      );

      final success = result.affectedRows > 0;
      print('✅ [assignRestaurateur] Succès: $success');
      
      return success;
    } catch (e) {
      print('❌ [assignRestaurateur] Erreur: $e');
      return false;
    }
  }
}