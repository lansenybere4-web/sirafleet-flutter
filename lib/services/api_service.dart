import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/constants.dart';

class ApiService {
  static const Duration _timeout = Duration(seconds: 10);

  // ============================================================
  // CONNEXION
  // ============================================================

  Future<Map<String, dynamic>> login(
      String email,
      String password,
      ) async {
    try {
      final response = await http
          .post(
        Uri.parse('${AppConstants.baseUrl}/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      )
          .timeout(_timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      }

      throw Exception(
        data['message'] ?? 'Email ou mot de passe incorrect.',
      );
    } on TimeoutException {
      throw Exception(
        'Le serveur ne répond pas. Vérifie que Laravel tourne '
            '(php artisan serve --host=0.0.0.0) et que l\'adresse dans '
            'AppConstants.baseUrl est correcte.',
      );
    } on http.ClientException catch (e) {
      throw Exception('Impossible de contacter le serveur : $e');
    } on FormatException {
      throw Exception('Réponse du serveur invalide (pas du JSON).');
    }
  }

  // ============================================================
  // UTILISATEUR CONNECTÉ
  // ============================================================

  Future<Map<String, dynamic>> getUser(String token) async {
    try {
      final response = await http
          .get(
        Uri.parse('${AppConstants.baseUrl}/me'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      )
          .timeout(_timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      }

      throw Exception(
        data['message'] ?? 'Session expirée.',
      );
    } on TimeoutException {
      throw Exception('Le serveur ne répond pas.');
    }
  }

  // ============================================================
  // DÉCONNEXION
  // ============================================================

  Future<void> logout(String token) async {
    final response = await http
        .post(
      Uri.parse('${AppConstants.baseUrl}/logout'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la déconnexion.');
    }
  }
}