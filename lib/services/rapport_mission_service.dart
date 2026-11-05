import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/constants.dart';

class RapportMissionService {
  RapportMissionService({
    required this.token,
  });

  final String token;

  /// Récupère les données calculées automatiquement par le serveur pour
  /// une mission : distance (positions GPS), carburant (dernière mesure
  /// de l'équipement) et images envoyées dans la conversation.
  Future<Map<String, dynamic>> apercuAutomatique(int missionId) async {
    final url =
    Uri.parse('${AppConstants.baseUrl}/rapports-missions/apercu/$missionId');

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    Map<String, dynamic> body = {};

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    } catch (_) {
      // Réponse non JSON
    }

    if (response.statusCode == 200 && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }

    throw Exception(
      body['message']?.toString() ??
          'Impossible de charger les données automatiques.',
    );
  }

  /// Envoie le rapport de fin de mission.
  /// La distance et le carburant ne sont PLUS envoyés : ils sont pris
  /// automatiquement côté serveur depuis l'équipement du camion. Les
  /// images de la conversation sont aussi jointes côté serveur.
  /// [photos] reste possible pour des photos prises manuellement.
  Future<Map<String, dynamic>> envoyerRapport({
    required int missionId,
    required String etatCamion,
    required bool incidentSignale,
    String? incidentDescription,
    String? commentaire,
    List<XFile>? photos,
  }) async {
    final url = Uri.parse('${AppConstants.baseUrl}/rapports-missions');

    final request = http.MultipartRequest('POST', url);

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.fields.addAll({
      'mission_id': missionId.toString(),
      'etat_camion': etatCamion,
      'incident_signale': incidentSignale.toString(),
      if (incidentSignale && incidentDescription != null)
        'incident_description': incidentDescription,
      if (commentaire != null && commentaire.isNotEmpty)
        'commentaire': commentaire,
    });

    if (photos != null && photos.isNotEmpty) {
      for (final photo in photos) {
        if (kIsWeb) {
          final bytes = await photo.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'photos[]',
              bytes,
              filename: photo.name,
            ),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath(
              'photos[]',
              File(photo.path).path,
              filename: photo.name,
            ),
          );
        }
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    Map<String, dynamic> data = {};

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    } catch (_) {
      // Réponse non JSON
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    String message = 'Impossible d\u2019envoyer le rapport.';

    if (data['message'] != null) {
      message = data['message'].toString();
    }

    if (data['errors'] is Map) {
      final errors = data['errors'] as Map;
      final messages = <String>[];

      for (final entry in errors.entries) {
        final value = entry.value;
        if (value is List) {
          messages.addAll(value.map((e) => e.toString()));
        } else {
          messages.add(value.toString());
        }
      }

      if (messages.isNotEmpty) {
        message = messages.join('\n');
      }
    }

    throw Exception(message);
  }

  /// Récupère tous les rapports de mission envoyés par les chauffeurs.
  Future<List<Map<String, dynamic>>> listerRapports() async {
    final url = Uri.parse('${AppConstants.baseUrl}/rapports-missions');

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    Map<String, dynamic> decoded = {};

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        decoded = body;
      }
    } catch (_) {
      // Réponse non JSON
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = decoded['data'];
      if (data is List) {
        return List<Map<String, dynamic>>.from(
          data.map((e) => Map<String, dynamic>.from(e as Map)),
        );
      }
      return [];
    }

    throw Exception(
      decoded['message']?.toString() ?? 'Impossible de récupérer les rapports.',
    );
  }
}
