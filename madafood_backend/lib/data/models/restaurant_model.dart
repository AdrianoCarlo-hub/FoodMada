import 'package:madafood_backend/domain/entities/restaurant.dart';

class RestaurantModel extends Restaurant {
  RestaurantModel({
    required super.id,
    required super.nom,
    required super.adresse,
    super.latitude,
    super.longitude,
    required super.estOuvert,
    required super.dateCreation,
  });

  factory RestaurantModel.fromEntity(Restaurant entity) {
    return RestaurantModel(
      id: entity.id,
      nom: entity.nom,
      adresse: entity.adresse,
      latitude: entity.latitude,
      longitude: entity.longitude,
      estOuvert: entity.estOuvert,
      dateCreation: entity.dateCreation,
    );
  }

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id']?.toString() ?? '',
      nom: json['nom']?.toString() ?? 'Restaurant',
      adresse: json['adresse']?.toString() ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      estOuvert: _parseBool(json['est_ouvert'], defaultValue: true),
      dateCreation: _parseDate(json['date_creation']),
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
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static bool _parseBool(dynamic value, {required bool defaultValue}) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value?.toString().toLowerCase();
    if (text == 'true') return true;
    if (text == 'false') return false;

    return defaultValue;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
