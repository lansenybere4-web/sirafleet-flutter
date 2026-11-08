import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../core/constants.dart';
import '../models/trajet_reel_model.dart';

class TrajetService {
  // Le map-matching peut traiter plusieurs lots côté serveur : timeout large.
  static const Duration _timeout = Duration(seconds: 45);

  Map<String, String> _headers(String token) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ============================================================
  // TRAJET RÉEL (positions GPS recalées sur les routes)
  // ============================================================

  Future<TrajetReel> getTrajetReel(
      int missionId, {
        required String token,
      }) async {
    final decoded = await _call(
      http.get(
        Uri.parse('${AppConstants.baseUrl}/missions/$missionId/trajet-reel'),
        headers: _headers(token),
      ),
      'Impossible de récupérer le trajet réel.',
    );

    final data = decoded['data'];
    if (data is! Map) {
      throw Exception('Données de trajet invalides.');
    }

    return TrajetReel.fromJson(Map<String, dynamic>.from(data));
  }

  // ============================================================
  // RECALCUL DE L'ITINÉRAIRE PRÉVU DEPUIS LA POSITION ACTUELLE
  // ============================================================

  Future<List<LatLng>> recalculerItineraire(
      int missionId, {
        required String token,
        required double latitude,
        required double longitude,
      }) async {
    final decoded = await _call(
      http.post(
        Uri.parse(
          '${AppConstants.baseUrl}/missions/$missionId/recalculer-itineraire',
        ),
        headers: _headers(token),
        body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
      ),
      "Impossible de recalculer l'itinéraire.",
    );

    final data = decoded['data'];
    final raw = data is Map ? data['itineraire'] : null;

    if (raw is! List) {
      throw Exception('Itinéraire invalide reçu du serveur.');
    }

    final points = <LatLng>[];
    for (final item in raw) {
      if (item is Map && item['lat'] != null && item['lng'] != null) {
        points.add(LatLng(
          (item['lat'] as num).toDouble(),
          (item['lng'] as num).toDouble(),
        ));
      }
    }

    if (points.length < 2) {
      throw Exception('Itinéraire vide reçu du serveur.');
    }

    return points;
  }

  // ============================================================
  // OUTILS
  // ============================================================

  Future<Map<String, dynamic>> _call(
      Future<http.Response> request,
      String defaultError,
      ) async {
    try {
      final response = await request.timeout(_timeout);

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw Exception('Réponse invalide du serveur.');
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      throw Exception(_extractError(decoded, defaultError));
    } on TimeoutException {
      throw Exception('Le serveur ne répond pas.');
    } on http.ClientException catch (e) {
      throw Exception('Erreur de connexion : $e');
    }
  }

  String _extractError(dynamic decoded, String fallback) {
    if (decoded is Map) {
      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) return message;

      final errors = decoded['errors'];
      if (errors is Map) {
        final messages = <String>[];
        errors.forEach((_, v) {
          if (v is List) {
            messages.addAll(v.map((e) => e.toString()));
          } else {
            messages.add(v.toString());
          }
        });
        if (messages.isNotEmpty) return messages.join('\n');
      }
    }
    return fallback;
  }
}
