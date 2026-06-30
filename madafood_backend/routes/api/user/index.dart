// routes/api/user/index.dart
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/domain/repositories/user_repository.dart';

Future<Response> onRequest(RequestContext context) async {
// ... le reste de ton code ne change pas
  // On récupère notre repository depuis le middleware
  final userRepository = context.read<UserRepository>();

  // Si Flutter fait une requête POST (ex: Inscription)
  if (context.request.method == HttpMethod.post) {
    try {
      // On lit le JSON envoyé par l'application mobile
      final body = await context.request.json() as Map<String, dynamic>;

      // On appelle notre fonction SQL pour créer l'utilisateur
      final newUser = await userRepository.createUser(
        nom: body['nom'] as String,
        telephone: body['telephone'] as String,
        motDePasse: body['mot_de_passe'] as String, // En clair pour l'instant
        role: body['role'] as String? ?? 'CLIENT',
      );

      // On renvoie un succès (201 Created) avec les infos du profil
      return Response.json(
        statusCode: HttpStatus.created,
        body: {
          'message': 'Utilisateur créé avec succès',
          'user': {
            'id': newUser.id,
            'nom': newUser.nom,
            'telephone': newUser.telephone,
            'role': newUser.role,
          }
        },
      );
    } catch (e) {
      // Cette ligne va imprimer la vraie erreur SQL dans le terminal de ton serveur
      print('Erreur PostgreSQL : $e'); 
      
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'erreur': "Impossible de créer l'utilisateur. Vérifiez les données."},
      );
    }
  }

  // Si la méthode n'est pas supportée (ex: GET, PUT)
  return Response(statusCode: HttpStatus.methodNotAllowed);
}