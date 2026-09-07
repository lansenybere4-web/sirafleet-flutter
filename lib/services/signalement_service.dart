import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart' show XFile;

import '../core/constants.dart';
import '../models/message_signalement_model.dart';

class SignalementService {
  static String get baseUrl => AppConstants.baseUrl;

  // ============================================================
  // LISTE DES SIGNALEMENTS
  // ============================================================

  Future<List<Map<String, dynamic>>> getSignalements(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/signalements'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return _handleListResponse(response);
  }

  // ============================================================
  // DETAIL D'UN SIGNALEMENT
  // ============================================================

  Future<Map<String, dynamic>> getSignalement(
      String token,
      int signalementId,
      ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/signalements/$signalementId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 200 && body['success'] == true) {
      return Map<String, dynamic>.from(body['data']);
    }

    throw Exception(
      body['message'] ?? 'Impossible de récupérer le signalement.',
    );
  }

  // ============================================================
  // CREER UN SIGNALEMENT
  // ============================================================

  Future<Map<String, dynamic>> createSignalement(
      String token, {
        required int missionId,
        required int chauffeurId,
        required int camionId,
        required String type,
        String? description,
        double? latitude,
        double? longitude,
      }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signalements'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'mission_id': missionId,
        'chauffeur_id': chauffeurId,
        'camion_id': camionId,
        'type': type,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    final body = _decodeResponse(response);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        body['success'] == true) {
      return Map<String, dynamic>.from(body['data']);
    }

    throw Exception(
      body['message'] ?? 'Impossible de créer le signalement.',
    );
  }

  // ============================================================
  // MODIFIER LE STATUT
  // ============================================================

  Future<Map<String, dynamic>> updateStatut(
      String token,
      int signalementId,
      String statut,
      ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/signalements/$signalementId/statut'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'statut': statut}),
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 200 && body['success'] == true) {
      return Map<String, dynamic>.from(body['data']);
    }

    throw Exception(body['message'] ?? 'Impossible de modifier le statut.');
  }

  // ============================================================
  // MESSAGES — LISTE
  // ============================================================

  Future<List<MessageSignalementModel>> getMessages(
      String token,
      int signalementId,
      ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/signalements/$signalementId/messages'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 200 && body['success'] == true) {
      final data = body['data'];

      if (data is List) {
        return data
            .map(
              (item) => MessageSignalementModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
            .toList();
      }

      return [];
    }

    throw Exception(
      body['message'] ?? 'Erreur lors de la récupération des messages.',
    );
  }

  // ============================================================
  // ENVOYER UN MESSAGE TEXTE
  // ============================================================

  Future<MessageSignalementModel> sendMessage(
      String token,
      int signalementId,
      String message,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signalements/$signalementId/messages'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'message': message}),
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 201 && body['success'] == true) {
      return MessageSignalementModel.fromJson(
        Map<String, dynamic>.from(body['data']),
      );
    }

    throw Exception(body['message'] ?? 'Impossible d’envoyer le message.');
  }

  // ============================================================
  // ENVOYER UN MESSAGE VOCAL
  // ============================================================
  //
  // Prend le chemin du fichier enregistré (mobile uniquement — la
  // fonctionnalité d'enregistrement est désactivée côté web). On lit
  // les octets via XFile (package cross_file, déjà utilisé par
  // image_picker) plutôt que dart:io directement : ça reste
  // compilable pour le web sans jamais planter, même si en pratique
  // cette méthode n'est appelée qu'avec un vrai chemin mobile.
  // ============================================================

  Future<MessageSignalementModel> sendVocalMessage(
      String token,
      int signalementId,
      String audioFilePath,
      int durationSeconds,
      ) async {
    final file = XFile(audioFilePath);
    final bytes = await file.readAsBytes();
    final filename = audioFilePath.split('/').last;

    final uri = Uri.parse(
      '$baseUrl/signalements/$signalementId/messages/vocal',
    );

    final request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['audio_duration'] = durationSeconds.toString()
      ..files.add(
        http.MultipartFile.fromBytes('audio', bytes, filename: filename),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final body = _decodeResponse(response);

    if (response.statusCode == 201 && body['success'] == true) {
      return MessageSignalementModel.fromJson(
        Map<String, dynamic>.from(body['data']),
      );
    }

    throw Exception(
      body['message'] ?? 'Impossible d’envoyer le message vocal.',
    );
  }

  // ============================================================
  // ENVOYER UNE IMAGE
  // ============================================================
  //
  // Prend directement un XFile (retourné par image_picker) au lieu
  // d'un chemin — fonctionne sur web (où il n'y a pas de vrai chemin
  // fichier, juste un blob en mémoire) et sur mobile de la même
  // façon, via readAsBytes().
  // ============================================================

  Future<MessageSignalementModel> sendImageMessage(
      String token,
      int signalementId,
      XFile imageFile,
      ) async {
    final bytes = await imageFile.readAsBytes();

    final uri = Uri.parse(
      '$baseUrl/signalements/$signalementId/messages/image',
    );

    final request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: imageFile.name.isNotEmpty ? imageFile.name : 'photo.jpg',
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final body = _decodeResponse(response);

    if (response.statusCode == 201 && body['success'] == true) {
      return MessageSignalementModel.fromJson(
        Map<String, dynamic>.from(body['data']),
      );
    }

    throw Exception(body['message'] ?? 'Impossible d’envoyer l’image.');
  }

  // ============================================================
  // OUTILS
  // ============================================================

  Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {'success': false, 'message': 'Réponse serveur invalide.'};
    } catch (_) {
      return {
        'success': false,
        'message': 'Réponse serveur invalide (${response.statusCode}).',
      };
    }
  }

  List<Map<String, dynamic>> _handleListResponse(http.Response response) {
    final body = _decodeResponse(response);

    if (response.statusCode == 200 && body['success'] == true) {
      final data = body['data'];

      if (data is List) {
        return List<Map<String, dynamic>>.from(
          data.map((item) => Map<String, dynamic>.from(item)),
        );
      }

      return [];
    }

    throw Exception(
      body['message'] ?? 'Erreur lors de la récupération des données.',
    );
  }
}
