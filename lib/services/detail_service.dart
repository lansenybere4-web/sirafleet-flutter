import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';

class DetailService {
  static const Duration _timeout = Duration(seconds: 15);

  Map<String, String> _headers(String token) => {
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>> _get(String token, String path) async {
    try {
      final response = await http
          .get(Uri.parse('${AppConstants.baseUrl}$path'), headers: _headers(token))
          .timeout(_timeout);

      dynamic body;
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        throw Exception('Réponse invalide du serveur (${response.statusCode}).');
      }

      if (response.statusCode == 200 && body is Map && body['data'] is Map) {
        return Map<String, dynamic>.from(body['data']);
      }

      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }

      if (response.statusCode == 403) {
        throw Exception('Vous n\'êtes pas autorisé à consulter cette fiche.');
      }

      if (response.statusCode == 404) {
        throw Exception('Fiche introuvable.');
      }

      throw Exception(
        body is Map
            ? (body['message']?.toString() ?? 'Erreur ${response.statusCode}.')
            : 'Erreur ${response.statusCode}.',
      );
    } on TimeoutException {
      throw Exception('Le serveur met trop de temps à répondre.');
    }
  }

  /// Fiche complète d'un utilisateur : compte, dossier chauffeur,
  /// statistiques, missions, alertes, messages envoyés.
  Future<Map<String, dynamic>> getUserDetails(String token, String userId) {
    return _get(token, '/users/$userId/details');
  }

  /// Fiche complète d'une mission : trajet, planning, chauffeur, camion
  /// (+ équipements), rapport, alertes.
  Future<Map<String, dynamic>> getMissionDetails(String token, int missionId) {
    return _get(token, '/missions/$missionId');
  }
}
