// lib/core/network/dio_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

class DioClient {
  late Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  DioClient() {
    String baseUrl;
    
    //  Configuration selon l'environnement
    if (kIsWeb) {
      // Pour le web (localhost)
      baseUrl = 'http://localhost:8080';
    } else if (Platform.isAndroid) {
      //  Pour Android (téléphone physique)
      // Utilise l'IP de ton ordinateur sur le même réseau Wi-Fi
      baseUrl = 'http://192.168.0.101:8080';
    } else if (Platform.isIOS) {
      // Pour iOS (simulateur ou physique)
      // Sur simulateur: localhost, sur physique: IP de l'ordinateur
      baseUrl = 'http://192.168.0.101:8080';
    } else {
      // Fallback
      baseUrl = 'http://192.168.0.101:8080';
    }

    print('📡 Base URL: $baseUrl');
    print('📱 Platform: ${Platform.isAndroid ? "Android" : Platform.isIOS ? "iOS" : "Autre"}');
    print('🌐 Web: $kIsWeb');

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await _storage.read(key: 'jwt_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            print('🔑 Token added to: ${options.path}');
          } else {
            print('⚠️ No token for: ${options.path}');
          }
        } catch (e) {
          print('❌ Token error: $e');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ Response: ${response.statusCode} - ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (error, handler) async {
        print('❌ Error: ${error.response?.statusCode} - ${error.requestOptions.path}');
        print('❌ Error message: ${error.message}');
        
        if (error.response?.statusCode == 401) {
          await _storage.delete(key: 'jwt_token');
          print('🔴 Token removed (401)');
        }
        
        // ✅ Gérer les erreurs de connexion
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.connectionError) {
          print('⚠️ Connection error - Vérifie que le serveur est en cours d\'exécution');
          print('⚠️ Assure-toi que le téléphone est sur le même réseau Wi-Fi que l\'ordinateur');
          print('⚠️ Vérifie que le firewall n\'est pas bloquant le port 8080');
        }
        
        return handler.next(error);
      },
    ));
  }
}