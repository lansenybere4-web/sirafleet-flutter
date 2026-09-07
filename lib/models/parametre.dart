class Parametre {
  final String nomApp;
  final String entreprise;
  final String version;

  final double vitesseMax;
  final double carburantMin;

  final bool notifSOS;
  final bool notifPanne;
  final bool notifMaintenance;
  final bool notifCarburant;
  final bool notifVitesse;
  final bool notifConnexion;

  final int sessionTimeout;
  final bool doubleAuth;
  final bool journalisation;

  final int frequenceGPS;
  final bool gpsActif;
  final bool historiqueGPS;

  final String apiUrl;
  final bool apiActive;

  Parametre({
    required this.nomApp,
    required this.entreprise,
    required this.version,
    required this.vitesseMax,
    required this.carburantMin,
    required this.notifSOS,
    required this.notifPanne,
    required this.notifMaintenance,
    required this.notifCarburant,
    required this.notifVitesse,
    required this.notifConnexion,
    required this.sessionTimeout,
    required this.doubleAuth,
    required this.journalisation,
    required this.frequenceGPS,
    required this.gpsActif,
    required this.historiqueGPS,
    required this.apiUrl,
    required this.apiActive,
  });

  factory Parametre.fromJson(Map<String, dynamic> json) {
    return Parametre(
      nomApp: json['nom_app'] ?? 'SiraFleet',
      entreprise: json['entreprise'] ?? '',
      version: json['version'] ?? '1.0.0',
      vitesseMax: (json['vitesse_max'] as num?)?.toDouble() ?? 90,
      carburantMin: (json['carburant_min'] as num?)?.toDouble() ?? 15,
      notifSOS: json['notif_sos'] ?? true,
      notifPanne: json['notif_panne'] ?? true,
      notifMaintenance: json['notif_maintenance'] ?? false,
      notifCarburant: json['notif_carburant'] ?? true,
      notifVitesse: json['notif_vitesse'] ?? true,
      notifConnexion: json['notif_connexion'] ?? true,
      sessionTimeout: json['session_timeout'] ?? 30,
      doubleAuth: json['double_auth'] ?? false,
      journalisation: json['journalisation'] ?? true,
      frequenceGPS: json['frequence_gps'] ?? 30,
      gpsActif: json['gps_actif'] ?? true,
      historiqueGPS: json['historique_gps'] ?? true,
      apiUrl: json['api_url'] ?? 'http://localhost:8000/api',
      apiActive: json['api_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom_app': nomApp,
      'entreprise': entreprise,
      'version': version,
      'vitesse_max': vitesseMax,
      'carburant_min': carburantMin,
      'notif_sos': notifSOS,
      'notif_panne': notifPanne,
      'notif_maintenance': notifMaintenance,
      'notif_carburant': notifCarburant,
      'notif_vitesse': notifVitesse,
      'notif_connexion': notifConnexion,
      'session_timeout': sessionTimeout,
      'double_auth': doubleAuth,
      'journalisation': journalisation,
      'frequence_gps': frequenceGPS,
      'gps_actif': gpsActif,
      'historique_gps': historiqueGPS,
      'api_url': apiUrl,
      'api_active': apiActive,
    };
  }
}