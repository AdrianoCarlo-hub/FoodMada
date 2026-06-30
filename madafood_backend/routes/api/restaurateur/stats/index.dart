// routes/api/restaurateur/stats/index.dart
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/core/security/restaurateur_middleware.dart';
import 'package:madafood_backend/core/database_client.dart';
import 'package:madafood_backend/domain/entities/user.dart';
import 'package:postgres/postgres.dart';

Handler middleware(Handler handler) {
  return handler.use(restaurateurMiddleware);
}

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(
      statusCode: HttpStatus.methodNotAllowed,
      body: 'Méthode non autorisée. Utilisez GET.',
    );
  }

  try {
    final user = context.read<User?>();
    final restaurantId = user?.restaurantId;

    if (user == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Non authentifié'},
      );
    }

    if (restaurantId == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'Restaurant non associé'},
      );
    }

    final dbClient = context.read<DatabaseClient>();

    // 1️⃣ Nombre total de plats
    final platsResult = await dbClient.pool.execute(
      Sql.named('SELECT COUNT(*) as total FROM plats WHERE restaurant_id = @rid'),
      parameters: {'rid': restaurantId},
    );
    final totalPlats = int.tryParse(
      platsResult.first.toColumnMap()['total']?.toString() ?? '0'
    ) ?? 0;

    // 2️⃣ Nombre total de commandes
    final commandesResult = await dbClient.pool.execute(
      Sql.named('SELECT COUNT(*) as total FROM commandes WHERE restaurant_id = @rid'),
      parameters: {'rid': restaurantId},
    );
    final totalCommandes = int.tryParse(
      commandesResult.first.toColumnMap()['total']?.toString() ?? '0'
    ) ?? 0;

    // 3️⃣ CA du jour
    final caResult = await dbClient.pool.execute(
      Sql.named("""
        SELECT COALESCE(SUM(prix_total), 0) as total 
        FROM commandes 
        WHERE restaurant_id = @rid 
        AND DATE(date_creation) = CURRENT_DATE
        AND statut = 'LIVREE'
      """),
      parameters: {'rid': restaurantId},
    );
    final caJour = double.tryParse(
      caResult.first.toColumnMap()['total']?.toString() ?? '0'
    ) ?? 0;

    // 4️⃣ Commandes en attente
    final enAttenteResult = await dbClient.pool.execute(
      Sql.named("""
        SELECT COUNT(*) as total 
        FROM commandes 
        WHERE restaurant_id = @rid 
        AND statut = 'EN_ATTENTE'
      """),
      parameters: {'rid': restaurantId},
    );
    final enAttente = int.tryParse(
      enAttenteResult.first.toColumnMap()['total']?.toString() ?? '0'
    ) ?? 0;

    // 5️⃣ Commandes en préparation
    final enPreparationResult = await dbClient.pool.execute(
      Sql.named("""
        SELECT COUNT(*) as total 
        FROM commandes 
        WHERE restaurant_id = @rid 
        AND statut = 'PREPARATION'
      """),
      parameters: {'rid': restaurantId},
    );
    final enPreparation = int.tryParse(
      enPreparationResult.first.toColumnMap()['total']?.toString() ?? '0'
    ) ?? 0;

    return Response.json(
      body: {
        'success': true,
        'data': {
          'total_plats': totalPlats,
          'total_commandes': totalCommandes,
          'ca_jour': caJour,
          'en_attente': enAttente,
          'en_preparation': enPreparation,
        },
      },
    );
  } catch (e, stackTrace) {
    print('❌ Erreur stats: $e');
    print('📚 Stack: $stackTrace');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': 'Erreur: ${e.toString()}'},
    );
  }
}