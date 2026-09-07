import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/mission.dart';

class MissionService {
  static const Duration _timeout = Duration(seconds: 15);

  String get _baseUrl => AppConstants.baseUrl;

  // ============================================================
  // HEADERS
  // ============================================================

  Map<String, String> _headers(String? token) {
    final Map<String, String> headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    return headers;
  }

  // ============================================================
  // LISTE DES MISSIONS
  // ============================================================

  Future<List<Mission>> getMissions({
    String? token,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/missions');

    try {
      final response = await http
          .get(
        uri,
        headers: _headers(token),
      )
          .timeout(_timeout);

      _checkResponse(response);

      final dynamic decoded = _decodeJson(response);

      final List<dynamic> data = _extractMissionList(decoded);

      return data
          .whereType<Map>()
          .map(
            (item) => Mission.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
          .toList();
    } on TimeoutException {
      throw Exception(
        'Le serveur met trop de temps à répondre.',
      );
    } on FormatException {
      throw Exception(
        'Réponse invalide du serveur.',
      );
    } catch (e) {
      throw Exception(_cleanError(e));
    }
  }

  // ============================================================
  // UNE MISSION
  // ============================================================

  Future<Mission?> getActiveMissionForCamion(
      int camionId, {
        String? token,
      }) async {
    final Uri uri = Uri.parse('$_baseUrl/camions/$camionId/mission-active');

    try {
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(_timeout);

      if (response.statusCode == 404) {
        return null; // pas de mission en cours, ce n'est pas une erreur
      }

      _checkResponse(response);
      final decoded = _decodeJson(response);
      final data = _extractMission(decoded);

      return data != null ? Mission.fromJson(data) : null;
    } on TimeoutException {
      throw Exception('Le serveur met trop de temps à répondre.');
    } catch (e) {
      throw Exception(_cleanError(e));
    }
  }

  // ============================================================
  // CRÉER UNE MISSION
  // ============================================================

  Future<Mission> createMission(
      Mission mission, {
        String? token,
      }) async {
    final Uri uri = Uri.parse('$_baseUrl/missions');

    try {
      final Map<String, dynamic> payload = mission.toJson();

      final response = await http
          .post(
        uri,
        headers: _headers(token),
        body: jsonEncode(payload),
      )
          .timeout(_timeout);

      _checkResponse(response);

      final dynamic decoded = _decodeJson(response);

      final Map<String, dynamic>? data = _extractMission(decoded);

      if (data == null) {
        throw Exception(
          'La mission créée n\'a pas été retournée par le serveur.',
        );
      }

      return Mission.fromJson(data);
    } on TimeoutException {
      throw Exception(
        'Le serveur met trop de temps à répondre.',
      );
    } on FormatException {
      throw Exception(
        'Réponse invalide du serveur.',
      );
    } catch (e) {
      throw Exception(_cleanError(e));
    }
  }

  // ============================================================
  // MODIFIER UNE MISSION
  // ============================================================

  Future<Mission> updateMission(
      Mission mission, {
        String? token,
      }) async {
    if (mission.id == null) {
      throw Exception(
        'Identifiant de mission manquant.',
      );
    }

    final Uri uri = Uri.parse(
      '$_baseUrl/missions/${mission.id}',
    );

    try {
      final Map<String, dynamic> payload = mission.toJson();

      final response = await http
          .put(
        uri,
        headers: _headers(token),
        body: jsonEncode(payload),
      )
          .timeout(_timeout);

      _checkResponse(response);

      final dynamic decoded = _decodeJson(response);

      final Map<String, dynamic>? data = _extractMission(decoded);

      if (data == null) {
        throw Exception(
          'La mission modifiée n\'a pas été retournée par le serveur.',
        );
      }

      return Mission.fromJson(data);
    } on TimeoutException {
      throw Exception(
        'Le serveur met trop de temps à répondre.',
      );
    } on FormatException {
      throw Exception(
        'Réponse invalide du serveur.',
      );
    } catch (e) {
      throw Exception(_cleanError(e));
    }
  }

  // ============================================================
  // SUPPRIMER UNE MISSION
  // ============================================================

  Future<void> deleteMission(
      int id, {
        String? token,
      }) async {
    final Uri uri = Uri.parse(
      '$_baseUrl/missions/$id',
    );

    try {
      final response = await http
          .delete(
        uri,
        headers: _headers(token),
      )
          .timeout(_timeout);

      _checkResponse(response);
    } on TimeoutException {
      throw Exception(
        'Le serveur met trop de temps à répondre.',
      );
    } catch (e) {
      throw Exception(_cleanError(e));
    }
  }

  // ============================================================
  // DÉMARRER UNE MISSION
  // ============================================================

  Future<Mission> startMission(
      int id, {
        String? token,
      }) async {
    final Uri uri = Uri.parse(
      '$_baseUrl/missions/$id/start',
    );

    try {
      final response = await http
          .post(
        uri,
        headers: _headers(token),
      )
          .timeout(_timeout);

      _checkResponse(response);

      final dynamic decoded = _decodeJson(response);

      final Map<String, dynamic>? data = _extractMission(decoded);

      if (data == null) {
        throw Exception(
          'La mission démarrée n\'a pas été retournée.',
        );
      }

      return Mission.fromJson(data);
    } on TimeoutException {
      throw Exception(
        'Le serveur met trop de temps à répondre.',
      );
    } on FormatException {
      throw Exception(
        'Réponse invalide du serveur.',
      );
    } catch (e) {
      throw Exception(_cleanError(e));
    }
  }

  // ============================================================
  // TERMINER UNE MISSION
  // ============================================================

  Future<Mission> completeMission(
      int id, {
        String? token,
      }) async {
    final Uri uri = Uri.parse(
      '$_baseUrl/missions/$id/complete',
    );

    try {
      final response = await http
          .post(
        uri,
        headers: _headers(token),
      )
          .timeout(_timeout);

      _checkResponse(response);

      final dynamic decoded = _decodeJson(response);

      final Map<String, dynamic>? data = _extractMission(decoded);

      if (data == null) {
        throw Exception(
          'La mission terminée n\'a pas été retournée.',
        );
      }

      return Mission.fromJson(data);
    } on TimeoutException {
      throw Exception(
        'Le serveur met trop de temps à répondre.',
      );
    } on FormatException {
      throw Exception(
        'Réponse invalide du serveur.',
      );
    } catch (e) {
      throw Exception(_cleanError(e));
    }
  }

  // ============================================================
  // DÉCODER LE JSON
  // ============================================================

  dynamic _decodeJson(http.Response response) {
    if (response.body.trim().isEmpty) {
      throw const FormatException(
        'La réponse du serveur est vide.',
      );
    }

    return jsonDecode(response.body);
  }

  // ============================================================
  // EXTRAIRE UNE LISTE DE MISSIONS
  // ============================================================

  List<dynamic> _extractMissionList(dynamic decoded) {
    if (decoded is List) {
      return List<dynamic>.from(decoded);
    }

    if (decoded is Map) {
      if (decoded['data'] is List) {
        return List<dynamic>.from(decoded['data']);
      }

      if (decoded['missions'] is List) {
        return List<dynamic>.from(decoded['missions']);
      }

      // Certains endpoints Laravel peuvent retourner :
      // { "data": { "missions": [...] } }

      if (decoded['data'] is Map) {
        final dynamic nestedData = decoded['data'];

        if (nestedData['missions'] is List) {
          return List<dynamic>.from(
            nestedData['missions'],
          );
        }
      }
    }

    return [];
  }

  // ============================================================
  // EXTRAIRE UNE MISSION
  // ============================================================

  Map<String, dynamic>? _extractMission(
      dynamic decoded,
      ) {
    if (decoded is! Map) {
      return null;
    }

    // { "data": {...} }
    if (decoded['data'] is Map) {
      return Map<String, dynamic>.from(
        decoded['data'],
      );
    }

    // { "mission": {...} }
    if (decoded['mission'] is Map) {
      return Map<String, dynamic>.from(
        decoded['mission'],
      );
    }

    // { "data": { "mission": {...} } }
    if (decoded['data'] is Map) {
      final dynamic data = decoded['data'];

      if (data['mission'] is Map) {
        return Map<String, dynamic>.from(
          data['mission'],
        );
      }
    }

    // Objet directement retourné
    return Map<String, dynamic>.from(decoded);
  }

  // ============================================================
  // VÉRIFICATION DE LA RÉPONSE HTTP
  // ============================================================

  void _checkResponse(
      http.Response response,
      ) {
    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return;
    }

    String message = 'Erreur serveur.';

    try {
      if (response.body.trim().isNotEmpty) {
        final dynamic decoded = jsonDecode(
          response.body,
        );

        if (decoded is Map) {
          // Message Laravel
          if (decoded['message'] != null) {
            message = decoded['message'].toString();
          }

          // Erreurs de validation Laravel
          if (decoded['errors'] is Map) {
            final Map<String, dynamic> errors =
            Map<String, dynamic>.from(
              decoded['errors'],
            );

            final List<String> messages = [];

            errors.forEach(
                  (String field, dynamic value) {
                if (value is List) {
                  for (final dynamic item in value) {
                    messages.add(
                      item.toString(),
                    );
                  }
                } else {
                  messages.add(
                    value.toString(),
                  );
                }
              },
            );

            if (messages.isNotEmpty) {
              message = messages.join('\n');
            }
          }
        }
      }
    } catch (_) {
      if (response.body.trim().isNotEmpty) {
        message = response.body.trim();
      }
    }

    switch (response.statusCode) {
      case 400:
        throw Exception(
          message.isNotEmpty
              ? message
              : 'Requête incorrecte.',
        );

      case 401:
        throw Exception(
          'Session expirée. Veuillez vous reconnecter.',
        );

      case 403:
        throw Exception(
          'Vous n\'êtes pas autorisé à effectuer cette action.',
        );

      case 404:
        throw Exception(
          'Mission introuvable.',
        );

      case 409:
        throw Exception(
          message.isNotEmpty
              ? message
              : 'Conflit lors du traitement de la mission.',
        );

      case 422:
        throw Exception(
          message.isNotEmpty
              ? message
              : 'Les données envoyées sont invalides.',
        );

      case 500:
        throw Exception(
          'Erreur interne du serveur Laravel.',
        );

      case 502:
      case 503:
      case 504:
        throw Exception(
          'Le serveur Laravel est temporairement indisponible.',
        );

      default:
        throw Exception(
          message.isNotEmpty
              ? message
              : 'Erreur HTTP ${response.statusCode}.',
        );
    }
  }

  // ============================================================
  // NETTOYER L'ERREUR
  // ============================================================

  String _cleanError(Object error) {
    final String message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(
        'Exception: '.length,
      );
    }

    return message;
  }
}