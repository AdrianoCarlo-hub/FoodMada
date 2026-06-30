// lib/domain/entities/commande_item.dart

class CommandeItem {
  final String id;
  final String commandeId;
  final String platId;
  final String nomPlat;
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

  CommandeItem copyWith({
    String? id,
    String? commandeId,
    String? platId,
    String? nomPlat,
    int? quantite,
    double? prixUnitaire,
  }) {
    return CommandeItem(
      id: id ?? this.id,
      commandeId: commandeId ?? this.commandeId,
      platId: platId ?? this.platId,
      nomPlat: nomPlat ?? this.nomPlat,
      quantite: quantite ?? this.quantite,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
    );
  }

  @override
  String toString() {
    return 'CommandeItem{nomPlat: $nomPlat, quantite: $quantite, prixUnitaire: $prixUnitaire}';
  }
}