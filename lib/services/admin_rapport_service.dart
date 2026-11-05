import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/constants.dart';

/// Journal d'activité global + rapports de l'administrateur.
class AdminRapportService {
  AdminRapportService({required this.token});

  final String token;

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _decode(http.Response r, String erreur) {
    final decoded = jsonDecode(r.body);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return Map<String, dynamic>.from(decoded);
    }
    throw Exception(decoded['message'] ?? erreur);
  }

  /// KPIs + répartitions du journal sur une période.
  Future<Map<String, dynamic>> stats(DateTime debut, DateTime fin) async {
    final url = Uri.parse('${AppConstants.baseUrl}/journal-activites/stats')
        .replace(queryParameters: {
      'periode_debut': _fmt(debut),
      'periode_fin': _fmt(fin),
    });
    final r = await http.get(url, headers: _headers);
    return Map<String, dynamic>.from(
        _decode(r, 'Impossible de charger les statistiques.')['data']);
  }

  /// Journal paginé (admin + responsables + chauffeurs).
  Future<({List<Map<String, dynamic>> items, int lastPage})> journal({
    int page = 1,
    String? role,
    String? module,
    String? statut,
    String? search,
    DateTime? debut,
    DateTime? fin,
  }) async {
    final params = <String, String>{'page': '$page', 'per_page': '30'};
    if (role != null) params['role'] = role;
    if (module != null) params['module'] = module;
    if (statut != null) params['statut'] = statut;
    if (search != null && search.trim().isNotEmpty) params['search'] = search.trim();
    if (debut != null && fin != null) {
      params['date_debut'] = _fmt(debut);
      params['date_fin'] = _fmt(fin);
    }

    final url = Uri.parse('${AppConstants.baseUrl}/journal-activites')
        .replace(queryParameters: params);
    final r = await http.get(url, headers: _headers);
    final body = _decode(r, 'Impossible de charger le journal.');

    return (
    items: List<Map<String, dynamic>>.from(body['data'] ?? []),
    lastPage: (body['meta']?['last_page'] ?? 1) as int,
    );
  }

  Future<List<String>> modules() async {
    final r = await http.get(
        Uri.parse('${AppConstants.baseUrl}/journal-activites/modules'),
        headers: _headers);
    final body = _decode(r, 'Modules indisponibles.');
    return List<String>.from(body['data'] ?? []);
  }

  /// Historique des rapports générés par l'admin.
  Future<List<Map<String, dynamic>>> lister() async {
    final r = await http.get(
        Uri.parse('${AppConstants.baseUrl}/rapports-admin'),
        headers: _headers);
    return List<Map<String, dynamic>>.from(
        _decode(r, 'Impossible de récupérer l\'historique.')['data'] ?? []);
  }

  Future<Map<String, dynamic>> generer({
    required String periodeType,
    required DateTime debut,
    required DateTime fin,
    String? notes,
  }) async {
    final r = await http.post(
      Uri.parse('${AppConstants.baseUrl}/rapports-admin'),
      headers: _headers,
      body: jsonEncode({
        'periode_type': periodeType,
        'periode_debut': _fmt(debut),
        'periode_fin': _fmt(fin),
        'notes': notes,
      }),
    );
    return _decode(r, 'Impossible de générer le rapport.');
  }

  Future<Map<String, dynamic>> detail(int id) async {
    final r = await http.get(
        Uri.parse('${AppConstants.baseUrl}/rapports-admin/$id'),
        headers: _headers);
    return _decode(r, 'Rapport introuvable.');
  }
}
