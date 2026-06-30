// lib/core/security/auth_middleware.dart
import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/core/database_client.dart';
import 'package:madafood_backend/core/security/jwt_service_impl.dart';
import 'package:madafood_backend/data/repositories_impl/user_repository_impl.dart';
import 'package:madafood_backend/domain/entities/user.dart';
import 'package:madafood_backend/domain/repositories/user_repository.dart';

// ✅ Fonction de décodage du rôle robuste
String _decodeRole(dynamic roleValue) {
  if (roleValue == null) return 'CLIENT';
  
  // Si c'est déjà une String valide
  if (roleValue is String) {
    final trimmed = roleValue.trim().toUpperCase();
    if (trimmed == 'ADMIN' || trimmed == 'RESTAURATEUR' || trimmed == 'CLIENT' || trimmed == 'LIVREUR') {
      return trimmed;
    }
    // Si la chaîne contient un des mots-clés
    if (trimmed.contains('ADMIN')) return 'ADMIN';
    if (trimmed.contains('RESTAURATEUR')) return 'RESTAURATEUR';
    if (trimmed.contains('CLIENT')) return 'CLIENT';
    if (trimmed.contains('LIVREUR')) return 'LIVREUR';
    return 'CLIENT';
  }
  
  // Si c'est un type PostgreSQL (PgEnum, UndecodedBytes, etc.)
  final roleStr = roleValue.toString();
  
  // Chercher des mots-clés dans la chaîne
  if (roleStr.contains('ADMIN')) return 'ADMIN';
  if (roleStr.contains('RESTAURATEUR')) return 'RESTAURATEUR';
  if (roleStr.contains('CLIENT')) return 'CLIENT';
  if (roleStr.contains('LIVREUR')) return 'LIVREUR';
  
  // Nettoyer la chaîne
  String cleaned = roleStr
      .replaceAll('INSTANCE OF', '')
      .replaceAll("'", '')
      .replaceAll('"', '')
      .replaceAll('(', '')
      .replaceAll(')', '')
      .trim()
      .toUpperCase();
  
  // Vérifier le résultat
  if (cleaned.isEmpty || cleaned.contains('UNDECODEDBYTES')) {
    return 'CLIENT';
  }
  
  if (cleaned == 'ADMIN' || cleaned == 'RESTAURATEUR' || cleaned == 'CLIENT' || cleaned == 'LIVREUR') {
    return cleaned;
  }
  
  return 'CLIENT';
}

Middleware authMiddleware() {
  return (handler) {
    return (context) async {
      print('🔍 [AUTH] ===== DEBUT AUTHENTIFICATION =====');
      
      final authHeader = context.request.headers['Authorization'];
      print('🔍 [AUTH] Header: $authHeader');

      User? user;

      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        final token = authHeader.substring(7);
        final tokenPreview = token.length > 30 ? '${token.substring(0, 30)}...' : token;
        print('🔑 [AUTH] Token recu: $tokenPreview');

        try {
          final jwtService = JwtServiceImpl();
          final decodedToken = jwtService.verifyToken(token);

          if (decodedToken != null) {
            final userId = decodedToken['sub'] as String?;
            print('👤 [AUTH] User ID extrait du token: $userId');

            if (userId != null) {
              try {
                print('🔍 [AUTH] Recherche de UserRepository...');
                
                UserRepository? repo;
                try {
                  repo = context.read<UserRepository>();
                  print('✅ [AUTH] UserRepository trouve via context.read');
                } catch (e) {
                  print('⚠️ [AUTH] UserRepository non trouve dans le contexte');
                  print('🔍 [AUTH] Creation d\'une instance directe...');
                  final dbClient = DatabaseClient.initialize();
                  repo = UserRepositoryImpl(dbClient);
                  print('✅ [AUTH] UserRepository cree manuellement');
                }
                
                if (repo != null) {
                  print('🔍 [AUTH] Appel de getUserById($userId)...');
                  user = await repo.getUserById(userId);
                  
                  if (user != null) {
                    // ✅ Décoder le rôle avec _decodeRole
                    final decodedRole = _decodeRole(user.role);
                    print('🔍 [AUTH] Role brut: "${user.role}" -> decode: "$decodedRole"');
                    
                    // ✅ Créer un nouvel utilisateur avec le rôle décodé
                    user = User(
                      id: user.id,
                      nom: user.nom,
                      telephone: user.telephone,
                      motDePasse: user.motDePasse,
                      role: decodedRole,
                      restaurantId: user.restaurantId,
                      dateCreation: user.dateCreation,
                    );
                    
                    print('✅ [AUTH] Utilisateur trouve: "${user.nom}" (${user.role})');
                    print('🔍 [AUTH] Restaurant ID: ${user.restaurantId}');
                  } else {
                    print('❌ [AUTH] Utilisateur non trouve en base');
                  }
                }
              } catch (e) {
                print('❌ [AUTH] Erreur recuperation utilisateur: $e');
              }
            } else {
              print('❌ [AUTH] userId est null');
            }
          } else {
            print('❌ [AUTH] Token invalide ou expire');
          }
        } catch (e) {
          print('❌ [AUTH] Erreur verification token: $e');
        }
      } else {
        if (authHeader == null) {
          print('⚠️ [AUTH] Pas de header Authorization');
        } else {
          print('⚠️ [AUTH] Header ne commence pas par Bearer');
        }
      }

      // Fournir l'utilisateur au contexte
      final newHandler = provider<User?>((_) => user)(handler);
      
      print('🔍 [AUTH] Utilisateur fourni au contexte: ${user?.nom ?? 'null'} (${user?.role ?? 'null'})');
      print('🔍 [AUTH] Restaurant ID: ${user?.restaurantId ?? 'null'}');
      print('🔍 [AUTH] ===== FIN AUTHENTIFICATION =====');
      
      return newHandler(context);
    };
  };
}