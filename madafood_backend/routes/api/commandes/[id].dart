import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/core/database_client.dart';
import 'package:madafood_backend/core/security/auth_middleware.dart';
import 'package:madafood_backend/domain/entities/user.dart';
import 'package:postgres/postgres.dart';

Handler middleware(Handler handler) {
  return handler.use(authMiddleware());
}

// ✅ La fonction onRequest doit accepter un paramètre 'id' supplémentaire
Future<Response> onRequest(RequestContext context, String id) async {
  final user = context.read<User?>();
  final dbClient = context.read<DatabaseClient>();

  if (user == null) {
    return Response.json(
      statusCode: 401,
      body: {'error': 'Non authentifié'},
    );
  }

  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Méthode non autorisée'},
    );
  }

  try {
    // Récupérer la commande
    final commandeResult = await dbClient.pool.execute(
      Sql.named('''
        SELECT c.id, c.client_id, c.restaurant_id, c.prix_total, c.methode_paiement,
               c.statut::text, c.date_creation, r.nom as restaurant_nom,
               u.nom as client_nom
        FROM commandes c
        LEFT JOIN restaurants r ON c.restaurant_id = r.id
        LEFT JOIN utilisateurs u ON c.client_id = u.id
        WHERE c.id = @cid AND c.client_id = @client_id
      '''),
      parameters: {
        'cid': id,
        'client_id': user.id,
      },
    );

    if (commandeResult.isEmpty) {
      return Response.json(
        statusCode: 404,
        body: {'error': 'Commande non trouvée'},
      );
    }

    final commandeRow = commandeResult.first;
    final map = commandeRow.toColumnMap();

    // Récupérer les lignes de commande
    final lignesResult = await dbClient.pool.execute(
      Sql.named('''
        SELECT l.id, l.plat_id, l.quantite, l.prix_unitaire, p.nom as nom_plat
        FROM lignes_commande l
        LEFT JOIN plats p ON l.plat_id = p.id
        WHERE l.commande_id = @cid
      '''),
      parameters: {'cid': id},
    );

    final itemsList = lignesResult.map((row) {
      final lMap = row.toColumnMap();
      return {
        'id': lMap['id'].toString(),
        'plat_id': lMap['plat_id'].toString(),
        'nom_plat': lMap['nom_plat']?.toString() ?? 'Plat',
        'quantite': int.tryParse(lMap['quantite'].toString()) ?? 1,
        'prix_unitaire': double.tryParse(lMap['prix_unitaire'].toString() ?? '0') ?? 0,
      };
    }).toList();

    return Response.json(
      statusCode: 200,
      body: {
        'success': true,
        'data': {
          'id': map['id'].toString(),
          'client_id': map['client_id'].toString(),
          'restaurant_id': map['restaurant_id'].toString(),
          'prix_total': double.tryParse(map['prix_total']?.toString() ?? '0') ?? 0,
          'methode_paiement': map['methode_paiement']?.toString(),
          'statut': map['statut']?.toString() ?? 'EN_ATTENTE',
          'date_creation': map['date_creation'].toString(),
          'restaurant_nom': map['restaurant_nom']?.toString(),
          'client_nom': map['client_nom']?.toString(),
          'items': itemsList,
        },
      },
    );
  } catch (e, stack) {
    print('❌ Erreur récupération commande: $e');
    print('��� Stack: $stack');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Erreur lors de la récupération de la commande: $e'},
    );
  }
}
