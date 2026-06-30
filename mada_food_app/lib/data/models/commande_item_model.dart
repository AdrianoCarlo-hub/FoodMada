// lib/data/models/commande_item_model.dart
import '../../domain/entities/commande_item.dart';

class CommandeItemModel extends CommandeItem {
  CommandeItemModel({
    required super.id,
    required super.commandeId,
    required super.platId,
    required super.nomPlat,
    required super.quantite,
    required super.prixUnitaire,
  });

  factory CommandeItemModel.fromJson(Map<String, dynamic> json) {
    return CommandeItemModel(
      id: json['id']?.toString() ?? '',
      commandeId: json['commande_id']?.toString() ?? '',
      platId: json['plat_id']?.toString() ?? '',
      nomPlat: json['nom_plat']?.toString() ?? '',
      quantite: int.tryParse(json['quantite']?.toString() ?? '1') ?? 1,
      prixUnitaire: double.tryParse(json['prix_unitaire']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commande_id': commandeId,
      'plat_id': platId,
      'nom_plat': nomPlat,
      'quantite': quantite,
      'prix_unitaire': prixUnitaire,
    };
  }
}