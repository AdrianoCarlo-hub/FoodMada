// lib/domain/entities/commande.dart

import 'package:madafood_backend/domain/entities/commande_item.dart';

class Commande {
  final String id;
  final String clientId;
  final String restaurantId;
  final List<CommandeItem> items;
  final double sousTotal;
  final double fraisLivraison;
  final double total;
  final String statut; // EN_ATTENTE, ACCEPTEE, EN_PREPARATION, EN_COURS_DE_LIVRAISON, LIVREE, ANNULEE
  final String? adresseLivraison;
  final String? modePaiement; // MVOLA, ORANGE_MONEY, AIRTEL_MONEY
  final DateTime dateCreation;

  Commande({
    required this.id,
    required this.clientId,
    required this.restaurantId,
    required this.items,
    required this.sousTotal,
    required this.fraisLivraison,
    required this.total,
    required this.statut,
    this.adresseLivraison,
    this.modePaiement,
    required this.dateCreation,
  });
}