// lib/domain/entities/restaurant.dart

class Restaurant {
  final String id;
  final String nom;
  final String adresse;
  final double? latitude;
  final double? longitude;
  final bool estOuvert;
  final DateTime dateCreation;

  Restaurant({
    required this.id,
    required this.nom,
    required this.adresse,
    this.latitude,
    this.longitude,
    required this.estOuvert,
    required this.dateCreation,
  });
}