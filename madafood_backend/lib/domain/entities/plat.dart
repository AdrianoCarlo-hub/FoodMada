class Plat {
  final String id;
  final String restaurantId;
  final String nom;
  final String? description;
  final double prix;
  final bool estDisponible;

  Plat({
    required this.id,
    required this.restaurantId,
    required this.nom,
    this.description,
    required this.prix,
    required this.estDisponible,
  });
}