/*import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/constants.dart';
import '../models/user_model.dart';
import '../models/role_model.dart';

class UserService {
  static const Duration _timeout = Duration(seconds: 15);

  Map<String, String> _headers(String token) => {
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ============================================================
  // UTILISATEURS
  // ============================================================

  Future<List<UserModel>> getUsers(String token) async {
    final response = await http
        .get(
      Uri.parse('${AppConstants.baseUrl}/users'),
      headers: _headers(token),
    )
        .timeout(_timeout);

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      final list = data['data'];

      if (list is! List) {
        throw Exception('Format de réponse utilisateurs invalide.');
      }

      return list
          .map(
            (e) => UserModel.fromJson(
          Map<String, dynamic>.from(e as Map),
        ),
      )
          .toList();
    }

    throw Exception(
      data['message']?.toString() ??
          'Erreur de chargement des utilisateurs.',
    );
  }

  // ============================================================
  // ROLES
  // ============================================================

  Future<List<RoleModel>> getRoles(String token) async {
    final response = await http
        .get(
      Uri.parse('${AppConstants.baseUrl}/roles'),
      headers: _headers(token),
    )
        .timeout(_timeout);

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      final list = data['data'];

      if (list is! List) {
        throw Exception('Format de réponse des rôles invalide.');
      }

      return list
          .map(
            (e) => RoleModel.fromJson(
          Map<String, dynamic>.from(e as Map),
        ),
      )
          .toList();
    }

    throw Exception(
      data['message']?.toString() ?? 'Erreur de chargement des rôles.',
    );
  }

  // ============================================================
  // CREATION UTILISATEUR
  // ============================================================
  //
  // matricule / permis / typePermis / dateEmbauche ne sont utiles
  // que si le rôle choisi est "Chauffeur" ; le backend les valide
  // et crée la ligne "chauffeurs" correspondante automatiquement.
  //
  Future<UserModel> createUser({
    required String token,
    required String nom,
    required String prenom,
    required String email,
    required String numTel,
    required String password,
    required String roleId,
    required String address,
    required String statut,
    XFile? photo,
    String? matricule,
    String? permis,
    String? typePermis,
    String siteAffection = '',
    String? dateEmbauche, // format attendu : 'YYYY-MM-DD'
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConstants.baseUrl}/users'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.fields.addAll({
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'numTel': numTel,
      'password': password,
      'roleId': roleId,
      'address': address,
      'siteAffectation': siteAffection,
      'statut': statut,
      if (matricule != null && matricule.isNotEmpty)
        'matricule': matricule,
      if (permis != null && permis.isNotEmpty)
        'permis': permis,
      if (typePermis != null && typePermis.isNotEmpty)
        'typePermis': typePermis,
      if (dateEmbauche != null && dateEmbauche.isNotEmpty)
        'dateEmbauche': dateEmbauche,
    });

    // ------------------------------------------------------------
    // PHOTO
    // ------------------------------------------------------------

    if (photo != null) {
      final bytes = await photo.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: _fileName(photo.name),
        ),
      );
    }

    final streamedResponse =
    await request.send().timeout(_timeout);

    final response = await http.Response.fromStream(
      streamedResponse,
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 201) {
      return UserModel.fromJson(
        Map<String, dynamic>.from(data['data'] as Map),
      );
    }

    throw Exception(_extractError(data));
  }

  // ============================================================
  // MODIFICATION UTILISATEUR
  // ============================================================

  Future<UserModel> updateUser({
    required String token,
    required String id,
    required String nom,
    required String prenom,
    required String email,
    required String numTel,
    String? password,
    required String roleId,
    required String address,
    required String statut,
    XFile? photo,
    String? matricule,
    String? permis,
    String? typePermis,
    String? dateEmbauche,
    String siteAffectation = '',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConstants.baseUrl}/users/$id'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    // Laravel reçoit _method=PUT
    request.fields['_method'] = 'PUT';

    request.fields.addAll({
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'numTel': numTel,
      'roleId': roleId,
      'address': address,
      'statut': statut,
    });

    if (password != null && password.isNotEmpty) {
      request.fields['password'] = password;
    }

    if (matricule != null && matricule.isNotEmpty) {
      request.fields['matricule'] = matricule;
    }

    if (permis != null && permis.isNotEmpty) {
      request.fields['permis'] = permis;
    }

    if (typePermis != null && typePermis.isNotEmpty) {
      request.fields['typePermis'] = typePermis;
    }

    if (dateEmbauche != null && dateEmbauche.isNotEmpty) {
      request.fields['dateEmbauche'] = dateEmbauche;
    }

    // ------------------------------------------------------------
    // NOUVELLE PHOTO
    // ------------------------------------------------------------

    if (photo != null) {
      final bytes = await photo.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: _fileName(photo.name),
        ),
      );
    }

    final streamedResponse =
    await request.send().timeout(_timeout);

    final response = await http.Response.fromStream(
      streamedResponse,
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      return UserModel.fromJson(
        Map<String, dynamic>.from(data['data'] as Map),
      );
    }

    throw Exception(_extractError(data));
  }

  // ============================================================
  // SUPPRESSION
  // ============================================================

  Future<void> deleteUser(
      String token,
      String id,
      ) async {
    final response = await http
        .delete(
      Uri.parse('${AppConstants.baseUrl}/users/$id'),
      headers: _headers(token),
    )
        .timeout(_timeout);

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['message']?.toString() ??
            'Erreur lors de la suppression.',
      );
    }
  }

  // ============================================================
  // OUTILS
  // ============================================================

  Map<String, dynamic> _decodeResponse(
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
      return {
        'message': 'Réponse invalide du serveur.',
      };
    }
  }

  String _extractError(
      Map<String, dynamic> data,
      ) {
    final errors = data['errors'];

    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }

        if (value != null) {
          return value.toString();
        }
      }
    }

    return data['message']?.toString() ??
        'Une erreur est survenue.';
  }

  String _fileName(String name) {
    if (name.trim().isEmpty) {
      return 'profile.jpg';
    }

    return name.split('/').last.split('\\').last;
  }
}*/


