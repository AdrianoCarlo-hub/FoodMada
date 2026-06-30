// lib/data/models/plat_model.dart

import 'package:madafood_backend/domain/entities/plat.dart';

class PlatModel extends Plat {
  PlatModel({
    required super.id,
    required super.restaurantId,
    required super.nom,
    super.description,
    required super.prix,
    
    required super.estDisponible,
  });

  // 1. Convertir JSON vers Modèle (utilisé par le repository pour la BDD)
  factory PlatModel.fromJson(Map<String, dynamic> json) {
    return PlatModel(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      nom: json['nom'] as String,
      description: json['description'] as String?,
      prix: double.tryParse(json['prix'].toString()) ?? 0.0,
      estDisponible: json['est_disponible'] is bool 
          ? json['est_disponible'] as bool 
          : true,
    );
  }

  // 2. Convertir Modèle vers JSON (utilisé pour les réponses API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'nom': nom,
      'description': description,
      'prix': prix,
      
      'est_disponible': estDisponible,
    };
  }

  // 3. LA MÉTHODE MANQUANTE : Convertir Entité vers Modèle
  // Cela permet à vos routes de transformer les résultats du Repository en JSON
  factory PlatModel.fromEntity(Plat entity) {
    return PlatModel(
      id: entity.id,
      restaurantId: entity.restaurantId,
      nom: entity.nom,
      description: entity.description,
      prix: entity.prix,
      estDisponible: entity.estDisponible,
    );
  }
}