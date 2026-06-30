// lib/core/security/jwt_service_impl.dart
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:madafood_backend/domain/services/token_service.dart';

class JwtServiceImpl implements TokenService {
  // 🔑 CLÉ SECRÈTE - En production, utilisez une variable d'environnement
  static const String _secretKey = 'madafood_super_secret_key_2024_1234567890';

  @override
  String generateToken(String userId, String role) {
    try {
      // Créer le payload du JWT
      final jwt = JWT({
        'sub': userId,      // Subject = ID de l'utilisateur
        'role': role,       // Rôle de l'utilisateur
        'iat': DateTime.now().millisecondsSinceEpoch, // Issued at
      });
      
      // Signer le JWT avec une clé secrète
      final token = jwt.sign(
        SecretKey(_secretKey),
        expiresIn: const Duration(days: 7), // Expire dans 7 jours
      );
      
      print('✅ JWT généré pour $userId avec rôle $role');
      print('🔑 Token: ${token.substring(0, 30)}...');
      
      return token;
    } catch (e) {
      print('❌ Erreur génération JWT: $e');
      return '';
    }
  }

  @override
  Map<String, dynamic>? verifyToken(String token) {
    try {
      print('🔍 Vérification du token...');
      
      // Vérifier et décoder le JWT
      final jwt = JWT.verify(token, SecretKey(_secretKey));
      
      print('✅ Token valide');
      print('📦 Payload: ${jwt.payload}');
      
      return jwt.payload as Map<String, dynamic>;
    } on JWTExpiredException {
      print('❌ Token expiré');
      return null;
    } on JWTInvalidException {
      print('❌ Token invalide');
      return null;
    } catch (e) {
      print('❌ Erreur vérification token: $e');
      return null;
    }
  }
}