// lib/services/user_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/constants.dart';
import '../models/role_model.dart';
import '../models/user_model.dart';

class UserService {
  // Un peu plus long qu'avant : l'envoi d'une photo peut prendre du temps.
  static const Duration _timeout = Duration(seconds: 30);

  Map<String, String> _headers(String token) => {
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ============================================================
  // UTILISATEURS
  // ============================================================

  Future<List<UserModel>> getUsers(String token) async {
    final response = await http
        .get(Uri.parse('${AppConstants.baseUrl}/users'),
        headers: _headers(token))
        .timeout(_timeout);

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      final list = data['data'];
      if (list is! List) {
        throw Exception('Format de réponse utilisateurs invalide.');
      }
      return list
          .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    throw Exception(
      data['message']?.toString() ?? 'Erreur de chargement des utilisateurs.',
    );
  }

  // ============================================================
  // ROLES
  // ============================================================

  Future<List<RoleModel>> getRoles(String token) async {
    final response = await http
        .get(Uri.parse('${AppConstants.baseUrl}/roles'),
        headers: _headers(token))
        .timeout(_timeout);

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      final list = data['data'];
      if (list is! List) {
        throw Exception('Format de réponse des rôles invalide.');
      }
      return list
          .map((e) => RoleModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    throw Exception(
      data['message']?.toString() ?? 'Erreur de chargement des rôles.',
    );
  }

  // ============================================================
  // CREATION
  // ============================================================

  Future<UserModel> createUser({
    required String token,
    required String nom,
    required String prenom,
    required String email,
    required String numTel,
    required String password,
    required String roleId,
    required String address,
    required String statut,
    String siteAffectation = '',
    XFile? photo,
    String? matricule,
    String? permis,
    String? typePermis,
    String? dateEmbauche, // 'YYYY-MM-DD'
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConstants.baseUrl}/users'),
    );

    request.headers.addAll(_headers(token));

    request.fields.addAll({
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'numTel': numTel,
      'password': password,
      'roleId': roleId,
      'address': address,
      'statut': statut,
      'siteAffectation': siteAffectation,
      if (matricule != null && matricule.isNotEmpty) 'matricule': matricule,
      if (permis != null && permis.isNotEmpty) 'permis': permis,
      if (typePermis != null && typePermis.isNotEmpty)
        'typePermis': typePermis,
      if (dateEmbauche != null && dateEmbauche.isNotEmpty)
        'dateEmbauche': dateEmbauche,
    });

    await _attachPhoto(request, photo);

    final response = await _send(request);
    final data = _decodeResponse(response);

    if (response.statusCode == 201) {
      return UserModel.fromJson(
        Map<String, dynamic>.from(data['data'] as Map),
      );
    }

    throw Exception(_extractError(data));
  }

  // ============================================================
  // MODIFICATION
  // ============================================================

  Future<UserModel> updateUser({
    required String token,
    required String id,
    required String nom,
    required String prenom,
    required String email,
    required String numTel,
    String? password,
    required String roleId,
    required String address,
    required String statut,
    String siteAffectation = '',
    XFile? photo,
    String? matricule,
    String? permis,
    String? typePermis,
    String? dateEmbauche,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConstants.baseUrl}/users/$id'),
    );

    request.headers.addAll(_headers(token));

    // Laravel reçoit _method=PUT
    request.fields['_method'] = 'PUT';

    request.fields.addAll({
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'numTel': numTel,
      'roleId': roleId,
      'address': address,
      'statut': statut,
      'siteAffectation': siteAffectation,
      if (password != null && password.isNotEmpty) 'password': password,
      if (matricule != null && matricule.isNotEmpty) 'matricule': matricule,
      if (permis != null && permis.isNotEmpty) 'permis': permis,
      if (typePermis != null && typePermis.isNotEmpty)
        'typePermis': typePermis,
      if (dateEmbauche != null && dateEmbauche.isNotEmpty)
        'dateEmbauche': dateEmbauche,
    });

    await _attachPhoto(request, photo);

    final response = await _send(request);
    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      return UserModel.fromJson(
        Map<String, dynamic>.from(data['data'] as Map),
      );
    }

