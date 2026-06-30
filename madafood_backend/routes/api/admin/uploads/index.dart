import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:mime/mime.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) return Response(statusCode: 405);

  final formData = await context.request.formData();
  final file = formData.files['image']; // 'image' est la clé envoyée par Flutter

  if (file == null) return Response.json(statusCode: 400, body: {'error': 'Aucun fichier'});

  // Sauvegarde dans un dossier 'public/uploads'
  final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
  final path = 'public/uploads/$fileName';
  await File(path).writeAsBytes(await file.readAsBytes());

  // Retourne l'URL publique
  return Response.json(body: {'url': 'https://votre-domaine.com/uploads/$fileName'});
}