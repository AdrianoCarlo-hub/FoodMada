// lib/domain/entities/user_entity.dart
class UserEntity {
  final String id;
  final String nom;
  final String telephone;
  final String role;
  final DateTime dateCreation;
  final String? restaurantId;

  const UserEntity({
    required this.id,
    required this.nom,
    required this.telephone,
    required this.role,
    required this.dateCreation,
    this.restaurantId,
  });
}
