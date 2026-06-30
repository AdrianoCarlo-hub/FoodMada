// lib/domain/entities/plat.dart
class Plat {
  final String id;
  final String restaurantId;
  final String nom;
  final String? description;
  final double prix;
  final String? categorie;
  final bool estDisponible;
  final DateTime dateCreation;

  Plat({
    required this.id,
    required this.restaurantId,
    required this.nom,
    this.description,
    required this.prix,
    this.categorie,
    this.estDisponible = true,
    required this.dateCreation,
  });

  factory Plat.fromJson(Map<String, dynamic> json) {
    return Plat(
      id: json['id']?.toString() ?? '',
      restaurantId: json['restaurant_id']?.toString() ?? '',
      nom: json['nom'] ?? '',
      description: json['description']?.toString(),
      prix: (json['prix'] ?? 0).toDouble(),
      categorie: json['categorie']?.toString(),
      estDisponible: json['est_disponible'] ?? true,
      dateCreation: json['date_creation'] != null
          ? DateTime.parse(json['date_creation'])
          : DateTime.now(),
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

  Plat copyWith({
    String? id,
    String? restaurantId,
    String? nom,
    String? description,
    double? prix,
    String? categorie,
    bool? estDisponible,
    DateTime? dateCreation,
  }) {
    return Plat(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      prix: prix ?? this.prix,
      categorie: categorie ?? this.categorie,
      estDisponible: estDisponible ?? this.estDisponible,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }
}