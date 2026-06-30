// lib/domain/entities/commande_item.dart

class CommandeItem {
  final String id;
  final String commandeId;
  final String platId;
  final String nomPlat; // Redondance utile pour l'historique si le plat change de nom
  final int quantite;
  final double prixUnitaire;

  CommandeItem({
    required this.id,
    required this.commandeId,
    required this.platId,
    required this.nomPlat,
    required this.quantite,
    required this.prixUnitaire,
  });

  double get sousTotal => prixUnitaire * quantite;
}