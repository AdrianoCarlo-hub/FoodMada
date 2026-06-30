// lib/data/repositories_impl/commande_repository_impl.dart

import 'package:madafood_backend/core/database_client.dart';
import 'package:madafood_backend/domain/entities/commande.dart';
import 'package:madafood_backend/domain/repositories/commande_repository.dart';
import 'package:madafood_backend/data/models/commande_model.dart';
import 'package:madafood_backend/data/models/commande_item_model.dart';
import 'package:postgres/postgres.dart';

class CommandeRepositoryImpl implements CommandeRepository {
  final DatabaseClient _dbClient;

  CommandeRepositoryImpl(this._dbClient);

  /// Méthode privée mutualisée pour construire une Commande complète depuis SQL
  Future<Commande> _buildCommandeFromRow(Map<String, dynamic> cmdMap) async {
    final cmdId = cmdMap['id'] as String;

    final itemsResult = await _dbClient.pool.execute(
      r'''
      SELECT lc.id::text, lc.commande_id::text, lc.plat_id::text, p.nom as nom_plat, lc.quantite, lc.prix_unitaire::text 
      FROM lignes_commande lc
      JOIN plats p ON lc.plat_id = p.id
      WHERE lc.commande_id = $1
      ''',
      parameters: [cmdId],
    );

    final items = itemsResult.map((r) => CommandeItemModel.fromJson(r.toColumnMap())).toList();
    
    double calculSousTotal = 0;
    for (final item in items) {
      calculSousTotal += item.prixUnitaire * item.quantite;
    }

    final commandeJson = {
      ...cmdMap,
      'sous_total': calculSousTotal,
      'frais_livraison': double.parse(cmdMap['prix_total'].toString()) - calculSousTotal,
      'total': cmdMap['prix_total'],
      'adresse_livraison': cmdMap['adresse_livraison'],
    };

    return CommandeModel.fromJson(commandeJson, items: items);
  }

  @override
  Future<Commande> creerCommande({
    required String clientId,
    required String restaurantId,
    required List<Map<String, dynamic>> itemsBruts,
    required double fraisLivraison,
    String? adresseLivraison,
    String? modePaiement,
  }) async {
    double sousTotal = 0;
    final listItemsAInserer = <Map<String, dynamic>>[];

    for (final item in itemsBruts) {
      final platId = item['plat_id'] as String;
      final quantite = int.parse(item['quantite'].toString());

      final platResult = await _dbClient.pool.execute(
        'SELECT nom, prix::text FROM plats WHERE id = \$1',
        parameters: [platId],
      );

      if (platResult.isEmpty) throw Exception('Plat $platId inexistant.');

      final nomPlat = platResult.first.toColumnMap()['nom'] as String;
      final prixUnitaire = double.parse(platResult.first.toColumnMap()['prix'] as String);
      
      sousTotal += prixUnitaire * quantite;
      listItemsAInserer.add({'plat_id': platId, 'nom_plat': nomPlat, 'quantite': quantite, 'prix_unitaire': prixUnitaire});
    }

    final prixTotalFinal = sousTotal + fraisLivraison;

    return await _dbClient.pool.runTx((ctx) async {
      // ✅ CORRECTION 1 : Utiliser Sql.named avec des paramètres nommés
      final cmdResult = await ctx.execute(
        Sql.named('''
          INSERT INTO commandes (client_id, restaurant_id, prix_total, methode_paiement, statut)
          VALUES (@client_id, @restaurant_id, @prix_total, @methode_paiement, 'EN_ATTENTE'::statut_commande_enum)
          RETURNING id::text, client_id::text, restaurant_id::text, prix_total::text, methode_paiement, statut::text, date_creation::text
        '''),
        parameters: {
          'client_id': clientId,
          'restaurant_id': restaurantId,
          'prix_total': prixTotalFinal,
          'methode_paiement': modePaiement ?? 'MVOLA',
        },
      );

      final rowMap = cmdResult.first.toColumnMap();
      final commandeId = rowMap['id'] as String;

      // ✅ CORRECTION 2 : Utiliser Sql.named pour les lignes de commande
      for (final item in listItemsAInserer) {
        await ctx.execute(
          Sql.named('''
            INSERT INTO lignes_commande (commande_id, plat_id, quantite, prix_unitaire) 
            VALUES (@commande_id, @plat_id, @quantite, @prix_unitaire)
          '''),
          parameters: {
            'commande_id': commandeId,
            'plat_id': item['plat_id'],
            'quantite': item['quantite'],
            'prix_unitaire': item['prix_unitaire'],
          },
        );
      }

      return await _buildCommandeFromRow(rowMap);
    });
  }

