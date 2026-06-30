// routes/api/auth/register.dart
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/domain/repositories/i_auth_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final nom = body['nom'] as String?;
    final telephone = body['telephone'] as String?;
    final motDePasse = body['mot_de_passe'] as String?;
    // ✅ Récupérer le rôle avec une valeur par défaut
    final role = body['role'] as String? ?? 'CLIENT';

    // Validation des champs obligatoires
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

    if (motDePasse == null || motDePasse.trim().isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'Le mot de passe est requis',
        },
      );
    }

    // ✅ Validation du rôle
    const validRoles = ['CLIENT', 'RESTAURATEUR', 'ADMIN'];
    final finalRole = validRoles.contains(role) ? role : 'CLIENT';

    print('📝 Tentative d\'inscription: $nom, $telephone, rôle: $finalRole');

    final authRepo = context.read<IAuthRepository>();
    final result = await authRepo.register(
      nom: nom.trim(),
      telephone: telephone.trim(),
      motDePasse: motDePasse,
      role: finalRole, // ✅ Envoi du rôle
    );

    if (result == null) {
      return Response.json(
        statusCode: HttpStatus.conflict,
        body: {
          'success': false,
          'error': 'Ce numéro de téléphone est déjà utilisé',
        },
      );
    }

    print('✅ Inscription réussie pour $nom avec rôle $finalRole');

    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'success': true,
        'data': result,
      },
    );
  } catch (e, stackTrace) {
    print('❌ Erreur dans register: $e');
    print('📚 Trace: $stackTrace');
    
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Erreur lors de l\'inscription: ${e.toString()}',
      },
    );
  }
}