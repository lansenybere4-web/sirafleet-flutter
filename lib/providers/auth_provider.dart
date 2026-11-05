
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/push_notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  UserModel? _user;
  String? _token;

  bool _isLoading = false;
  String? _errorMessage;

  // ============================================================
  // GETTERS
  // ============================================================

  UserModel? get user => _user;

  String? get token => _token;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get isAuthenticated {
    return _token != null &&
        _token!.trim().isNotEmpty &&
        _user != null;
  }

  // ============================================================
  // ROLE
  // ============================================================

  String? get role {
    final value = _user?.role;

    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return value.trim();
  }

  /// Normalise les différentes écritures possibles du rôle.
  ///
  /// Exemple :
  /// ADMIN -> admin
  /// ADMINISTRATEUR -> administrateur
  /// RESPONSABLE_FLOTTE -> responsable flotte
  /// RESPONSABLE-DE-FLOTTE -> responsable de flotte
  /// CHAUFFEUR -> chauffeur
  String get normalizedRole {
    return (role ?? '')
        .toLowerCase()
        .trim()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool get isAdmin {
    return normalizedRole == 'admin' ||
        normalizedRole == 'administrateur';
  }

  bool get isDirecteur {
    return normalizedRole == 'directeur';
  }

  bool get isResponsableFlotte {
    return normalizedRole == 'responsable' ||
        normalizedRole == 'responsable flotte' ||
        normalizedRole == 'responsable de flotte';
  }

  bool get isChauffeur {
    return normalizedRole == 'chauffeur';
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<bool> login(
      String email,
      String password,
      ) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      // ========================================================
      // VALIDATION
      // ========================================================

      if (email.trim().isEmpty) {
        _errorMessage =
        'Veuillez saisir votre adresse email.';

        _isLoading = false;

        notifyListeners();

        return false;
      }

      if (password.isEmpty) {
        _errorMessage =
        'Veuillez saisir votre mot de passe.';

        _isLoading = false;

        notifyListeners();

        return false;
      }

      // ========================================================
      // API LARAVEL
      // ========================================================

      final data = await _apiService.login(
        email.trim(),
        password,
      );

      debugPrint(
        '========================================',
      );

      //debugPrint('Réponse login Laravel : $data',);

      // ========================================================
      // TOKEN
      // ========================================================

      final token = data['token']?.toString();

      // ========================================================
      // UTILISATEUR
      // ========================================================

      final dynamic rawUser = data['user'];

      Map<String, dynamic>? userData;

      if (rawUser is Map) {
        userData = Map<String, dynamic>.from(
          rawUser,
        );
      }

      // ========================================================
      // VERIFICATION
      // ========================================================

      if (token == null ||
          token.trim().isEmpty ||
          userData == null) {
        _errorMessage =
        'Réponse invalide du serveur. Token ou utilisateur manquant.';

        _isLoading = false;

        notifyListeners();

        return false;
      }

      // ========================================================
      // CREATION USER MODEL
      // ========================================================

      final UserModel loggedUser =
      UserModel.fromJson(userData);

      // ========================================================
      // MEMOIRE
      // ========================================================

      _token = token;

      _user = loggedUser;

      // ========================================================
      // SAUVEGARDE LOCALE
      // ========================================================

      final prefs =
      await SharedPreferences.getInstance();

      await prefs.setString(
        'token',
        token,
      );

      await prefs.setString(
        'user',
        jsonEncode(userData),
      );

      await PushNotificationService.instance.registerToken(token);

      // ========================================================
      // FIN
      // ========================================================

      _isLoading = false;

      _errorMessage = null;

      notifyListeners();

      debugPrint(
        'Utilisateur : ${loggedUser.nom} ${loggedUser.prenom}',
      );

      debugPrint(
        'Email : ${loggedUser.email}',
      );

      debugPrint(
        'Role brut : "${loggedUser.role}"',
      );

      debugPrint(
        'Role normalisé : "$normalizedRole"',
      );

      debugPrint(
        'Connexion réussie.',
      );

      debugPrint(
        '========================================',
      );

      return true;
    } catch (e) {
      debugPrint(
        'Erreur login : $e',
      );

      _errorMessage =
          _cleanErrorMessage(e);

      _isLoading = false;

      notifyListeners();

      return false;
    }

  }

  // ============================================================
  // AUTO LOGIN
  // ============================================================

  Future<void> tryAutoLogin() async {
    try {
      final prefs =
      await SharedPreferences.getInstance();

      final savedToken =
      prefs.getString('token');

      final savedUser =
      prefs.getString('user');

      // ========================================================
      // TOKEN ABSENT
      // ========================================================

      if (savedToken == null ||
          savedToken.trim().isEmpty) {
        return;
      }

      _token = savedToken;

      // ========================================================
      // RESTAURATION LOCALE
      // ========================================================

      if (savedUser != null &&
          savedUser.trim().isNotEmpty) {
        try {
          final dynamic decodedUser =
          jsonDecode(savedUser);

          if (decodedUser is Map) {
            final userData =
            Map<String, dynamic>.from(
              decodedUser,
            );

            _user =
                UserModel.fromJson(userData);

            notifyListeners();

            debugPrint(
              'Utilisateur restauré : ${_user?.nom}',
            );

            debugPrint(
              'Role restauré : "${_user?.role}"',
            );
          }
        } catch (e) {
          debugPrint(
            'Erreur décodage utilisateur local : $e',
          );

          await logout(
            callApi: false,
          );

          return;
        }
      }

      // ========================================================
      // VERIFICATION LARAVEL
      // ========================================================

      try {
        final data =
        await _apiService.getUser(
          _token!,
        );

        //debugPrint('Réponse /me : $data',);

        dynamic rawUser;

        if (data['data'] is Map) {
          rawUser = data['data'];
        } else if (data['user'] is Map) {
          rawUser = data['user'];
        } else {
          rawUser = data;
        }

        if (rawUser is! Map) {
          throw Exception(
            'Utilisateur introuvable dans la réponse Laravel.',
          );
        }

        final userData =
        Map<String, dynamic>.from(
          rawUser,
        );

        _user =
            UserModel.fromJson(userData);

        await prefs.setString(
          'user',
          jsonEncode(userData),
        );

        notifyListeners();

        debugPrint(
          'Session Laravel valide.',
        );

        debugPrint(
          'Role : "$normalizedRole"',
        );
      } catch (e) {
        debugPrint(
          'Session Laravel invalide : $e',
        );

        await logout(
          callApi: false,
        );
      }
    } catch (e) {
      debugPrint(
        'Erreur auto login : $e',
      );

      await logout(
        callApi: false,
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================


  Future<void> logout({
    bool callApi = true,
  }) async {
    final currentToken = _token; // capturé avant tout nettoyage

    if (callApi && currentToken != null && currentToken.trim().isNotEmpty) {
      try {
        await _apiService.logout(currentToken);
        debugPrint('Déconnexion Laravel réussie.');
      } catch (e) {
        debugPrint('Erreur logout API : $e');
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');

      if (currentToken != null && currentToken.trim().isNotEmpty) {
        await PushNotificationService.instance.unregisterToken(currentToken);
      }
    } catch (e) {
      debugPrint('Erreur suppression session locale : $e');
    }

    _user = null;
    _token = null;
    _errorMessage = null;
    _isLoading = false;

    notifyListeners();

    debugPrint('Session locale supprimée.');
  }



  // ============================================================
  // REFRESH USER
  // ============================================================

  Future<bool> refreshUser() async {
    if (_token == null ||
        _token!.trim().isEmpty) {
      return false;
    }

    try {
      final data =
      await _apiService.getUser(
        _token!,
      );

      dynamic rawUser;

      if (data['data'] is Map) {
        rawUser = data['data'];
      } else if (data['user'] is Map) {
        rawUser = data['user'];
      } else {
        rawUser = data;
      }

      if (rawUser is! Map) {
        return false;
      }

      final userData =
      Map<String, dynamic>.from(
        rawUser,
      );

      _user =
          UserModel.fromJson(userData);

      final prefs =
      await SharedPreferences.getInstance();

      await prefs.setString(
        'user',
        jsonEncode(userData),
      );

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint(
        'Erreur rafraîchissement utilisateur : $e',
      );

      return false;
    }
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // CLEAN ERROR
  // ============================================================

  String _cleanErrorMessage(
      Object error,
      ) {
    String message =
    error.toString();

    if (message.startsWith(
      'Exception: ',
    )) {
      message =
          message.replaceFirst(
            'Exception: ',
            '',
          );
    }

    if (message.trim().isEmpty) {
      return 'Une erreur est survenue.';
    }

    return message.trim();
  }
}


