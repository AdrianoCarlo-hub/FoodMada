// lib/data/models/user_model.dart
import '../../domain/entities/user_entity.dart';
import 'dart:convert';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.nom,
    required super.telephone,
    required super.role,
    required super.dateCreation,
    super.restaurantId,
  });

  factory UserModel.fromJson(dynamic jsonInput) {
    Map<String, dynamic> json;
    if (jsonInput is String) {
      json = jsonDecode(jsonInput) as Map<String, dynamic>;
    } else if (jsonInput is Map<String, dynamic>) {
      json = jsonInput;
    } else {
      json = jsonDecode(jsonInput.toString()) as Map<String, dynamic>;
    }

    String rawRole = (json['role'] ?? 'CLIENT').toString().trim().toUpperCase();
    if (rawRole.isEmpty) {
      rawRole = 'CLIENT';
    }

    const validRoles = ['CLIENT', 'RESTAURATEUR', 'ADMIN'];
    if (!validRoles.contains(rawRole)) {
      print('⚠️ Rôle inconnu: "$rawRole", utilisation de CLIENT par défaut');
      rawRole = 'CLIENT';
    }

    return UserModel(
      id: (json['id'] ?? json['id_utilisateur'] ?? '').toString(),
      nom: (json['nom'] ?? '').toString(),
      telephone: (json['telephone'] ?? '').toString(),
      role: rawRole,
      restaurantId: json['restaurant_id']?.toString(),
      dateCreation: json['date_creation'] != null
          ? DateTime.tryParse(json['date_creation'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'telephone': telephone,
    'role': role,
    'restaurant_id': restaurantId,
    'date_creation': dateCreation.toIso8601String(),
  };
}
