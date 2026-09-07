import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/parametre.dart';

class ParametreService {
  final String baseUrl = AppConstants.baseUrl;

  // ============================================================
  // HEADERS
  // ============================================================

  Map<String, String> _headers({String? token}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    return headers;
  }

  // ============================================================
  // RÉCUPÉRATION
  // ============================================================

  Future<Parametre> getParametres({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/parametres'),
        headers: _headers(token: token),
      );

      final decoded = _decodeResponse(response);

      if (response.statusCode != 200) {
        throw Exception(_extractErrorFromDecoded(decoded));
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ??
              'Impossible de récupérer les paramètres.',
        );
      }

      if (decoded['data'] is! Map) {
        throw Exception('Données des paramètres invalides.');
      }

      return Parametre.fromJson(Map<String, dynamic>.from(decoded['data']));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur de connexion au serveur.');
    }
  }

  // ============================================================
  // MISE À JOUR
  // ============================================================

  Future<Parametre> updateParametres(
      Map<String, dynamic> data, {
        String? token,
      }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/parametres'),
        headers: _headers(token: token),
        body: jsonEncode(data),
      );

      final decoded = _decodeResponse(response);

      if (response.statusCode != 200) {
        throw Exception(_extractErrorFromDecoded(decoded));
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ??
              'Impossible d\u2019enregistrer les paramètres.',
        );
      }

      if (decoded['data'] is! Map) {
        throw Exception('Données des paramètres invalides.');
      }

      return Parametre.fromJson(Map<String, dynamic>.from(decoded['data']));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur de connexion au serveur.');
    }
  }

  // ============================================================
  // RÉINITIALISATION
  // ============================================================

  Future<Parametre> resetParametres({String? token}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/parametres/reset'),
        headers: _headers(token: token),
      );

      final decoded = _decodeResponse(response);

      if (response.statusCode != 200) {
        throw Exception(_extractErrorFromDecoded(decoded));
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ??
              'Impossible de réinitialiser les paramètres.',
        );
      }

      if (decoded['data'] is! Map) {
        throw Exception('Données des paramètres invalides.');
      }

      return Parametre.fromJson(Map<String, dynamic>.from(decoded['data']));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur de connexion au serveur.');
    }
  }

  // ============================================================
  // DECODAGE / ERREUR (identique à CamionService)
  // ============================================================

  Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return {'message': 'Réponse invalide du serveur.'};
    } catch (_) {
      return {
        'message': 'Réponse invalide du serveur (${response.statusCode}).',
      };
    }
  }

  String _extractErrorFromDecoded(Map<String, dynamic> decoded) {
    if (decoded['message'] != null) {
      final message = decoded['message'].toString();
      if (message.trim().isNotEmpty) return message;
    }

    if (decoded['errors'] is Map) {
      final errors = Map<String, dynamic>.from(decoded['errors']);
      final messages = <String>[];

      for (final value in errors.values) {
        if (value is List) {
          messages.addAll(value.map((e) => e.toString()));
        } else {
          messages.add(value.toString());
        }
      }

      if (messages.isNotEmpty) return messages.join('\n');
    }

    return 'Une erreur est survenue.';
  }
}