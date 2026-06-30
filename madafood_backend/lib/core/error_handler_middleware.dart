import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/domain/repositories/commande_repository.dart'; // Pour l'exception personnalisée

Handler errorHandlerMiddleware(Handler handler) {
  return (context) async {
    try {
      return await handler(context);
    } catch (error, stackTrace) {
      print('🚨 [GLOBAL ERROR] : $error\n$stackTrace');
      
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {
          'success': false,
          'message': 'Une erreur est survenue sur le serveur.',
          'code': 'INTERNAL_ERROR',
        },
      );
    }
  };
}