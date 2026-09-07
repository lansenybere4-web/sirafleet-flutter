import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/equipement_model.dart';

class EquipementService {
  final String baseUrl = AppConstants.baseUrl;

  static const Duration _timeout =
  Duration(seconds: 15);

  Map<String, String> _headers({
    String? token,
  }) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // LISTE
  // ============================================================

  Future<List<EquipementModel>> getEquipements({
    String? token,
  }) async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/equipements'),
        headers: _headers(token: token),
      )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception(
          _extractError(response),
        );
      }

      final decoded =
      jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Réponse invalide du serveur.',
        );
      }

      if (decoded['success'] == false) {
        throw Exception(
          decoded['message']?.toString() ??
              'Impossible de récupérer les équipements.',
        );
      }

      final data = decoded['data'];

      if (data is! List) {
        return [];
      }

      return data
          .whereType<Map>()
          .map(
            (json) => EquipementModel.fromJson(
          Map<String, dynamic>.from(json),
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

  Future<EquipementModel> getEquipement(
      String id, {
        String? token,
      }) async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/equipements/$id'),
        headers: _headers(token: token),
      )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception(
          _extractError(response),
        );
      }

      final decoded =
      jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Réponse invalide du serveur.',
        );
      }

      if (decoded['success'] == false) {
        throw Exception(
          decoded['message']?.toString() ??
              'Équipement introuvable.',
        );
      }

      final data = decoded['data'];

      if (data is! Map) {
        throw Exception(
          'Données de l’équipement invalides.',
        );
      }

      return EquipementModel.fromJson(
        Map<String, dynamic>.from(data),
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

  Future<EquipementModel> createEquipement({
    required String type,
    required String numeroSerie,
    String? imei,
    String? fabricant,
    String? modele,
    String? versionFirmware,
    int? camionId,
    required String statut,
    String? dateInstallation,
    String? dateDernierControle,
    String? observation,
    String? token,
  }) async {
    try {
      final body = <String, dynamic>{
        'type': type.trim(),
        'numero_serie': numeroSerie.trim(),
        'statut': statut,
      };

      if (imei != null &&
          imei.trim().isNotEmpty) {
        body['imei'] = imei.trim();
      }

      if (fabricant != null &&
          fabricant.trim().isNotEmpty) {
        body['fabricant'] =
            fabricant.trim();
      }

      if (modele != null &&
          modele.trim().isNotEmpty) {
        body['modele'] =
            modele.trim();
      }

      if (versionFirmware != null &&
          versionFirmware.trim().isNotEmpty) {
        body['version_firmware'] =
            versionFirmware.trim();
      }

      if (camionId != null) {
        body['camion_id'] = camionId;
      }

      if (dateInstallation != null &&
          dateInstallation.trim().isNotEmpty) {
        body['date_installation'] =
            dateInstallation.trim();
      }

      if (dateDernierControle != null &&
          dateDernierControle.trim().isNotEmpty) {
        body['date_dernier_controle'] =
            dateDernierControle.trim();
      }

      if (observation != null &&
          observation.trim().isNotEmpty) {
        body['observation'] =
            observation.trim();
      }

      final response = await http
          .post(
        Uri.parse('$baseUrl/equipements'),
        headers: _headers(token: token),
        body: jsonEncode(body),
      )
          .timeout(_timeout);

      if (response.statusCode != 201 &&
          response.statusCode != 200) {
        throw Exception(
          _extractError(response),
        );
      }

      final decoded =
      jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Réponse invalide du serveur.',
        );
      }

      if (decoded['success'] == false) {
        throw Exception(
          decoded['message']?.toString() ??
              'Impossible de créer l’équipement.',
        );
      }

      final data = decoded['data'];

      if (data is! Map) {
        throw Exception(
          'Données de l’équipement invalides.',
        );
      }

      return EquipementModel.fromJson(
        Map<String, dynamic>.from(data),
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

  Future<EquipementModel> updateEquipement({
    required String id,
    String? type,
    String? numeroSerie,
    String? imei,
    String? fabricant,
    String? modele,
    String? versionFirmware,
    int? camionId,
    String? statut,
    String? dateInstallation,
    String? dateDernierControle,
    String? observation,
    String? token,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (type != null) {
        body['type'] = type.trim();
      }

      if (numeroSerie != null) {
        body['numero_serie'] =
            numeroSerie.trim();
      }

      if (imei != null) {
        body['imei'] =
        imei.trim().isEmpty
            ? null
            : imei.trim();
      }

      if (fabricant != null) {
        body['fabricant'] =
        fabricant.trim().isEmpty
            ? null
            : fabricant.trim();
      }

      if (modele != null) {
        body['modele'] =
        modele.trim().isEmpty
            ? null
            : modele.trim();
      }

      if (versionFirmware != null) {
        body['version_firmware'] =
        versionFirmware.trim().isEmpty
            ? null
            : versionFirmware.trim();
      }

      if (camionId != null) {
        body['camion_id'] = camionId;
      }

      if (statut != null) {
        body['statut'] = statut;
      }

      if (dateInstallation != null) {
        body['date_installation'] =
        dateInstallation.trim().isEmpty
            ? null
            : dateInstallation.trim();
      }

      if (dateDernierControle != null) {
        body['date_dernier_controle'] =
        dateDernierControle.trim().isEmpty
            ? null
            : dateDernierControle.trim();
      }

      if (observation != null) {
        body['observation'] =
        observation.trim().isEmpty
            ? null
            : observation.trim();
      }

      final response = await http
          .put(
        Uri.parse(
          '$baseUrl/equipements/$id',
        ),
        headers: _headers(token: token),
        body: jsonEncode(body),
      )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception(
          _extractError(response),
        );
      }

      final decoded =
      jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Réponse invalide du serveur.',
        );
      }

      if (decoded['success'] == false) {
        throw Exception(
          decoded['message']?.toString() ??
              'Impossible de modifier l’équipement.',
        );
      }

      final data = decoded['data'];

      if (data is! Map) {
        throw Exception(
          'Données de l’équipement invalides.',
        );
      }

      return EquipementModel.fromJson(
        Map<String, dynamic>.from(data),
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

  Future<void> deleteEquipement(
      String id, {
        String? token,
      }) async {
    try {
      final response = await http
          .delete(
        Uri.parse(
          '$baseUrl/equipements/$id',
        ),
        headers: _headers(token: token),
      )
          .timeout(_timeout);

      if (response.statusCode != 200 &&
          response.statusCode != 204) {
        throw Exception(
          _extractError(response),
        );
      }

      if (response.body.trim().isNotEmpty) {
        final decoded =
        jsonDecode(response.body);

        if (decoded is Map<String, dynamic> &&
            decoded['success'] == false) {
          throw Exception(
            decoded['message']?.toString() ??
                'Impossible de supprimer l’équipement.',
          );
        }
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

  // ============================================================
  // ERREURS
  // ============================================================

  String _extractError(
      http.Response response,
      ) {
    try {
      final decoded =
      jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        if (decoded['message'] != null) {
          final message =
          decoded['message']
              .toString()
              .trim();

          if (message.isNotEmpty) {
            return message;
          }
        }

        if (decoded['error'] != null) {
          final error =
          decoded['error']
              .toString()
              .trim();

          if (error.isNotEmpty) {
            return error;
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
      }
    } catch (_) {}

    switch (response.statusCode) {
      case 400:
        return 'Requête invalide.';
      case 401:
        return 'Non authentifié. Veuillez vous reconnecter.';
      case 403:
        return 'Vous n’avez pas l’autorisation.';
      case 404:
        return 'Équipement introuvable.';
      case 409:
        return 'Cet équipement existe déjà.';
      case 422:
        return 'Les données envoyées sont invalides.';
      case 500:
        return 'Erreur interne du serveur Laravel.';
      default:
        return 'Erreur serveur (${response.statusCode}).';
    }
  }
}