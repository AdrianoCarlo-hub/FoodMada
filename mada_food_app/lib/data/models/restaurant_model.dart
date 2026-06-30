// lib/data/models/restaurant_model.dart
import '../../domain/entities/restaurant_entity.dart';

class RestaurantModel extends RestaurantEntity {
  const RestaurantModel({
    required super.id,
    required super.nom,
    required super.adresse,
    super.latitude,
    super.longitude,
    required super.estOuvert,
    required super.dateCreation,
    super.proprietaireId,  // ✅ AJOUTER
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      adresse: json['adresse']?.toString() ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      estOuvert: json['est_ouvert'] == true,
      dateCreation: json['date_creation'] != null
          ? DateTime.tryParse(json['date_creation'].toString()) ?? DateTime.now()
          : DateTime.now(),
      proprietaireId: json['proprietaire_id']?.toString(),  // ✅ AJOUTER
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'adresse': adresse,
      'latitude': latitude,
      'longitude': longitude,
      'est_ouvert': estOuvert,
      'date_creation': dateCreation.toIso8601String(),
      'proprietaire_id': proprietaireId,  // ✅ AJOUTER
    };
  }

  factory RestaurantModel.fromEntity(RestaurantEntity entity) {
    return RestaurantModel(
      id: entity.id,
      nom: entity.nom,
      adresse: entity.adresse,
      latitude: entity.latitude,
      longitude: entity.longitude,
      estOuvert: entity.estOuvert,
      dateCreation: entity.dateCreation,
      proprietaireId: entity.proprietaireId,  // ✅ AJOUTER
    );
  }
}
