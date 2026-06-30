import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:madafood_backend/core/security/restaurateur_middleware.dart';

// Utilisation du middleware pour protéger cette route
Handler middleware(Handler handler) {
  return handler.use(restaurateurMiddleware);
}

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(statusCode: 405, body: {'error': 'Méthode non autorisée'});
  }

  try {
    final formData = await context.request.formData();
    final file = formData.files['image'];

    if (file == null) {
      return Response.json(statusCode: 400, body: {'error': 'Aucune image fournie'});
    }

    // Validation du type MIME
    final mimeType = file.contentType.value;
    if (!mimeType.startsWith('image/')) {
      return Response.json(statusCode: 400, body: {'error': 'Le fichier doit être une image'});
    }

    // Génération d'un nom de fichier sécurisé
    final ext = extensionFromMime(mimeType) ?? 'jpg';
    final fileName = 'plat_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final uploadDir = Directory('public/uploads/plats');
    
    if (!await uploadDir.exists()) {
      await uploadDir.create(recursive: true);
    }

    // Sauvegarde du fichier
    final bytes = await file.readAsBytes();
    final fileHandle = File(path.join(uploadDir.path, fileName));
    await fileHandle.writeAsBytes(bytes);

    return Response.json(
      statusCode: 200,
      body: {
        'success': true,
        'url': '/uploads/plats/$fileName',
      },
    );
  } catch (e) {
    print('🚨 Erreur lors de l\'upload : $e');
    return Response.json(statusCode: 500, body: {'error': 'Erreur interne'});
  }
}