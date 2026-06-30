// lib/domain/entities/restaurant_entity.dart
class RestaurantEntity {
  final String id;
  final String nom;
  final String adresse;
  final double? latitude;
  final double? longitude;
  final bool estOuvert;
  final DateTime dateCreation;
  final String? proprietaireId;  // ✅ AJOUTER

  const RestaurantEntity({
    required this.id,
    required this.nom,
    required this.adresse,
    this.latitude,
    this.longitude,
    required this.estOuvert,
    required this.dateCreation,
    this.proprietaireId,  // ✅ AJOUTER
  });
}
