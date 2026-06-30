// lib/core/security/admin_middleware.dart
import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/domain/services/token_service.dart';
import 'package:madafood_backend/domain/entities/user.dart';
import 'package:madafood_backend/domain/repositories/user_repository.dart'; // ✅ AJOUTER CET IMPORT

Handler adminMiddleware(Handler handler) {
  return (context) async {
    print('🔍 [ADMIN_MIDDLEWARE] Vérification des droits admin');
    
    // ✅ Essayer de récupérer l'utilisateur du contexte
    User? user;
    try {
      user = context.read<User?>();
      print('🔍 [ADMIN_MIDDLEWARE] Utilisateur trouvé dans le contexte: ${user?.nom}');
    } catch (e) {
      print('⚠️ [ADMIN_MIDDLEWARE] Utilisateur non trouvé dans le contexte: $e');
    }

    // Si l'utilisateur n'est pas dans le contexte, vérifier le token
    if (user == null) {
      final authHeader = context.request.headers['Authorization'];
      print('🔍 [ADMIN_MIDDLEWARE] Auth Header: $authHeader');
      
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        print('❌ [ADMIN_MIDDLEWARE] Pas de token valide');
        return Response.json(
          statusCode: 401,
          body: {'success': false, 'error': 'Non autorisé - Token manquant'},
        );
      }

      final token = authHeader.substring(7);
      print('🔍 [ADMIN_MIDDLEWARE] Token: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      
      try {
        final tokenService = context.read<TokenService>();
        final payload = tokenService.verifyToken(token);
        print('🔍 [ADMIN_MIDDLEWARE] Payload du token: $payload');

        if (payload == null) {
          return Response.json(
            statusCode: 401,
            body: {'success': false, 'error': 'Token invalide ou expiré'},
          );
        }

        final role = payload['role'] as String?;
        final userId = payload['sub'] as String?; // ✅ Récupérer l'ID utilisateur
        print('🔍 [ADMIN_MIDDLEWARE] Rôle extrait du token: $role');
        print('🔍 [ADMIN_MIDDLEWARE] UserId extrait: $userId');

        // ✅ Vérifier le rôle
        if (role != 'ADMIN') {
          print('❌ [ADMIN_MIDDLEWARE] Accès refusé - Rôle: $role');
          return Response.json(
            statusCode: 403,
            body: {
              'success': false,
              'error': 'Accès réservé aux administrateurs',
              'role_recu': role,
            },
          );
        }

        // ✅ Si userId est présent, charger l'utilisateur et l'ajouter au contexte
        if (userId != null) {
          try {
            final userRepo = context.read<UserRepository>();
            print('🔍 [ADMIN_MIDDLEWARE] Chargement de l\'utilisateur: $userId');
            final loadedUser = await userRepo.getUserById(userId);
            if (loadedUser != null) {
              print('✅ [ADMIN_MIDDLEWARE] Utilisateur chargé: ${loadedUser.nom}');
              // ✅ Fournir l'utilisateur au contexte pour les routes suivantes
              final newContext = context.provide<User?>(() => loadedUser);
              return await handler(newContext);
            } else {
              print('❌ [ADMIN_MIDDLEWARE] Utilisateur non trouvé en base');
            }
          } catch (e) {
            print('⚠️ [ADMIN_MIDDLEWARE] Impossible de charger l\'utilisateur: $e');
          }
        }

        print('✅ [ADMIN_MIDDLEWARE] Admin authentifié avec succès (sans utilisateur chargé)');
        return await handler(context);
      } catch (e) {
        print('❌ [ADMIN_MIDDLEWARE] Erreur lors de la vérification du token: $e');
        return Response.json(
          statusCode: 401,
          body: {'success': false, 'error': 'Token invalide: ${e.toString()}'},
        );
      }
    }

    // ✅ Si l'utilisateur est dans le contexte, vérifier son rôle
    final roleNormalise = user.role.toString().trim().toUpperCase();
    print('🔍 [ADMIN_MIDDLEWARE] Rôle de l\'utilisateur: $roleNormalise');

    if (roleNormalise != 'ADMIN') {
      print('❌ [ADMIN_MIDDLEWARE] Accès refusé - Rôle: $roleNormalise');
      return Response.json(
        statusCode: 403,
        body: {
          'success': false,
          'error': 'Accès réservé aux administrateurs',
          'role_recu': roleNormalise,
        },
      );
    }

    print('✅ [ADMIN_MIDDLEWARE] Admin authentifié avec succès (contexte)');
    return await handler(context);
  };
}