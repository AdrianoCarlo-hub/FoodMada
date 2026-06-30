// routes/api/admin/commandes/index.dart
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/core/security/admin_middleware.dart';
import 'package:madafood_backend/core/database_client.dart';
import 'package:postgres/postgres.dart';

Handler middleware(Handler handler) => handler.use(adminMiddleware);

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final dbClient = context.read<DatabaseClient>();
    final params = context.request.uri.queryParameters;
    
    String sql = '''
      SELECT id, client_id, restaurant_id, prix_total, 
             methode_paiement, statut::text, date_creation
      FROM commandes
      WHERE 1=1
    ''';
    final Map<String, dynamic> queryParams = {};

    if (params.containsKey('statut')) {
      sql += ' AND statut = @statut';
      queryParams['statut'] = params['statut'];
    }

    if (params.containsKey('restaurant_id')) {
      sql += ' AND restaurant_id = @restaurant_id';
      queryParams['restaurant_id'] = params['restaurant_id'];
    }

    sql += ' ORDER BY date_creation DESC';

    final result = await dbClient.pool.execute(
      Sql.named(sql),
      parameters: queryParams,
    );

    final commandes = <Map<String, dynamic>>[];
    for (final row in result) {
      final map = row.toColumnMap();
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

      commandes.add(commandeData);
    }

    return Response.json(
      body: {
        'success': true,
        'data': commandes,
      },
    );
  } catch (e, stackTrace) {
    print('❌ Erreur getAllCommandes: $e');
    print('📚 Stack: $stackTrace');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': 'Erreur: ${e.toString()}'},
    );
  }
}