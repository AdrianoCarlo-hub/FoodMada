// lib/data/models/commande_model.dart
import '../../domain/entities/commande.dart';
import '../../domain/entities/commande_item.dart';
import 'commande_item_model.dart';

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

  factory CommandeModel.fromJson(Map<String, dynamic> json) {
    // ✅ Extraire les items avec gestion des nulls
    final itemsList = json['items'] as List? ?? [];
    final items = itemsList
        .map((item) => CommandeItemModel.fromJson(item as Map<String, dynamic>))
        .toList();

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return CommandeModel(
      id: json['id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      restaurantId: json['restaurant_id']?.toString() ?? '',
      items: items,
      sousTotal: parseDouble(json['sous_total'] ?? json['prix_total']),
      fraisLivraison: parseDouble(json['frais_livraison'] ?? 0),
      total: parseDouble(json['total'] ?? json['prix_total']),
      statut: json['statut']?.toString() ?? 'EN_ATTENTE',
      adresseLivraison: json['adresse_livraison']?.toString(),
      modePaiement: json['methode_paiement']?.toString() ?? json['mode_paiement']?.toString(),
      dateCreation: parseDate(json['date_creation']),
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