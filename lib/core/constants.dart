import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  /// URL de base de l'API, adaptée automatiquement à la plateforme.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    }

    if (Platform.isAndroid) {
      // Émulateur Android : 10.0.2.2 pointe vers le localhost de ton PC.
      //return 'http://10.0.2.2:8000/api';

      // Sur un vrai téléphone Android, remplace la ligne au-dessus par :
      return 'http://192.168.1.9:8000/api'; // IP locale de ton PC (ipconfig)
    }

    if (Platform.isIOS) {
      // Simulateur iOS : localhost fonctionne directement.
      return 'http://localhost:8000/api';

      // Sur un vrai iPhone, remplace par l'IP locale de ton PC également.
    }

    return 'http://localhost:8000/api';
  }

  static String get mediaBaseUrl {
    if (baseUrl.endsWith('/api')) {
      return baseUrl.substring(0, baseUrl.length - 4);
    }
    return baseUrl;
  }

  static const String mapTilerKey = 'Eo1M0OHEM0E9aP8G2Mmv';
}