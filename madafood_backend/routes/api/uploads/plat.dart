// routes/api/uploads/plat.dart
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:madafood_backend/core/security/restaurateur_middleware.dart';

Handler middleware(Handler handler) {
  return handler.use(restaurateurMiddleware);
}

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Méthode non autorisée. Utilisez POST'},
    );
  }

  try {
    final formData = await context.request.formData();
    final file = formData.files['image'];

    if (file == null) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'Aucune image fournie'},
      );
    }

    // ✅ Vérifier le type MIME
    final mimeType = file.contentType.value;
    if (!mimeType.startsWith('image/')) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'Le fichier doit être une image'},
      );
    }

    // ✅ Récupérer l'ID du plat (optionnel)
    final platId = formData.fields['plat_id'] ?? 
                    DateTime.now().millisecondsSinceEpoch.toString();

    // ✅ Déterminer l'extension
    String extension = '.jpg';
    if (mimeType.contains('png')) extension = '.png';
    if (mimeType.contains('jpeg') || mimeType.contains('jpg')) extension = '.jpg';
    if (mimeType.contains('webp')) extension = '.webp';
    if (mimeType.contains('gif')) extension = '.gif';

    // ✅ Générer un nom de fichier unique
    final fileName = 'plat_${platId}_${DateTime.now().millisecondsSinceEpoch}$extension';
    final uploadDir = Directory('public/uploads/plats');
    
    if (!await uploadDir.exists()) {
      await uploadDir.create(recursive: true);
    }

    // ✅ Sauvegarder le fichier
    final bytes = await file.readAsBytes();
    final fileHandle = File(path.join(uploadDir.path, fileName));
    await fileHandle.writeAsBytes(bytes);

    // ✅ Retourner l'URL
    final imageUrl = '/uploads/plats/$fileName';

    return Response.json(
      statusCode: 200,
      body: {
        'success': true,
        'url': imageUrl,
        'filename': fileName,
        'message': 'Image uploadée avec succès',
      },
    );
  } catch (e) {
    print('🚨 Erreur upload: $e');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Erreur interne lors de l\'upload'},
    );
  }
}