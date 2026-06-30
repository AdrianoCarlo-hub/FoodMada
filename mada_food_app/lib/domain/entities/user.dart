// lib/domain/entities/user.dart
class User {
  final String id;
  final String nom;
  final String telephone;
  final String role;
  final String? restaurantId;  // ✅ AJOUTER
  final DateTime dateCreation;

  const User({
    required this.id,
    required this.nom,
    required this.telephone,
    required this.role,
    this.restaurantId,
    required this.dateCreation,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      nom: json['nom'] ?? '',
      telephone: json['telephone'] ?? '',
      role: json['role']?.toString() ?? 'CLIENT',
      restaurantId: json['restaurant_id']?.toString(),  // ✅ AJOUTER
      dateCreation: json['date_creation'] != null
          ? DateTime.parse(json['date_creation'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'telephone': telephone,
      'role': role,
      'restaurant_id': restaurantId,  // ✅ AJOUTER
      'date_creation': dateCreation.toIso8601String(),
    };
  }
}
