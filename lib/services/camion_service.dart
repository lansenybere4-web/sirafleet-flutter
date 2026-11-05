import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/camion_details_model.dart';
import '../models/camion_model.dart';

class CamionService {
  final String baseUrl = AppConstants.baseUrl;

  // ============================================================
  // HEADERS
  // ============================================================

  Map<String, String> _headers({
    String? token,
  }) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null &&
        token.trim().isNotEmpty) {
      headers['Authorization'] =
      'Bearer ${token.trim()}';
    }

    return headers;
  }

  // ============================================================
  // LISTE DES CAMIONS
  // ============================================================

  Future<List<Camion>> getCamions({
    String? token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/camions'),
        headers: _headers(
          token: token,
        ),
      );

      final decoded =
      _decodeResponse(response);

      if (response.statusCode != 200) {
        throw Exception(
          _extractErrorFromDecoded(
            decoded,
          ),
        );
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ??
              'Impossible de récupérer les camions.',
        );
      }

      final data = decoded['data'];

      if (data is! List) {
        return [];
      }

      return data
          .whereType<Map>()
          .map(
            (json) => Camion.fromJson(
          Map<String, dynamic>.from(
            json,
          ),
        ),
      )
          .toList();
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Erreur de connexion au serveur.',
      );
    }
  }

  // ============================================================
  // DETAILS
  // ============================================================

  Future<Camion> getCamion(
      int id, {
        String? token,
      }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/camions/$id'),
        headers: _headers(
          token: token,
        ),
      );

      final decoded =
      _decodeResponse(response);

      if (response.statusCode != 200) {
        throw Exception(
          _extractErrorFromDecoded(
            decoded,
          ),
        );
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ??
              'Camion introuvable.',
        );
      }

      if (decoded['data'] is! Map) {
        throw Exception(
          'Données du camion invalides.',
        );
      }

      return Camion.fromJson(
        Map<String, dynamic>.from(
          decoded['data'],
        ),
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Erreur de connexion au serveur.',
      );
    }
  }

  // ============================================================
  // CREATION
  // ============================================================

  Future<Camion> createCamion({
    required String matricule,
    String? marque,
    String? modele,
    int? annee,
    double kilometrage = 0,
    String statut = 'disponible',
    int? anneeAcquisition,
    DateTime? dateMiseEnService,
    String? token,
  }) async {
    try {
      final body = <String, dynamic>{
        'matricule': matricule.trim(),
        'kilometrage': kilometrage,
        'statut': statut,
      };

      if (marque != null &&
          marque.trim().isNotEmpty) {
        body['marque'] = marque.trim();
      }

      if (modele != null &&
          modele.trim().isNotEmpty) {
        body['modele'] = modele.trim();
      }

      if (annee != null) {
        body['annee'] = annee;
      }
      // dans le body, à côté de 'annee'
      if (anneeAcquisition != null) {
        body['annee_acquisition'] = anneeAcquisition;
      }
      if (dateMiseEnService != null) {
        body['date_mise_en_service'] =
            dateMiseEnService.toIso8601String().substring(0, 10);
      }

      final response = await http.post(
        Uri.parse('$baseUrl/camions'),
        headers: _headers(
          token: token,
        ),
        body: jsonEncode(body),
      );

      final decoded =
      _decodeResponse(response);

      if (response.statusCode != 201) {
        throw Exception(
          _extractErrorFromDecoded(
            decoded,
          ),
        );
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ??
              'Impossible de créer le camion.',
        );
      }

      if (decoded['data'] is! Map) {
        throw Exception(
          'Données du camion invalides.',
        );
      }

      return Camion.fromJson(
        Map<String, dynamic>.from(
          decoded['data'],
        ),
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Erreur de connexion au serveur.',
      );
    }
  }

  // ============================================================
  // MODIFICATION
  // ============================================================

  Future<Camion> updateCamion({
    required int id,
    String? matricule,
    String? marque,
    String? modele,
    int? annee,
    double? kilometrage,
    String? statut,
    int? anneeAcquisition,
    DateTime? dateMiseEnService,
    String? token,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (matricule != null) {
        body['matricule'] =
            matricule.trim();
      }

      if (marque != null) {
        body['marque'] =
        marque.trim().isEmpty
            ? null
            : marque.trim();
      }

      if (modele != null) {
        body['modele'] =
        modele.trim().isEmpty
            ? null
            : modele.trim();
      }

      if (annee != null) {
        body['annee'] = annee;
      }

      // dans le body, à côté de 'annee'
      if (anneeAcquisition != null) {
        body['annee_acquisition'] = anneeAcquisition;
      }
      if (dateMiseEnService != null) {
        body['date_mise_en_service'] =
            dateMiseEnService.toIso8601String().substring(0, 10);
      }

      if (kilometrage != null) {
        body['kilometrage'] =
            kilometrage;
      }

      if (statut != null) {
        body['statut'] = statut;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/camions/$id'),
        headers: _headers(
          token: token,
        ),
        body: jsonEncode(body),
      );

      final decoded =
      _decodeResponse(response);

      if (response.statusCode != 200) {
        throw Exception(
          _extractErrorFromDecoded(
            decoded,
          ),
        );
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ??
              'Impossible de modifier le camion.',
        );
      }

      if (decoded['data'] is! Map) {
        throw Exception(
          'Données du camion invalides.',
        );
      }

      return Camion.fromJson(
        Map<String, dynamic>.from(
          decoded['data'],
        ),
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Erreur de connexion au serveur.',
      );
    }
  }

  // ============================================================
  // SUPPRESSION
  // ============================================================

  Future<void> deleteCamion(
      int id, {
        String? token,
      }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/camions/$id'),
        headers: _headers(
          token: token,
        ),
      );

      final decoded =
      _decodeResponse(response);

      if (response.statusCode != 200) {
        throw Exception(
          _extractErrorFromDecoded(
            decoded,
          ),
        );
      }

      if (decoded.isNotEmpty &&
          decoded['success'] != null &&
          decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ??
              'Impossible de supprimer le camion.',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Erreur de connexion au serveur.',
      );
    }
  }




  Future<CamionDetails> getCamionDetails(int id, {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/camions/$id/details'),
        headers: _headers(token: token),
      );

      final decoded = _decodeResponse(response);

      if (response.statusCode != 200) {
        throw Exception(_extractErrorFromDecoded(decoded));
      }

      if (decoded['data'] is! Map) {
        throw Exception('Données du camion invalides.');
      }

      return CamionDetails.fromJson(
        Map<String, dynamic>.from(decoded['data']),
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur de connexion au serveur.');
    }
  }

  // ============================================================
  // DECODAGE
  // ============================================================

  Map<String, dynamic> _decodeResponse(
      http.Response response,
      ) {
    try {
      final decoded =
      jsonDecode(response.body);

      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded,
        );
      }

      return {
        'message':
        'Réponse invalide du serveur.',
      };
    } catch (_) {
      return {
        'message':
        'Réponse invalide du serveur (${response.statusCode}).',
      };
    }
  }

  // ============================================================
  // ERREUR
  // ============================================================

  String _extractErrorFromDecoded(
      Map<String, dynamic> decoded,
      ) {
    if (decoded['message'] != null) {
      final message =
      decoded['message'].toString();

      if (message.trim().isNotEmpty) {
        return message;
      }
    }

    if (decoded['errors'] is Map) {
      final errors =
      Map<String, dynamic>.from(
        decoded['errors'],
      );

      final messages = <String>[];

      for (final value in errors.values) {
        if (value is List) {
          messages.addAll(
            value.map(
                  (e) => e.toString(),
            ),
          );
        } else {
          messages.add(
            value.toString(),
          );
        }
      }

      if (messages.isNotEmpty) {
        return messages.join('\n');
      }
    }

    return 'Une erreur est survenue.';
  }
}