    throw Exception(_extractError(data));
  }

  // ============================================================
  // SUPPRESSION
  // ============================================================

  Future<void> deleteUser(String token, String id) async {
    final response = await http
        .delete(Uri.parse('${AppConstants.baseUrl}/users/$id'),
        headers: _headers(token))
        .timeout(_timeout);

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['message']?.toString() ?? 'Erreur lors de la suppression.',
      );
    }
  }

  // ============================================================
  // OUTILS
  // ============================================================

  /// Ajoute la photo à la requête multipart.
  /// Sur le web, XFile.name est souvent un identifiant sans extension :
  /// on garantit donc un nom de fichier avec extension valide.
  Future<void> _attachPhoto(
      http.MultipartRequest request,
      XFile? photo,
      ) async {
    if (photo == null) return;

    final bytes = await photo.readAsBytes();

    if (bytes.isEmpty) {
      throw Exception('La photo sélectionnée est vide.');
    }

    final filename = _photoFileName(photo);

    debugPrint(
      'UserService : envoi photo "$filename" (${bytes.length} octets)',
    );

    request.files.add(
      http.MultipartFile.fromBytes('photo', bytes, filename: filename),
    );
  }

  String _photoFileName(XFile photo) {
    final raw = photo.name.split('/').last.split('\\').last.trim();
    final dot = raw.lastIndexOf('.');

    if (dot > 0 && dot < raw.length - 1) {
      final ext = raw.substring(dot + 1).toLowerCase();
      if (['jpg', 'jpeg', 'png', 'webp'].contains(ext)) return raw;
    }

    final mime = (photo.mimeType ?? '').toLowerCase();
    final ext = mime.contains('png')
        ? 'png'
        : mime.contains('webp')
        ? 'webp'
        : 'jpg';

    return 'profile_${DateTime.now().millisecondsSinceEpoch}.$ext';
  }

  Future<http.Response> _send(http.MultipartRequest request) async {
    debugPrint('REQUEST ${request.method} ${request.url}');
    debugPrint('FIELDS ${request.fields}');

    final streamed = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamed);

    debugPrint('RESPONSE ${response.statusCode} ${response.body}');
    return response;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) return {};

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {'message': 'Réponse invalide du serveur.'};
    }
  }

  String _extractError(Map<String, dynamic> data) {
    final errors = data['errors'];

    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) return value.first.toString();
        if (value != null) return value.toString();
      }
    }

    return data['message']?.toString() ?? 'Une erreur est survenue.';
  }
}
