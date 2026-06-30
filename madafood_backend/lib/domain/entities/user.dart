// lib/domain/entities/user.dart
class User {
  final String id;
  final String nom;
  final String telephone;
  final String role;
  final String? restaurantId;
  final DateTime dateCreation;
  final String? motDePasse;  // ✅ Optionnel

  const User({
    required this.id,
    required this.nom,
    required this.telephone,
    required this.role,
    this.restaurantId,
    required this.dateCreation,
    this.motDePasse,  // ✅ Optionnel
  });

  /// ✅ Convertir JSON en User avec gestion des erreurs
  factory User.fromJson(Map<String, dynamic> json) {
    // ✅ Sécuriser la récupération des données
    final String rawRole = (json['role']?.toString() ?? 'CLIENT').toUpperCase();
    
    // ✅ Valider le rôle
    const validRoles = ['CLIENT', 'RESTAURATEUR', 'ADMIN'];
    final String finalRole = validRoles.contains(rawRole) ? rawRole : 'CLIENT';

    // ✅ Parser la date avec gestion d'erreur
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return User(
      id: json['id']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      telephone: json['telephone']?.toString() ?? '',
      role: finalRole,
      restaurantId: json['restaurant_id']?.toString(),
      dateCreation: parseDate(json['date_creation']),
      motDePasse: json['mot_de_passe']?.toString(),
    );
  }

  /// ✅ Convertir User en JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'id': id,
      'nom': nom,
      'telephone': telephone,
      'role': role,
      'date_creation': dateCreation.toIso8601String(),
    };
    
    // ✅ Ajouter restaurant_id seulement s'il n'est pas null
    if (restaurantId != null && restaurantId!.isNotEmpty) {
      json['restaurant_id'] = restaurantId;
    }
    
    // ✅ Ajouter mot_de_passe seulement s'il est présent
    if (motDePasse != null && motDePasse!.isNotEmpty) {
      json['mot_de_passe'] = motDePasse;
    }
    
    return json;
  }

  /// ✅ Méthode copyWith pour faciliter les mises à jour
  User copyWith({
    String? id,
    String? nom,
    String? telephone,
    String? role,
    String? restaurantId,
    DateTime? dateCreation,
    String? motDePasse,
  }) {
    return User(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      telephone: telephone ?? this.telephone,
      role: role ?? this.role,
      restaurantId: restaurantId ?? this.restaurantId,
      dateCreation: dateCreation ?? this.dateCreation,
      motDePasse: motDePasse ?? this.motDePasse,
    );
  }

  /// ✅ Méthode pour obtenir le rôle affichable
  String get displayRole {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Administrateur';
      case 'RESTAURATEUR':
        return 'Restaurateur';
      case 'CLIENT':
        return 'Client';
      default:
        return role;
    }
  }

  /// ✅ Vérifier si l'utilisateur est un administrateur
  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  /// ✅ Vérifier si l'utilisateur est un restaurateur
  bool get isRestaurateur => role.toUpperCase() == 'RESTAURATEUR';

  /// ✅ Vérifier si l'utilisateur est un client
  bool get isClient => role.toUpperCase() == 'CLIENT';

  /// ✅ Vérifier si l'utilisateur a un restaurant associé
  bool get hasRestaurant => restaurantId != null && restaurantId!.isNotEmpty;

  @override
  String toString() {
    return 'User{id: $id, nom: $nom, role: $role, restaurantId: $restaurantId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}