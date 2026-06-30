// lib/data/repositories/auth_repository_impl.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/network/dio_client.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final DioClient _dioClient;
  final _storage = const FlutterSecureStorage();

  AuthRepositoryImpl(this._dioClient);

  @override
  Future<UserModel> login(String telephone, String password) async {
    try {
      print('🔑 Tentative de login pour: $telephone');
      
      final response = await _dioClient.dio.post<dynamic>(
        '/api/auth/login',
        data: {
          'telephone': telephone,
          'mot_de_passe': password,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print('📡 Réponse login: ${response.statusCode}');

      final authData = _extractAuthData(response.data);
      print('🔑 Token reçu: ${authData.token.substring(0, 20)}...');
      
      await _storage.write(key: 'jwt_token', value: authData.token);
      
      // ✅ Vérifier que le token est bien sauvegardé
      final savedToken = await _storage.read(key: 'jwt_token');
      print('✅ Token sauvegardé: ${savedToken?.substring(0, 20)}...');

      return UserModel.fromJson(authData.userJson);
    } on DioException catch (e) {
      print('❌ DioException login: ${e.response?.statusCode}');
      throw Exception(_messageFromDio(e, fallback: 'Echec de la connexion'));
    } catch (e) {
      print('❌ Erreur login: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<UserModel> register({
    required String nom,
    required String telephone,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _dioClient.dio.post<dynamic>(
        '/api/auth/register',
        data: {
          'nom': nom,
          'telephone': telephone,
          'mot_de_passe': password,
          'role': role,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final authData = _extractAuthData(response.data);
      await _storage.write(key: 'jwt_token', value: authData.token);

      return UserModel.fromJson(authData.userJson);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, fallback: "Echec de l'inscription"));
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ✅ AJOUTER CETTE MÉTHODE POUR VÉRIFIER LE TOKEN
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // ✅ AJOUTER CETTE MÉTHODE POUR SE DÉCONNECTER
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    print('🔴 Token supprimé');
  }
}

_AuthData _extractAuthData(dynamic responseData) {
  final responseBody = _asMap(responseData);
  final data = _asMap(responseBody['data'] ?? responseBody);
  final token = data['token']?.toString();
  final userJson = _asMap(data['user']);

  if (token == null || token.isEmpty) {
    throw Exception('Token manquant dans la reponse du serveur.');
  }

  return _AuthData(token: token, userJson: userJson);
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value == null) return {};
  if (value is String) {
    try {
      final decoded = jsonDecode(value);
      return _asMap(decoded);
    } catch (_) {
      throw Exception('Impossible de décoder la chaîne JSON.');
    }
  }
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  try {
    final decoded = jsonDecode(value.toString());
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {}
  throw Exception('Format de reponse API invalide (attendu: Map).');
}

String _messageFromDio(DioException e, {required String fallback}) {
  final data = e.response?.data;
  if (data is Map) {
    final message = data['erreur'] ?? data['error'] ?? data['message'];
    if (message != null) return message.toString();
  } else if (data is String) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map) {
        final message = decoded['erreur'] ?? decoded['error'] ?? decoded['message'];
        if (message != null) return message.toString();
      }
    } catch (_) {}
  }
  return e.message ?? fallback;
}

class _AuthData {
  const _AuthData({
    required this.token,
    required this.userJson,
  });
  final String token;
  final Map<String, dynamic> userJson;
}