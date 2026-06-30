// routes/api/admin/commandes/[id].dart
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/core/security/admin_middleware.dart';
import 'package:madafood_backend/core/database_client.dart';
import 'package:postgres/postgres.dart';

Handler middleware(Handler handler) => handler.use(adminMiddleware);

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final dbClient = context.read<DatabaseClient>();

    // Récupérer la commande
    final result = await dbClient.pool.execute(
      Sql.named('''
        SELECT id, client_id, restaurant_id, prix_total, 
               methode_paiement, statut::text, date_creation
        FROM commandes
        WHERE id = @id
      '''),
      parameters: {'id': id},
    );

    if (result.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'Commande non trouvée'},
      );
    }

    final map = result.first.toColumnMap();
    final commandeId = map['id'].toString();

    // Récupérer les items
    final itemsResult = await dbClient.pool.execute(
      Sql.named('''
        SELECT lc.id, lc.commande_id, lc.plat_id, p.nom as nom_plat, 
               lc.quantite, lc.prix_unitaire
        FROM lignes_commande lc
        JOIN plats p ON lc.plat_id = p.id
        WHERE lc.commande_id = @commande_id
      '''),
      parameters: {'commande_id': commandeId},
    );

    final items = itemsResult.map((r) => r.toColumnMap()).toList();

    // ✅ CONVERTIR LES DATETIME EN STRING
    final commandeData = {
      'id': map['id'].toString(),
      'client_id': map['client_id'].toString(),
      'restaurant_id': map['restaurant_id'].toString(),
      'prix_total': double.tryParse(map['prix_total']?.toString() ?? '0') ?? 0,
      'methode_paiement': map['methode_paiement']?.toString(),
      'statut': map['statut'].toString(),
      'date_creation': map['date_creation'] is DateTime
          ? (map['date_creation'] as DateTime).toIso8601String()
          : map['date_creation'].toString(),
      'items': items.map((item) => {
        'id': item['id'].toString(),
        'commande_id': item['commande_id'].toString(),
        'plat_id': item['plat_id'].toString(),
        'nom_plat': item['nom_plat'].toString(),
        'quantite': int.tryParse(item['quantite'].toString()) ?? 0,
        'prix_unitaire': double.tryParse(item['prix_unitaire'].toString()) ?? 0,
      }).toList(),
    };

    return Response.json(
      body: {
        'success': true,
        'data': commandeData,
      },
    );
  } catch (e, stackTrace) {
    print('❌ Erreur getCommandeById: $e');
    print('📚 Stack: $stackTrace');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': 'Erreur: ${e.toString()}'},
    );
  }
}