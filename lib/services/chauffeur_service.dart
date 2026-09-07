/*import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/chauffeur_model.dart';

class ChauffeurService {
  static const Duration _timeout = Duration(seconds: 10);

  // ============================================================
  // HEADERS
  // ============================================================

  Map<String, String> _headers(String? token) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // CHAUFFEUR CONNECTÉ
  // ============================================================

  /*Future<Map<String, dynamic>> getMyChauffeur(
      String token,
      ) async {
    try {
      final response = await http
          .get(
        Uri.parse(
          '${AppConstants.baseUrl}/chauffeur/me',
        ),
        headers: _headers(token),
      )
          .timeout(_timeout);

      final body = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {};

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(body);
      }

      throw Exception(
        body['message'] ??
            'Impossible de récupérer les informations du chauffeur.',
      );
    } on TimeoutException {
      throw Exception(
        'Le serveur met trop de temps à répondre.',
      );
    } on FormatException {
      throw Exception(
        'Réponse invalide du serveur.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }*/

  Future<Map<String, dynamic>> getMyChauffeur(
      String token,
      ) async {
    try {
      final response = await http
          .get(
        Uri.parse(
          '${AppConstants.baseUrl}/chauffeur/me',
        ),
        headers: _headers(token),
      )
          .timeout(_timeout);

      final dynamic decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {};

      if (response.statusCode != 200) {
        if (decoded is Map &&
            decoded['message'] != null) {
          throw Exception(
            decoded['message'].toString(),
          );
        }

        throw Exception(
          'Impossible de récupérer les informations du chauffeur.',
        );
      }

      if (decoded is! Map) {
        throw Exception(
          'Réponse invalide du serveur.',
        );
      }

      return Map<String, dynamic>.from(decoded);
    } on TimeoutException {
      throw Exception(
        'Le serveur met trop de temps à répondre.',
      );
    } on FormatException {
      throw Exception(
        'Réponse invalide du serveur.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  Future<List<Chauffeur>> getChauffeurs({
    String? token,
  }) async {
    try {
      final response = await http
          .get(
        Uri.parse(
          '${AppConstants.baseUrl}/chauffeurs',
        ),
        headers: _headers(token),
      )
          .timeout(_timeout);

      final body = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {};

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        String message = 'Impossible de récupérer les chauffeurs.';

        if (body is Map && body['message'] != null) {
          message = body['message'].toString();
        }

        throw Exception(message);
      }

      List<dynamic> data = [];

      if (body is List) {
        data = body;
      } else if (body is Map) {
        if (body['data'] is List) {
          data = body['data'];
        } else if (body['chauffeurs'] is List) {
          data = body['chauffeurs'];
        }
      }

      return data
          .whereType<Map>()
          .map(
            (item) => Chauffeur.fromJson(
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
      throw Exception(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  // ============================================================
  // SOS
  // ============================================================

  Future<Map<String, dynamic>> sendSOS({
    required String token,
    required double latitude,
    required double longitude,
    int? chauffeurId,
    int? camionId,
    int? missionId,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse(
          '${AppConstants.baseUrl}/signalements',
        ),
        headers: _headers(token),
        body: jsonEncode({
          'type': 'sos',
          'description': 'SOS - Urgence chauffeur',
          'latitude': latitude,
          'longitude': longitude,
          if (chauffeurId != null)
            'chauffeur_id': chauffeurId,
          if (camionId != null)
            'camion_id': camionId,
          if (missionId != null)
            'mission_id': missionId,
        }),
      )
          .timeout(_timeout);

      final body = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {};

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        return Map<String, dynamic>.from(body);
      }

      throw Exception(
        body['message'] ?? 'Impossible d’envoyer le SOS.',
      );
    } on TimeoutException {
      throw Exception(
        'Le serveur met trop de temps à répondre.',
      );
    } on FormatException {
      throw Exception(
        'Réponse invalide du serveur.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}*/


import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/chauffeur_model.dart';

class ChauffeurService {
  static const Duration _timeout = Duration(seconds: 10);

  // ============================================================
  // HEADERS
  // ============================================================

  Map<String, String> _headers(String? token) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // CHAUFFEUR CONNECTÉ (données brutes — compat historique)
  // ============================================================

  Future<Map<String, dynamic>> getMyChauffeur(
      String token,
      ) async {
    try {
      final response = await http
          .get(
        Uri.parse(
          '${AppConstants.baseUrl}/chauffeur/me',
        ),
        headers: _headers(token),
      )
          .timeout(_timeout);

      final dynamic decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {};

      if (response.statusCode != 200) {
        if (decoded is Map && decoded['message'] != null) {
          throw Exception(
            decoded['message'].toString(),
          );
        }

        throw Exception(
          'Impossible de récupérer les informations du chauffeur.',
        );
      }

      if (decoded is! Map) {
        throw Exception(
          'Réponse invalide du serveur.',
        );
      }

      return Map<String, dynamic>.from(decoded);
    } on TimeoutException {
      throw Exception(
        'Le serveur met trop de temps à répondre.',
      );
    } on FormatException {
      throw Exception(
        'Réponse invalide du serveur.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  // ============================================================
  // CHAUFFEUR CONNECTÉ — modèle prêt à l'emploi pour ProfilScreen
  // ------------------------------------------------------------
  // Fusionne data.chauffeur + data.camion avant de construire un
  // Chauffeur, pour que camionActuel soit rempli automatiquement.
  // ============================================================

  Future<Chauffeur> getMyChauffeurProfile(
      String token,
      ) async {
    final raw = await getMyChauffeur(token);

    final dynamic data = raw['data'] ?? raw;

    if (data is! Map) {
      throw Exception('Réponse invalide du serveur.');
    }

    final dynamic chauffeurData = data['chauffeur'];

    if (chauffeurData is! Map) {
      throw Exception(
        'Aucun profil chauffeur associé à cet utilisateur.',
      );
    }

    final merged = Map<String, dynamic>.from(chauffeurData);
    merged['camion'] = data['camion'];

    return Chauffeur.fromJson(merged);
  }

  // ============================================================
  // CHAUFFEUR PAR ID (vue responsable — ProfilChauffeurScreen)
  // ============================================================

  Future<Chauffeur> getChauffeurById(
      int id, {
        required String token,
      }) async {
    try {
      final response = await http
          .get(
        Uri.parse(
          '${AppConstants.baseUrl}/chauffeurs/$id',
        ),
        headers: _headers(token),
      )
          .timeout(_timeout);

      final dynamic decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {};

      if (response.statusCode != 200) {
        if (decoded is Map && decoded['message'] != null) {
          throw Exception(decoded['message'].toString());
        }

        throw Exception('Chauffeur introuvable.');
      }

      if (decoded is! Map) {
        throw Exception('Réponse invalide du serveur.');
      }

      final dynamic data = decoded['data'];

      if (data is! Map) {
        throw Exception('Réponse invalide du serveur.');
      }

      // Le backend renvoie soit { chauffeur, camion }, soit le
      // chauffeur directement selon la route — on gère les deux.
      final dynamic chauffeurData = data['chauffeur'] ?? data;

      if (chauffeurData is! Map) {
        throw Exception('Réponse invalide du serveur.');
      }

      final merged = Map<String, dynamic>.from(chauffeurData);
      merged['camion'] = data['camion'];

      return Chauffeur.fromJson(merged);
    } on TimeoutException {
      throw Exception(
        'Le serveur met trop de temps à répondre.',
      );
    } on FormatException {
      throw Exception('Réponse invalide du serveur.');
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ============================================================
  // LISTE DES CHAUFFEURS
  // ============================================================

  Future<List<Chauffeur>> getChauffeurs({
    String? token,
  }) async {
    try {
      final response = await http
          .get(
        Uri.parse(
          '${AppConstants.baseUrl}/chauffeurs',
        ),
        headers: _headers(token),
      )
          .timeout(_timeout);

      final body = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {};

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        String message = 'Impossible de récupérer les chauffeurs.';

        if (body is Map && body['message'] != null) {
          message = body['message'].toString();
        }

        throw Exception(message);
      }

      List<dynamic> data = [];

      if (body is List) {
        data = body;
      } else if (body is Map) {
        if (body['data'] is List) {
          data = body['data'];
        } else if (body['chauffeurs'] is List) {
          data = body['chauffeurs'];
        }
      }

      return data
          .whereType<Map>()
          .map(
            (item) => Chauffeur.fromJson(
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
      throw Exception(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  // ============================================================
  // MODIFIER UN CHAUFFEUR (vue responsable)
  // ============================================================

  Future<Chauffeur> updateChauffeur({
    required int id,
    required String token,
    String? matricule,
    String? permis,
    String? typePermis,
    String? dateEmbauche,
    String? statut,
  }) async {
    try {
      final response = await http
          .put(
        Uri.parse(
          '${AppConstants.baseUrl}/chauffeurs/$id',
        ),
        headers: _headers(token),
        body: jsonEncode({
          if (matricule != null) 'matricule': matricule,
          if (permis != null) 'permis': permis,
          if (typePermis != null) 'type_permis': typePermis,
          if (dateEmbauche != null)
            'date_embauche': dateEmbauche,
          if (statut != null) 'statut': statut,
        }),
      )
          .timeout(_timeout);

      final dynamic decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {};

      if (response.statusCode != 200) {
        if (decoded is Map) {
          final errors = decoded['errors'];

          if (errors is Map && errors.isNotEmpty) {
            final firstError = errors.values.first;

            if (firstError is List && firstError.isNotEmpty) {
              throw Exception(firstError.first.toString());
            }
          }

          if (decoded['message'] != null) {
            throw Exception(decoded['message'].toString());
          }
        }

        throw Exception('Mise à jour impossible.');
      }

      if (decoded is! Map || decoded['data'] is! Map) {
        throw Exception('Réponse invalide du serveur.');
      }

      return Chauffeur.fromJson(
        Map<String, dynamic>.from(decoded['data']),
      );
    } on TimeoutException {
      throw Exception(
        'Le serveur met trop de temps à répondre.',
      );
    } on FormatException {
      throw Exception('Réponse invalide du serveur.');
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ============================================================
  // SOS
  // ============================================================

  Future<Map<String, dynamic>> sendSOS({
    required String token,
    required double latitude,
    required double longitude,
    int? chauffeurId,
    int? camionId,
    int? missionId,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse(
          '${AppConstants.baseUrl}/signalements',
        ),
        headers: _headers(token),
        body: jsonEncode({
          'type': 'sos',
          'description': 'SOS - Urgence chauffeur',
          'latitude': latitude,
          'longitude': longitude,
          if (chauffeurId != null)
            'chauffeur_id': chauffeurId,
          if (camionId != null)
            'camion_id': camionId,
          if (missionId != null)
            'mission_id': missionId,
        }),
      )
          .timeout(_timeout);

      final body = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {};

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        return Map<String, dynamic>.from(body);
      }

      throw Exception(
        body['message'] ?? 'Impossible d\u2019envoyer le SOS.',
      );
    } on TimeoutException {
      throw Exception(
        'Le serveur met trop de temps à répondre.',
      );
    } on FormatException {
      throw Exception(
        'Réponse invalide du serveur.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}
