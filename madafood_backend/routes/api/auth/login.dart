// routes/api/auth/login.dart
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/domain/repositories/i_auth_repository.dart';
import 'package:madafood_backend/data/models/user_model.dart'; // ✅ AJOUTER

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(
      statusCode: HttpStatus.methodNotAllowed,
      body: 'Méthode non autorisée. Utilisez POST.',
    );
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final telephone = body['telephone'] as String?;
    final motDePasse = body['mot_de_passe'] as String?;

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

    final authRepo = context.read<IAuthRepository>();
    final result = await authRepo.login(
      telephone: telephone.trim(),
      motDePasse: motDePasse,
    );

    if (result == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {
          'success': false,
          'error': 'Numéro de téléphone ou mot de passe incorrect',
        },
      );
    }

    // ✅ Récupérer les données
    final user = result['user'];
    final token = result['token'];

    // ✅ Vérification du token
    if (token == null || token.toString().isEmpty) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {
          'success': false,
          'error': 'Erreur lors de la génération du token',
        },
      );
    }

    // ✅ CORRECTION : Vérifier le type de user
    if (user == null) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {
          'success': false,
          'error': 'Utilisateur non trouvé',
        },
      );
    }

    // ✅ Si user est un Map, on le convertit en UserModel
    UserModel userModel;
    if (user is Map<String, dynamic>) {
      userModel = UserModel.fromJson(user);
    } else if (user is UserModel) {
      userModel = user;
    } else {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {
          'success': false,
          'error': 'Format d\'utilisateur invalide',
        },
      );
    }

    // ✅ Logs avec les bons accès
    print('✅ Login réussi: $telephone');
    print('🔑 Token: ${token.toString().substring(0, token.toString().length > 30 ? 30 : token.toString().length)}...');
    print('👤 Utilisateur: ${userModel.nom} (${userModel.role})');

    // ✅ Retourner la réponse
    return Response.json(
      body: {
        'success': true,
        'data': {
          'user': userModel.toJson(),
          'token': token.toString(),
        },
      },
    );
  } on FormatException catch (e) {
    print('❌ Erreur de format JSON: $e');
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {
        'success': false,
        'error': 'Format de requête invalide: $e',
      },
    );
  } catch (e, stackTrace) {
    print('❌ ERREUR DÉTAILLÉE : $e');
    print('📚 TRACE : $stackTrace');

    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Erreur serveur: ${e.toString()}',
      },
    );
  }
}