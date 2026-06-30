import 'package:madafood_backend/domain/entities/commande.dart';
import 'package:madafood_backend/domain/entities/commande_item.dart';
import 'package:madafood_backend/data/models/commande_item_model.dart';

class CommandeModel extends Commande {
  CommandeModel({
    required super.id,
    required super.clientId,
    required super.restaurantId,
    required super.items,
    required super.sousTotal,
    required super.fraisLivraison,
    required super.total,
    required super.statut,
    super.adresseLivraison,
    super.modePaiement,
    required super.dateCreation,
  });

  // 1. Méthode statique pour la Solution 1 (hors de fromJson)
  static CommandeModel fromEntity(Commande entity) {
    return CommandeModel(
      id: entity.id,
      clientId: entity.clientId,
      restaurantId: entity.restaurantId,
      items: entity.items,
      sousTotal: entity.sousTotal,
      fraisLivraison: entity.fraisLivraison,
      total: entity.total,
      statut: entity.statut,
      adresseLivraison: entity.adresseLivraison,
      modePaiement: entity.modePaiement,
      dateCreation: entity.dateCreation,
    );
  }

  // 2. Factory séparée pour fromJson
  factory CommandeModel.fromJson(Map<String, dynamic> json, {required List<CommandeItemModel> items}) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    return CommandeModel(
      id: json['id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      restaurantId: json['restaurant_id']?.toString() ?? '',
      items: items.cast<CommandeItem>(),
      sousTotal: parseDouble(json['sous_total']),
      fraisLivraison: parseDouble(json['frais_livraison']),
      total: parseDouble(json['total'] ?? json['prix_total']),
      statut: json['statut']?.toString() ?? 'EN_ATTENTE',
      adresseLivraison: json['adresse_livraison'] as String?,
      modePaiement: json['methode_paiement'] as String?,
      dateCreation: json['date_creation'] == null
          ? DateTime.now()
          : (json['date_creation'] is DateTime
              ? json['date_creation'] as DateTime
              : DateTime.tryParse(json['date_creation'].toString()) ?? DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'restaurant_id': restaurantId,
      'items': items.map((item) {
        if (item is CommandeItemModel) {
          return item.toJson();
        }
        return {
          'plat_id': item.platId,
          'nom_plat': item.nomPlat,
          'quantite': item.quantite,
          'prix_unitaire': item.prixUnitaire,
        };
      }).toList(),
      'sous_total': sousTotal,
      'frais_livraison': fraisLivraison,
      'total': total,
      'statut': statut,
      'adresse_livraison': adresseLivraison,
      'mode_paiement': modePaiement,
      'date_creation': dateCreation.toIso8601String(),
    };
  }
}