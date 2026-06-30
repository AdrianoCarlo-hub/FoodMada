import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/core/security/restaurateur_middleware.dart';

Handler middleware(Handler handler) {
  return handler.use(restaurateurMiddleware);
}