import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/carburant_model.dart';

class CarburantService {
  // ============================================================
  // URL API
  // ============================================================

  static String get _baseUrl => AppConstants.baseUrl;

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
  // MESURES DE CARBURANT
  // ============================================================

  /// Récupérer toutes les mesures de carburant.
  Future<List<CarburantModel>> getMesures({
    String? token,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/mesures-carburant'),
      headers: _headers(token),
    );

    return _handleListResponse(response);
  }

  /// Récupérer une mesure précise.
  Future<CarburantModel> getMesure(
      int id, {
        String? token,
      }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/mesures-carburant/$id'),
      headers: _headers(token),
    );

    return _handleSingleResponse(response);
  }

  /// Ajouter une mesure de carburant.
  Future<CarburantModel> createMesure({
    required int camionId,
    required int equipementId,
    required double niveauLitres,
    required double niveauPourcentage,
    required DateTime mesureAt,
    String? token,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/mesures-carburant'),
      headers: _headers(token),
      body: jsonEncode({
        'camion_id': camionId,
        'equipement_id': equipementId,
        'niveau_litres': niveauLitres,
        'niveau_pourcentage': niveauPourcentage,
        'mesure_at': mesureAt.toIso8601String(),
      }),
    );

    return _handleSingleResponse(response);
  }

  /// Modifier une mesure.
  Future<CarburantModel> updateMesure({
    required int id,
    int? camionId,
    int? equipementId,
    double? niveauLitres,
    double? niveauPourcentage,
    DateTime? mesureAt,
    String? token,
  }) async {
    final data = <String, dynamic>{};

    if (camionId != null) {
      data['camion_id'] = camionId;
    }

    if (equipementId != null) {
      data['equipement_id'] = equipementId;
    }

    if (niveauLitres != null) {
      data['niveau_litres'] = niveauLitres;
    }

    if (niveauPourcentage != null) {
      data['niveau_pourcentage'] = niveauPourcentage;
    }

    if (mesureAt != null) {
      data['mesure_at'] = mesureAt.toIso8601String();
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/mesures-carburant/$id'),
      headers: _headers(token),
      body: jsonEncode(data),
    );

    return _handleSingleResponse(response);
  }

  /// Supprimer une mesure.
  Future<void> deleteMesure(
      int id, {
        String? token,
      }) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/mesures-carburant/$id'),
      headers: _headers(token),
    );

    _handleDeleteResponse(response);
  }

  // ============================================================
  // DERNIÈRE MESURE D'UN CAMION
  // ============================================================

  Future<CarburantModel?> getDerniereMesure(
      int camionId, {
        String? token,
      }) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/camions/$camionId/carburant/derniere',
      ),
      headers: _headers(token),
    );

    if (response.statusCode == 404) {
      return null;
    }

    return _handleNullableResponse(response);
  }

  // ============================================================
  // HISTORIQUE MESURES D'UN CAMION
  // ============================================================

  Future<List<CarburantModel>> getHistoriqueMesures(
      int camionId, {
        String? token,
      }) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/camions/$camionId/carburant/historique',
      ),
      headers: _headers(token),
    );

    return _handleListResponse(response);
  }

  // ============================================================
  // RAVITAILLEMENTS
  // ============================================================

  /// Récupérer tous les ravitaillements.
  Future<List<CarburantModel>> getRavitaillements({
    String? token,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/ravitaillements'),
      headers: _headers(token),
    );

    return _handleListResponse(response);
  }

  /// Récupérer un ravitaillement précis.
  Future<CarburantModel> getRavitaillement(
      int id, {
        String? token,
      }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/ravitaillements/$id'),
      headers: _headers(token),
    );

    return _handleSingleResponse(response);
  }

  /// Ajouter un ravitaillement.
  Future<CarburantModel> createRavitaillement({
    required int camionId,
    int? userId,
    required double quantiteLitres,
    double? cout,
    String? station,
    required DateTime ravitaillementAt,
    String? token,
  }) async {
    final data = <String, dynamic>{
      'camion_id': camionId,
      'quantite_litres': quantiteLitres,
      'ravitaillement_at':
      ravitaillementAt.toIso8601String(),
    };

    if (userId != null) {
      data['user_id'] = userId;
    }

    if (cout != null) {
      data['cout'] = cout;
    }

    if (station != null && station.isNotEmpty) {
      data['station'] = station;
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/ravitaillements'),
      headers: _headers(token),
      body: jsonEncode(data),
    );

    return _handleSingleResponse(response);
  }

  /// Modifier un ravitaillement.
  Future<CarburantModel> updateRavitaillement({
    required int id,
    int? camionId,
    int? userId,
    double? quantiteLitres,
    double? cout,
    String? station,
    DateTime? ravitaillementAt,
    String? token,
  }) async {
    final data = <String, dynamic>{};

    if (camionId != null) {
      data['camion_id'] = camionId;
    }

    if (userId != null) {
      data['user_id'] = userId;
    }

    if (quantiteLitres != null) {
      data['quantite_litres'] = quantiteLitres;
    }

    if (cout != null) {
      data['cout'] = cout;
    }

    if (station != null) {
      data['station'] = station;
    }

    if (ravitaillementAt != null) {
      data['ravitaillement_at'] =
          ravitaillementAt.toIso8601String();
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/ravitaillements/$id'),
      headers: _headers(token),
      body: jsonEncode(data),
    );

    return _handleSingleResponse(response);
  }

  /// Supprimer un ravitaillement.
  Future<void> deleteRavitaillement(
      int id, {
        String? token,
      }) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/ravitaillements/$id'),
      headers: _headers(token),
    );

    _handleDeleteResponse(response);
  }

  // ============================================================
  // HISTORIQUE RAVITAILLEMENTS
  // ============================================================

  Future<List<CarburantModel>> getHistoriqueRavitaillements(
      int camionId, {
        String? token,
      }) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/camions/$camionId/ravitaillements/historique',
      ),
      headers: _headers(token),
    );

    return _handleListResponse(response);
  }

  // ============================================================
  // GESTION DES RÉPONSES
  // ============================================================

  List<CarburantModel> _handleListResponse(
      http.Response response,
      ) {
    final body = _decode(response);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        body['message'] ??
            'Erreur lors de la récupération des données.',
      );
    }

    final data = body['data'];

    if (data == null) {
      return [];
    }

    if (data is! List) {
      throw Exception(
        'Format de réponse API invalide.',
      );
    }

    return data
        .map(
          (item) => CarburantModel.fromJson(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();
  }

  CarburantModel _handleSingleResponse(
      http.Response response,
      ) {
    final body = _decode(response);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        body['message'] ??
            'Erreur lors de l’opération.',
      );
    }

    final data = body['data'];

    if (data == null) {
      throw Exception(
        'Aucune donnée retournée par le serveur.',
      );
    }

    return CarburantModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  CarburantModel? _handleNullableResponse(
      http.Response response,
      ) {
    final body = _decode(response);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        body['message'] ??
            'Erreur lors de la récupération.',
      );
    }

    final data = body['data'];

    if (data == null) {
      return null;
    }

    return CarburantModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  void _handleDeleteResponse(
      http.Response response,
      ) {
    final body = _decode(response);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        body['message'] ??
            'Erreur lors de la suppression.',
      );
    }
  }

  Map<String, dynamic> _decode(
      http.Response response,
      ) {
    if (response.body.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {};
    } catch (_) {
      throw Exception(
        'Réponse JSON invalide du serveur.',
      );
    }
  }
}