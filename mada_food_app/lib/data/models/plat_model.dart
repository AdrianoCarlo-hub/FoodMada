// lib/data/models/plat_model.dart
import '../../domain/entities/plat.dart';

class PlatModel extends Plat {
  PlatModel({
    required super.id,
    required super.restaurantId,
    required super.nom,
    super.description,
    required super.prix,
    super.categorie,
    required super.estDisponible,
    DateTime? dateCreation,
    DateTime? dateModification,
  }) : super(
    dateCreation: dateCreation ?? DateTime.now(),
  );

  factory PlatModel.fromJson(Map<String, dynamic> json) {
    return PlatModel(
      id: json['id']?.toString() ?? '',
      restaurantId: json['restaurant_id']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      description: json['description']?.toString(),
      prix: double.tryParse(json['prix']?.toString() ?? '0') ?? 0.0,
      categorie: json['categorie']?.toString(),
      estDisponible: json['est_disponible'] == true,
      dateCreation: json['date_creation'] != null
          ? DateTime.tryParse(json['date_creation']) ?? DateTime.now()
          : DateTime.now(),
      dateModification: json['date_modification'] != null
          ? DateTime.tryParse(json['date_modification'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'nom': nom,
      'description': description,
      'prix': prix,
      'categorie': categorie,
      'est_disponible': estDisponible,
      'date_creation': dateCreation.toIso8601String(),
    };
  }

  factory PlatModel.fromEntity(Plat entity) {
    return PlatModel(
      id: entity.id,
      restaurantId: entity.restaurantId,
      nom: entity.nom,
      description: entity.description,
      prix: entity.prix,
      categorie: entity.categorie,
      estDisponible: entity.estDisponible,
      dateCreation: entity.dateCreation,
    );
  }
}
