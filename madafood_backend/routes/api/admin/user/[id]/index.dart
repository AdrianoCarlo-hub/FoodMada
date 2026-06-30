// routes/api/admin/user/[id]/index.dart
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/core/security/admin_middleware.dart';
import 'package:madafood_backend/domain/repositories/user_repository.dart';

Handler middleware(Handler handler) => handler.use(adminMiddleware);

Future<Response> onRequest(RequestContext context, String id) async {
  print('🔍 [USER_INDEX] Requête pour l\'utilisateur: $id');
  print('🔍 [USER_INDEX] Méthode: ${context.request.method}');

  final method = context.request.method;

  // ✅ PUT : Mettre à jour un utilisateur
  if (method == HttpMethod.put) {
    return _updateUser(context, id);
  }
  
  // ✅ DELETE : Supprimer un utilisateur
  if (method == HttpMethod.delete) {
    return _deleteUser(context, id);
  }

  return Response(
    statusCode: HttpStatus.methodNotAllowed,
    body: 'Méthode non autorisée. Utilisez PUT ou DELETE.',
  );
}

// ✅ Mettre à jour un utilisateur (utilise UserRepository)
Future<Response> _updateUser(RequestContext context, String id) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>?;
    print('🔍 [USER_INDEX] Corps: $body');

    if (body == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'Corps de requête invalide',
        },
      );
    }

    final nom = body['nom'] as String?;
    final telephone = body['telephone'] as String?;

    if (nom == null || nom.trim().isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'Le nom est requis',
        },
      );
    }

    if (telephone == null || telephone.trim().isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'Le numéro de téléphone est requis',
        },
      );
    }

    // ✅ Utiliser UserRepository au lieu de DatabaseClient
    final repo = context.read<UserRepository>();
    print('🔍 [USER_INDEX] UserRepository récupéré');

    final success = await repo.updateUser(
      id, 
      nom: nom.trim(), 
      telephone: telephone.trim()
    );

    if (!success) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {
          'success': false,
          'error': 'Utilisateur non trouvé',
        },
      );
    }

    return Response.json(
      body: {
        'success': true,
        'message': 'Utilisateur mis à jour avec succès',
        'data': {
          'id': id,
          'nom': nom.trim(),
          'telephone': telephone.trim(),
        },
      },
    );
  } catch (e) {
    print('❌ [USER_INDEX] Erreur updateUser: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Erreur lors de la mise à jour: ${e.toString()}',
      },
    );
  }
}

// ✅ Supprimer un utilisateur (utilise UserRepository)
Future<Response> _deleteUser(RequestContext context, String id) async {
  try {
    print('🔍 [USER_INDEX] Suppression de l\'utilisateur: $id');

    // ✅ Utiliser UserRepository au lieu de DatabaseClient
    final repo = context.read<UserRepository>();
    print('🔍 [USER_INDEX] UserRepository récupéré');

    final success = await repo.deleteUser(id);

    if (!success) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {
          'success': false,
          'error': 'Utilisateur non trouvé',
        },
      );
    }

    return Response.json(
      body: {
        'success': true,
        'message': 'Utilisateur supprimé avec succès',
      },
    );
  } catch (e) {
    print('❌ [USER_INDEX] Erreur deleteUser: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Erreur lors de la suppression: ${e.toString()}',
      },
    );
  }
}