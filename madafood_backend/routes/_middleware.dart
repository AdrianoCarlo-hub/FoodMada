// routes/_middleware.dart
import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/core/database_client.dart';
import 'package:madafood_backend/core/security/jwt_service_impl.dart';
import 'package:madafood_backend/core/security/auth_middleware.dart';
import 'package:madafood_backend/core/error_handler_middleware.dart';
import 'package:madafood_backend/data/repositories_impl/user_repository_impl.dart';
import 'package:madafood_backend/data/repositories_impl/restaurant_repository_impl.dart';
import 'package:madafood_backend/data/repositories_impl/plat_repository_impl.dart';
import 'package:madafood_backend/data/repositories_impl/commande_repository_impl.dart';
import 'package:madafood_backend/data/repositories_impl/auth_repository_impl.dart';
import 'package:madafood_backend/data/repositories_impl/restaurateur_repository_impl.dart';
import 'package:madafood_backend/domain/repositories/user_repository.dart';
import 'package:madafood_backend/domain/repositories/restaurant_repository.dart';
import 'package:madafood_backend/domain/repositories/plat_repository.dart';
import 'package:madafood_backend/domain/repositories/commande_repository.dart';
import 'package:madafood_backend/domain/repositories/i_auth_repository.dart';
import 'package:madafood_backend/domain/repositories/restaurateur_repository.dart';
import 'package:madafood_backend/domain/services/token_service.dart';
import 'package:madafood_backend/core/helpers/decoder_helper.dart';

// 1. Initialisation unique du client
final dbClient = DatabaseClient.initialize();
final tokenService = JwtServiceImpl();

// 2. Initialisation globale des instances
final userRepository = UserRepositoryImpl(dbClient);
final restaurantRepository = RestaurantRepositoryImpl(dbClient);
final platRepository = PlatRepositoryImpl(dbClient);
final commandeRepository = CommandeRepositoryImpl(dbClient);
final authRepository = AuthRepositoryImpl(dbClient, tokenService);
final restaurateurRepository = RestaurateurRepositoryImpl(dbClient);

Handler middleware(Handler handler) {
  // ✅ Pipeline avec TOUS les providers
  final pipeline = handler
      .use(provider<DatabaseClient>((_) => dbClient))
      .use(provider<TokenService>((_) => tokenService))
      .use(provider<UserRepository>((_) => userRepository))
      .use(provider<RestaurantRepository>((_) => restaurantRepository))
      .use(provider<PlatRepository>((_) => platRepository))
      .use(provider<CommandeRepository>((_) => commandeRepository))
      .use(provider<IAuthRepository>((_) => authRepository))
      .use(provider<RestaurateurRepository>((_) => restaurateurRepository))
      .use(authMiddleware())  // ✅ FOURNIT User? au contexte
      .use(errorHandlerMiddleware);

  // 🔥 Gestion CORS
  return (context) async {
    // ✅ Gestion des requêtes OPTIONS (pre-flight)
    if (context.request.method == HttpMethod.options) {
      return Response(
        statusCode: 204,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
          'Access-Control-Allow-Credentials': 'true',
          'Access-Control-Max-Age': '86400',
        },
      );
    }

    // ✅ Exécuter le pipeline
    final response = await pipeline(context);

    // ✅ Ajouter les headers CORS à la réponse
    return response.copyWith(
      headers: {
        ...response.headers,
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
        'Access-Control-Allow-Credentials': 'true',
      },
    );
  };
}