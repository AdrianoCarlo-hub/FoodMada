// lib/domain/entities/restaurant.dart
class Restaurant {
  final String id;
  final String nom;
  final String description;
  final String adresse;
  final String? imageUrl;
  final String? telephone;
  final String? email;
  final String? categorie;
  final double? noteMoyenne;
  final String proprietaireId;
  final bool estActif;
  final DateTime dateCreation;
  final DateTime? dateModification;

  Restaurant({
    required this.id,
    required this.nom,
    required this.description,
    required this.adresse,
    this.imageUrl,
    this.telephone,
    this.email,
    this.categorie,
    this.noteMoyenne,
    required this.proprietaireId,
    this.estActif = true,
    required this.dateCreation,
    this.dateModification,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id']?.toString() ?? '',
      nom: json['nom'] ?? '',
      description: json['description'] ?? '',
      adresse: json['adresse'] ?? '',
      imageUrl: json['image_url'],
      telephone: json['telephone'],
      email: json['email'],
      categorie: json['categorie'],
      noteMoyenne: json['note_moyenne']?.toDouble(),
      proprietaireId: json['proprietaire_id']?.toString() ?? '',
      estActif: json['est_actif'] ?? true,
      dateCreation: json['date_creation'] != null
          ? DateTime.parse(json['date_creation'])
          : DateTime.now(),
      dateModification: json['date_modification'] != null
          ? DateTime.parse(json['date_modification'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'adresse': adresse,
      'image_url': imageUrl,
      'telephone': telephone,
      'email': email,
      'categorie': categorie,
      'note_moyenne': noteMoyenne,
      'proprietaire_id': proprietaireId,
      'est_actif': estActif,
      'date_creation': dateCreation.toIso8601String(),
      'date_modification': dateModification?.toIso8601String(),
    };
  }

  Restaurant copyWith({
    String? id,
    String? nom,
    String? description,
    String? adresse,
    String? imageUrl,
    String? telephone,
    String? email,
    String? categorie,
    double? noteMoyenne,
    String? proprietaireId,
    bool? estActif,
    DateTime? dateCreation,
    DateTime? dateModification,
  }) {
    return Restaurant(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      adresse: adresse ?? this.adresse,
      imageUrl: imageUrl ?? this.imageUrl,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      categorie: categorie ?? this.categorie,
      noteMoyenne: noteMoyenne ?? this.noteMoyenne,
      proprietaireId: proprietaireId ?? this.proprietaireId,
      estActif: estActif ?? this.estActif,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
    );
  }
}
