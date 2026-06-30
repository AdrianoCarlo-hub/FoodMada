// lib/domain/entities/commande.dart

import 'commande_item.dart';

class Commande {
  final String id;
  final String clientId;
  final String restaurantId;
  final List<CommandeItem> items;
  final double sousTotal;
  final double fraisLivraison;
  final double total;
  final String statut; // EN_ATTENTE, PREPARATION, EN_LIVRAISON, LIVREE, ANNULEE
  final String? adresseLivraison;
  final String? modePaiement;
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

  Commande copyWith({
    String? id,
    String? clientId,
    String? restaurantId,
    List<CommandeItem>? items,
    double? sousTotal,
    double? fraisLivraison,
    double? total,
    String? statut,
    String? adresseLivraison,
    String? modePaiement,
    DateTime? dateCreation,
  }) {
    return Commande(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      restaurantId: restaurantId ?? this.restaurantId,
      items: items ?? this.items,
      sousTotal: sousTotal ?? this.sousTotal,
      fraisLivraison: fraisLivraison ?? this.fraisLivraison,
      total: total ?? this.total,
      statut: statut ?? this.statut,
      adresseLivraison: adresseLivraison ?? this.adresseLivraison,
      modePaiement: modePaiement ?? this.modePaiement,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }

  @override
  String toString() {
    return 'Commande{id: $id, statut: $statut, total: $total}';
  }
}