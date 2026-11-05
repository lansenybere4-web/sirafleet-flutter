import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/constants.dart';

class RapportActiviteService {
  RapportActiviteService({required this.token});

  final String token;

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// Liste l'historique des rapports d'activité déjà générés.
  Future<List<Map<String, dynamic>>> lister() async {
    final url = Uri.parse('${AppConstants.baseUrl}/rapports-activites');

    final response = await http.get(url, headers: _headers);
    final decoded = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = decoded['data'];
      return data is List ? List<Map<String, dynamic>>.from(data) : [];
    }

    throw Exception(decoded['message'] ?? 'Impossible de récupérer l\'historique.');
  }

  /// Génère (et enregistre en base) un rapport d'activité pour une période,
  /// en agrégeant automatiquement les rapports de mission des chauffeurs
  /// sur cette période.
  Future<Map<String, dynamic>> generer({
    required String periodeType, // journalier | hebdomadaire | mensuel | annuel
    required DateTime periodeDebut,
    required DateTime periodeFin,
    String? notes,
  }) async {
    final url = Uri.parse('${AppConstants.baseUrl}/rapports-activites');

    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'periode_type': periodeType,
        'periode_debut': fmt(periodeDebut),
        'periode_fin': fmt(periodeFin),
        'notes': notes,
      }),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw Exception(decoded['message'] ?? 'Impossible de générer le rapport.');
  }

  /// Détail d'un rapport d'activité, avec les rapports chauffeurs inclus.
  Future<Map<String, dynamic>> detail(int id) async {
    final url = Uri.parse('${AppConstants.baseUrl}/rapports-activites/$id');

    final response = await http.get(url, headers: _headers);
    final decoded = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw Exception(decoded['message'] ?? 'Rapport introuvable.');
  }
}
