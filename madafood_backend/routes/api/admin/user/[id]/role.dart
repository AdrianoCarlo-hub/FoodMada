// routes/api/admin/user/[id]/role.dart
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/core/security/admin_middleware.dart';
import 'package:madafood_backend/domain/repositories/user_repository.dart';

// ✅ Appliquer le middleware admin
Handler middleware(Handler handler) => handler.use(adminMiddleware);

Future<Response> onRequest(RequestContext context, String id) async {
  print('🔍 [ROLE] ===== DÉBUT =====');
  print('🔍 [ROLE] Requête pour l\'utilisateur: $id');
  print('🔍 [ROLE] Méthode: ${context.request.method}');
  
  // ✅ Vérifier la méthode
  if (context.request.method != HttpMethod.patch) {
    return Response(
      statusCode: HttpStatus.methodNotAllowed,
      body: 'Méthode non autorisée. Utilisez PATCH.',
    );
  }

  try {
    // ✅ Lire le corps de la requête
    final body = await context.request.json() as Map<String, dynamic>?;
    print('🔍 [ROLE] Corps: $body');
    
    if (body == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'Corps de requête invalide',
        },
      );
    }

    final nouveauRole = body['role'] as String?;
    print('🔍 [ROLE] Nouveau rôle: $nouveauRole');

    // ✅ Validation du rôle
    const rolesAutorises = ['CLIENT', 'RESTAURATEUR', 'ADMIN'];
    if (nouveauRole == null || !rolesAutorises.contains(nouveauRole)) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'Rôle invalide. Rôles autorisés: ${rolesAutorises.join(', ')}',
          'role_recu': nouveauRole,
        },
      );
    }

    // ✅ Récupérer le repository
    print('🔍 [ROLE] Tentative de récupération du UserRepository...');
    final repo = context.read<UserRepository>();
    print('✅ [ROLE] UserRepository récupéré');
    
    // ✅ Mettre à jour le rôle
    final success = await repo.updateRole(id, nouveauRole);
    print('🔍 [ROLE] Mise à jour réussie: $success');

    if (!success) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {
          'success': false,
          'error': 'Utilisateur introuvable ou mise à jour échouée',
        },
      );
    }

    // ✅ Retourner une réponse claire
    return Response.json(
      body: {
        'success': true,
        'message': 'Rôle mis à jour avec succès',
        'data': {
          'id': id,
          'role': nouveauRole,
        },
      },
    );
  } catch (e, stackTrace) {
    print('❌ [ROLE] Erreur: $e');
    print('📚 [ROLE] Stack: $stackTrace');
    
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Erreur lors de la mise à jour du rôle: ${e.toString()}',
      },
    );
  }
}