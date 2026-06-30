// lib/core/helpers/decoder_helper.dart
import 'dart:convert';
import 'package:postgres/postgres.dart';

/// ✅ Fonction utilitaire pour décoder les UndecodedBytes
/// Utilisée dans toutes les routes pour décoder les enums PostgreSQL
String decodeStatus(dynamic value) {
  if (value == null) return '';
  if (value is String) return value.trim();
  if (value is UndecodedBytes) {
    try {
      return value.asString.trim();
    } catch (_) {
      try {
        return utf8.decode(value.bytes, allowMalformed: true).trim();
      } catch (_) {
        return value.toString().trim();
      }
    }
  }
  if (value is List<int>) {
    try {
      return utf8.decode(value, allowMalformed: true).trim();
    } catch (_) {
      return String.fromCharCodes(value);
    }
  }
  return value.toString().trim();
}

/// ✅ Version spéciale pour décoder le rôle
String decodeRole(dynamic value) {
  final decoded = decodeStatus(value);
  return decoded.isEmpty ? 'CLIENT' : decoded.toUpperCase();
}

/// ✅ Version pour décoder le mot de passe
String decodePassword(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is UndecodedBytes) {
    try {
      return value.asString;
    } catch (_) {
      try {
        return utf8.decode(value.bytes, allowMalformed: true);
      } catch (_) {
        return value.toString();
      }
    }
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