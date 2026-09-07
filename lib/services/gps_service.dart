import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/gps_position_model.dart';

class GpsService {
  static const Duration _timeout = Duration(seconds: 10);

  // ============================================================
  // ENVOYER UNE POSITION GPS
  // ============================================================

  Future<PositionGpsModel> sendPosition({
    required String token,
    required double latitude,
    required double longitude,
    required int camionId,
    int? missionId,
    double vitesse = 0,
    double? altitude,
    double? direction,
    double? precisionGps,
    DateTime? datePosition,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'camion_id': camionId,
        'latitude': latitude,
        'longitude': longitude,
        'vitesse': vitesse,
        'altitude': altitude,
        'direction': direction,
        'precision_gps': precisionGps,
        'date_position':
        (datePosition ?? DateTime.now()).toIso8601String(),
      };

      // On ajoute mission_id uniquement lorsqu'il existe.
      if (missionId != null) {
        body['mission_id'] = missionId;
      }

      final response = await http
          .post(
        Uri.parse(
          '${AppConstants.baseUrl}/gps/position',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      )
          .timeout(_timeout);

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw Exception(
          'Réponse GPS invalide du serveur.',
        );
      }

      if (response.statusCode == 201) {
        if (decoded is! Map ||
            decoded['data'] == null ||
            decoded['data'] is! Map) {
          throw Exception(
            'Les données GPS retournées par le serveur sont invalides.',
          );
        }

        return PositionGpsModel.fromJson(
          Map<String, dynamic>.from(
            decoded['data'],
          ),
        );
      }

      throw Exception(
        _extractErrorMessage(
          decoded,
          'Impossible d\'enregistrer la position GPS.',
        ),
      );
    } on TimeoutException {
      throw Exception(
        'Le serveur GPS ne répond pas.',
      );
    } on http.ClientException catch (e) {
      throw Exception(
        'Erreur de connexion GPS : $e',
      );
    }
  }

  // ============================================================
  // DERNIÈRE POSITION D'UN CAMION
  // ============================================================

  Future<PositionGpsModel> getCurrentPosition({
    required String token,
    required int camionId,
  }) async {
    try {
      final response = await http
          .get(
        Uri.parse(
          '${AppConstants.baseUrl}/gps/camion/$camionId',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      )
          .timeout(_timeout);

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw Exception(
          'Réponse GPS invalide du serveur.',
        );
      }

      if (response.statusCode == 200) {
        if (decoded is! Map ||
            decoded['data'] == null ||
            decoded['data'] is! Map) {
          throw Exception(
            'Aucune position GPS disponible.',
          );
        }

        return PositionGpsModel.fromJson(
          Map<String, dynamic>.from(
            decoded['data'],
          ),
        );
      }

      throw Exception(
        _extractErrorMessage(
          decoded,
          'Aucune position GPS disponible.',
        ),
      );
    } on TimeoutException {
      throw Exception(
        'Le serveur GPS ne répond pas.',
      );
    } on http.ClientException {
      throw Exception(
        'Erreur de connexion GPS.',
      );
    }
  }

  // ============================================================
  // HISTORIQUE GPS D'UN CAMION
  // ============================================================

  Future<List<PositionGpsModel>> getHistory({
    required String token,
    required int camionId,
  }) async {
    try {
      final response = await http
          .get(
        Uri.parse(
          '${AppConstants.baseUrl}/gps/camion/'
              '$camionId/history',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      )
          .timeout(_timeout);

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw Exception(
          'Réponse GPS invalide du serveur.',
        );
      }

      if (response.statusCode == 200) {
        if (decoded is! Map || decoded['data'] is! List) {
          return [];
        }

        final List<dynamic> data = decoded['data'];

        return data
            .whereType<Map>()
            .map(
              (item) => PositionGpsModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
            .toList();
      }

      throw Exception(
        _extractErrorMessage(
          decoded,
          'Impossible de récupérer l\'historique GPS.',
        ),
      );
    } on TimeoutException {
      throw Exception(
        'Le serveur GPS ne répond pas.',
      );
    } on http.ClientException {
      throw Exception(
        'Erreur de connexion GPS.',
      );
    }
  }

  // ============================================================
  // POSITIONS DE TOUTE LA FLOTTE
  // ============================================================

  Future<List<PositionGpsModel>> getFleetPositions({
    required String token,
  }) async {
    try {
      final response = await http
          .get(
        Uri.parse(
          '${AppConstants.baseUrl}/gps/flotte',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      )
          .timeout(_timeout);

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw Exception(
          'Réponse GPS invalide du serveur.',
        );
      }

      if (response.statusCode == 200) {
        if (decoded is! Map || decoded['data'] is! List) {
          return [];
        }

        final List<dynamic> data = decoded['data'];

        return data
            .whereType<Map>()
            .map(
              (item) => PositionGpsModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
            .toList();
      }

      throw Exception(
        _extractErrorMessage(
          decoded,
          'Impossible de récupérer les positions de la flotte.',
        ),
      );
    } on TimeoutException {
      throw Exception(
        'Le serveur GPS ne répond pas.',
      );
    } on http.ClientException {
      throw Exception(
        'Erreur de connexion GPS.',
      );
    }
  }

  // ============================================================
  // EXTRAIRE LE MESSAGE D'ERREUR LARAVEL
  // ============================================================

  String _extractErrorMessage(
      dynamic decoded,
      String defaultMessage,
      ) {
    if (decoded is Map) {
      final dynamic message = decoded['message'];

      if (message is String && message.trim().isNotEmpty) {
        return message;
      }

      final dynamic errors = decoded['errors'];

      if (errors is Map) {
        final List<String> messages = [];

        errors.forEach((key, value) {
          if (value is List) {
            messages.addAll(
              value.map((e) => e.toString()),
            );
          } else {
            messages.add(value.toString());
          }
        });

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }
    }

    return defaultMessage;
  }

  // ============================================================
// ENVOYER UNE ALERTE SOS
// ============================================================

  Future<Map<String, dynamic>> sendSos({
    required String token,
    required int missionId,
    required int camionId,
    required double latitude,
    required double longitude,
    String? description,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'mission_id': missionId,
        'camion_id': camionId,
        'latitude': latitude,
        'longitude': longitude,
        'description': description ??
            'ALERTE SOS déclenchée par le chauffeur.',
      };

      final response = await http
          .post(
        Uri.parse(
          '${AppConstants.baseUrl}/signalements/sos',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      )
          .timeout(_timeout);

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw Exception(
          'Réponse SOS invalide du serveur.',
        );
      }

      if (response.statusCode == 201) {
        if (decoded is! Map) {
          throw Exception(
            'Réponse SOS invalide.',
          );
        }

        return Map<String, dynamic>.from(decoded);
      }

      throw Exception(
        _extractErrorMessage(
          decoded,
          'Impossible d’envoyer l’alerte SOS.',
        ),
      );
    } on TimeoutException {
      throw Exception(
        'Le serveur ne répond pas.',
      );
    } on http.ClientException catch (e) {
      throw Exception(
        'Erreur de connexion : $e',
      );
    }
  }
}