  @override
  Future<List<Commande>> getCommandesByClient(String clientId) async {
    // ✅ CORRECTION 3 : Utiliser Sql.named
    final results = await _dbClient.pool.execute(
      Sql.named('''
        SELECT id::text, client_id::text, restaurant_id::text, prix_total::text, 
               methode_paiement, statut::text, date_creation::text 
        FROM commandes 
        WHERE client_id = @client_id 
        ORDER BY date_creation DESC
      '''),
      parameters: {'client_id': clientId},
    );

    final list = <Commande>[];
    for (final row in results) {
      list.add(await _buildCommandeFromRow(row.toColumnMap()));
    }
    return list;
  }

  @override
  Future<List<Commande>> getAllCommandes({String? restaurantId, String? statut}) async {
    String sql = 'SELECT id::text, client_id::text, restaurant_id::text, prix_total::text, methode_paiement, statut::text, date_creation::text FROM commandes WHERE 1=1';
    final params = <String, dynamic>{};

    if (restaurantId != null) { sql += ' AND restaurant_id = @rid'; params['rid'] = restaurantId; }
    if (statut != null) { sql += ' AND statut = @statut::statut_commande_enum'; params['statut'] = statut; }
    
    sql += ' ORDER BY date_creation DESC';

    final results = await _dbClient.pool.execute(Sql.named(sql), parameters: params);
    final list = <Commande>[];
    for (final row in results) {
      list.add(await _buildCommandeFromRow(row.toColumnMap()));
    }
    return list;
  }

  @override
  Future<Commande?> changerStatutCommande(String commandeId, String nouveauStatut) async {
    // 1. Récupérer la commande actuelle
    final commandeActuelle = await getCommandeById(commandeId);
    if (commandeActuelle == null) return null;

    // 2. Définir les règles de transition (State Machine simple)
    final statutActuel = commandeActuelle.statut;
    
    bool estValide = false;
    
    if (nouveauStatut == 'ANNULEE') {
      estValide = statutActuel != 'LIVREE';
    } else if (statutActuel == 'EN_ATTENTE' && nouveauStatut == 'PREPARATION') {
      estValide = true;
    } else if (statutActuel == 'PREPARATION' && nouveauStatut == 'EN_LIVRAISON') {
      estValide = true;
    } else if (statutActuel == 'EN_LIVRAISON' && nouveauStatut == 'LIVREE') {
      estValide = true;
    }

    if (!estValide) {
      throw InvalidStatusTransitionException(
        'Transition impossible de $statutActuel vers $nouveauStatut'
      );
    }

    // ✅ CORRECTION 4 : Utiliser Sql.named
    final result = await _dbClient.pool.execute(
      Sql.named('''
        UPDATE commandes SET statut = @statut::statut_commande_enum 
        WHERE id = @id 
        RETURNING id::text, client_id::text, restaurant_id::text, prix_total::text, methode_paiement, statut::text, date_creation::text
      '''),
      parameters: {
        'id': commandeId,
        'statut': nouveauStatut,
      },
    );

    if (result.isEmpty) return null;
    return await _buildCommandeFromRow(result.first.toColumnMap());
  }

  @override
  Future<List<Commande>> getCommandesByRestaurant(String restaurantId) async {
    final results = await _dbClient.pool.execute(
      Sql.named('''
        SELECT id::text, client_id::text, restaurant_id::text, prix_total::text, 
               methode_paiement, statut::text, date_creation::text 
        FROM commandes 
        WHERE restaurant_id = @rid 
        ORDER BY date_creation DESC
      '''),
      parameters: {'rid': restaurantId},
    );
    
    final list = <Commande>[];
    for (final row in results) {
      list.add(await _buildCommandeFromRow(row.toColumnMap()));
    }
    return list;
  }

  @override
  Future<Commande?> getCommandeById(String id) async {
    final result = await _dbClient.pool.execute(
      Sql.named('''
        SELECT id::text, client_id::text, restaurant_id::text, prix_total::text, 
               methode_paiement, statut::text, date_creation::text 
        FROM commandes 
        WHERE id = @id
      '''),
      parameters: {'id': id},
    );
    
    if (result.isEmpty) return null;
    
    return await _buildCommandeFromRow(result.first.toColumnMap());
  }
}