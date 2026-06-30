// lib/data/models/user_model.dart
import 'dart:convert';
import 'package:postgres/postgres.dart'; 
import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required super.id,
    required super.nom,
    required super.telephone,
    required super.motDePasse,
    required super.role,
    required super.dateCreation,
    // ✅ Ajout du champ restaurantId ici (assurez-vous qu'il est présent dans votre entité User)
    required super.restaurantId, 
  });

  /// Méthode de sécurité centralisée pour le décodage
  static String _safeDecode(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    
    if (value is UndecodedBytes) {
      return value.asString; 
    }

    if (value is List<int>) {
      try {
        return utf8.decode(value, allowMalformed: true);
      } catch (_) {
        return String.fromCharCodes(value);
      }
    }
    return value.toString();
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    print('🔍 [UserModel] Début décodage pour: ${json['nom']}');
    
    // ✅ Récupération du restaurant_id avec sécurité
    final rawRestaurantId = json['restaurant_id'];
    final String? decodedRestaurantId = (rawRestaurantId != null && rawRestaurantId.toString().isNotEmpty) 
        ? _safeDecode(rawRestaurantId) 
        : null;

    final user = UserModel(
      id: _safeDecode(json['id']),
      nom: _safeDecode(json['nom']),
      telephone: _safeDecode(json['telephone']),
      motDePasse: _safeDecode(json['mot_de_passe']),
      role: _safeDecode(json['role']),
      restaurantId: decodedRestaurantId, // ✅ Mapping du restaurant_id
      dateCreation: json['date_creation'] is DateTime 
          ? json['date_creation'] as DateTime 
          : DateTime.tryParse(json['date_creation']?.toString() ?? '') ?? DateTime.now(),
    );
    
    print('🔍 [UserModel] Utilisateur hydraté: ${user.nom}, Resto: ${user.restaurantId}');
    return user;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'telephone': telephone,
      'mot_de_passe': motDePasse,
      'role': role,
      'restaurant_id': restaurantId, // ✅ Export JSON
      'date_creation': dateCreation.toIso8601String(),
    };
  }
}