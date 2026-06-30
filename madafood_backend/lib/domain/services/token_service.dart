abstract class TokenService {
  /// Génère un token contenant l'ID de l'utilisateur et son rôle.
  String generateToken(String userId, String role);

  /// Vérifie la validité du token et retourne les données (payload) s'il est valide.
  Map<String, dynamic>? verifyToken(String token);
}