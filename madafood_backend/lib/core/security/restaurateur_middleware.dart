// lib/core/security/restaurateur_middleware.dart
import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/core/helpers/decoder_helper.dart';
import 'package:madafood_backend/domain/entities/user.dart';
import 'package:madafood_backend/core/database_client.dart';
import 'package:madafood_backend/data/repositories_impl/user_repository_impl.dart';
import 'package:madafood_backend/core/security/jwt_service_impl.dart';

Handler restaurateurMiddleware(Handler handler) {
  return (context) async {
    User? user;

    // 1. Tenter de récupérer l'utilisateur depuis le contexte ou le token
    try {
      user = context.read<User?>();
      if (user != null) {
        // ✅ Décoder le rôle si nécessaire
        final decodedRole = decodeRole(user.role);
        if (decodedRole != user.role) {
          user = User(
            id: user.id,
            nom: user.nom,
            telephone: user.telephone,
            role: decodedRole,
            restaurantId: user.restaurantId,
            dateCreation: user.dateCreation,
            motDePasse: user.motDePasse,
          );
        }
      }
    } catch (_) {}

    if (user == null) {
      final authHeader = context.request.headers['Authorization'];
      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        final token = authHeader.substring(7);
        try {
          final jwtService = JwtServiceImpl();
          final decodedToken = jwtService.verifyToken(token);
          if (decodedToken != null) {
            final userId = decodedToken['sub'] as String?;
            if (userId != null) {
              final dbClient = DatabaseClient.initialize();
              final repo = UserRepositoryImpl(dbClient);
              user = await repo.getUserById(userId);
              if (user != null) {
                // ✅ Décoder le rôle
                final decodedRole = decodeRole(user.role);
                user = User(
                  id: user.id,
                  nom: user.nom,
                  telephone: user.telephone,
                  role: decodedRole,
                  restaurantId: user.restaurantId,
                  dateCreation: user.dateCreation,
                  motDePasse: user.motDePasse,
                );
              }
            }
          }
        } catch (e) {
          print('❌ [MIDDLEWARE] Erreur JWT: $e');
        }
      }
    }

    // 2. Vérification de l'existence
    if (user == null) {
      return Response.json(statusCode: 401, body: {'error': 'Non authentifié'});
    }

    // ✅ NORMALISATION DU RÔLE (déjà décodé)
    final roleNormalise = user.role.toString().trim().toUpperCase();
    
    print('👤 [MIDDLEWARE] Vérification utilisateur: ${user.nom}');
    print('   - Rôle brut: "${user.role}"');
    print('   - Rôle normalisé: "$roleNormalise"');
    print('   - Restaurant ID: ${user.restaurantId}');

    // ✅ Vérification du rôle
    if (roleNormalise != 'RESTAURATEUR' && roleNormalise != 'ADMIN') {
      print('❌ [MIDDLEWARE] Accès refusé pour le rôle: $roleNormalise');
      return Response.json(
        statusCode: 403,
        body: {
          'error': 'Accès interdit : Restaurateur ou Admin requis. Rôle reçu: $roleNormalise',
          'role_recu': roleNormalise,
        },
      );
    }

    // ✅ Vérification du restaurant
    if (roleNormalise == 'RESTAURATEUR') {
      if (user.restaurantId == null || user.restaurantId!.isEmpty) {
        print('❌ [MIDDLEWARE] Restaurateur sans restaurant_id');
        return Response.json(
          statusCode: 403,
          body: {
            'error': 'Aucun restaurant associé. Contactez l\'administrateur.',
          },
        );
      }
      print('✅ [MIDDLEWARE] Restaurant ID: ${user.restaurantId}');
    }

    print('✅ [MIDDLEWARE] Accès autorisé pour: ${user.nom} ($roleNormalise)');
    return await handler(context);
  };
}