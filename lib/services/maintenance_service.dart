import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/maintenance_model.dart';

class MaintenanceService {
  static const Duration _timeout = Duration(seconds: 15);

  String get _baseUrl => '${AppConstants.baseUrl}/maintenances';

  // ============================================================
  // HEADERS
  // ============================================================

  Map<String, String> _headers({required String token}) {
    return <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token.trim()}',
    };
  }

  // ============================================================
  // LISTE DES MAINTENANCES
  // ============================================================

  Future<List<Map<String, dynamic>>> getMaintenances({
    required String token,
  }) async {
    try {
      final response = await http
          .get(Uri.parse(_baseUrl), headers: _headers(token: token))
          .timeout(_timeout);

      final body = _decodeResponse(response);

      if (response.statusCode != 200) {
        throw Exception(_extractError(body));
      }

      if (body['success'] != null && body['success'] != true) {
        throw Exception(
          body['message']?.toString() ??
              'Impossible de récupérer les maintenances.',
        );
      }

      final data = body['data'];

      if (data is! List) {
        return [];
      }

      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception('Erreur de connexion au serveur.');
    }
  }

  // ============================================================
  // DETAIL MAINTENANCE
  // ============================================================

  Future<MaintenanceModel> getMaintenance(
      int id, {
        required String token,
      }) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/$id'), headers: _headers(token: token))
          .timeout(_timeout);

      final body = _decodeResponse(response);

      if (response.statusCode != 200) {
        throw Exception(_extractError(body));
      }

      if (body['data'] is! Map) {
        throw Exception('Données de la maintenance invalides.');
      }

      return MaintenanceModel.fromJson(
        Map<String, dynamic>.from(body['data']),
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception('Erreur de connexion au serveur.');
    }
  }

  // ============================================================
  // CREATION
  // ============================================================

  Future<MaintenanceModel> createMaintenance(
      Map<String, dynamic> data, {
        required String token,
      }) async {
    try {
      final response = await http
          .post(
        Uri.parse(_baseUrl),
        headers: _headers(token: token),
        body: jsonEncode(data),
      )
          .timeout(_timeout);

      final body = _decodeResponse(response);

      if (response.statusCode != 201) {
        throw Exception(_extractError(body));
      }

      if (body['data'] is! Map) {
        throw Exception('Données de la maintenance invalides.');
      }

      return MaintenanceModel.fromJson(
        Map<String, dynamic>.from(body['data']),
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception('Erreur de connexion au serveur.');
    }
  }

  // ============================================================
  // MODIFICATION
  // ============================================================

  Future<MaintenanceModel> updateMaintenance(
      int id,
      Map<String, dynamic> data, {
        required String token,
      }) async {
    try {
      final response = await http
          .put(
        Uri.parse('$_baseUrl/$id'),
        headers: _headers(token: token),
        body: jsonEncode(data),
      )
          .timeout(_timeout);

      final body = _decodeResponse(response);

      if (response.statusCode != 200) {
        throw Exception(_extractError(body));
      }

      if (body['data'] is! Map) {
        throw Exception('Données de la maintenance invalides.');
      }

      return MaintenanceModel.fromJson(
        Map<String, dynamic>.from(body['data']),
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception('Erreur de connexion au serveur.');
    }
  }

  // ============================================================
  // SUPPRESSION
  // ============================================================

  Future<void> deleteMaintenance(
      int id, {
        required String token,
      }) async {
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl/$id'), headers: _headers(token: token))
          .timeout(_timeout);

      final body = _decodeResponse(response);

      if (response.statusCode != 200) {
        throw Exception(_extractError(body));
      }

      if (body['success'] != null && body['success'] != true) {
        throw Exception(
          body['message']?.toString() ??
              'Impossible de supprimer la maintenance.',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception('Erreur de connexion au serveur.');
    }
  }

  // ============================================================
  // DECODAGE REPONSE
  // ============================================================

  Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return {'message': 'Réponse invalide du serveur.'};
    } catch (_) {
      return {
        'message': 'Réponse invalide du serveur (${response.statusCode}).',
      };
    }
  }

  // ============================================================
  // EXTRACTION ERREUR
  // ============================================================

  String _extractError(Map<String, dynamic> body) {
    if (body['message'] != null) {
      final message = body['message'].toString();

      if (message.trim().isNotEmpty) {
        return message;
      }
    }

    if (body['errors'] is Map) {
      final errors = Map<String, dynamic>.from(body['errors']);

      final messages = <String>[];

      for (final value in errors.values) {
        if (value is List) {
          messages.addAll(value.map((e) => e.toString()));
        } else {
          messages.add(value.toString());
        }
      }

      if (messages.isNotEmpty) {
        return messages.join('\n');
      }
    }

    return 'Une erreur est survenue.';
  }
}
