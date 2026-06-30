import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:path/path.dart' as p;

Future<Response> onRequest(RequestContext context, String filename) async {
  final imagesDir = Directory('${Directory.current.path}/public/uploads');
  final file = File(p.join(imagesDir.path, filename));

  if (!await file.exists()) {
    return Response.json(
      statusCode: HttpStatus.notFound,
      body: {'error': 'Image introuvable'},
    );
  }

  final bytes = await file.readAsBytes();

  return Response.bytes(
    body: bytes,
    headers: {
      HttpHeaders.contentTypeHeader: 'image/jpeg',
    },
  );
}