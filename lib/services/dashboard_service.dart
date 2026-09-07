import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';



class DashboardService {
  static Future<Map<String, dynamic>> getResponsableDashboard(
      String token,
      ) async {
    final response = await http.get(
      Uri.parse(
        '${AppConstants.baseUrl}/dashboard/responsable',
      ),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 401) {
      throw Exception('SESSION_EXPIREE');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erreur serveur (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Réponse serveur invalide.');
    }

    if (decoded['success'] != true) {
      throw Exception(
        decoded['message']?.toString() ??
            'Impossible de récupérer le dashboard.',
      );
    }

    final data = decoded['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Données du dashboard invalides.');
    }

    return Map<String, dynamic>.from(data);
  }
}