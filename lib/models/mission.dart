import 'package:latlong2/latlong.dart';

class Mission {
  final int? id;

  final String reference;
  final String objet;
  final String type;
  final String priorite;

  final String origine;
  final String destination;

  final String camion;
  final String chauffeur;

  final int? camionId;
  final int? chauffeurId;

  final String date;
  final String heure;

  final String distance;
  final String statut;
  final String description;

  // ============================================================
  // COORDONNÉES GPS
  // ============================================================

  final double? origineLat;
  final double? origineLng;

  final double? destinationLat;
  final double? destinationLng;

  // ============================================================
  // ITINÉRAIRE (calculé par OpenRouteService au démarrage)
  // ============================================================

  final List<LatLng> itineraire;

  // ============================================================
  // ZONE GÉOGRAPHIQUE (ancien champ, conservé pour compat)
  // ============================================================

  final List<LatLng> zoneGeographique;

  const Mission({
    this.id,
    required this.reference,
    required this.objet,
    required this.type,
    required this.priorite,
    required this.origine,
    required this.destination,
    required this.camion,
    required this.chauffeur,
    this.camionId,
    this.chauffeurId,
    required this.date,
    required this.heure,
    required this.distance,
    required this.statut,
    required this.description,
    this.origineLat,
    this.origineLng,
    this.destinationLat,
    this.destinationLng,
    this.itineraire = const [],
    this.zoneGeographique = const [],
  });

  // ============================================================
  // FROM JSON
  // ============================================================

  factory Mission.fromJson(Map<String, dynamic> json) {
    final dynamic camionJson = json['camion'];
    final dynamic chauffeurJson = json['chauffeur'];

    // ------------------------------------------------------------
    // CAMION
    // ------------------------------------------------------------

    String camionNom = '';

    if (camionJson is Map) {
      camionNom = _firstNonEmpty([
        camionJson['immatriculation'],
        camionJson['matricule'],
        camionJson['nom'],
        camionJson['reference'],
      ]);
    }

    if (camionNom.isEmpty) {
      camionNom = _string(
        json['camion_nom'] ??
            json['camion_immatriculation'] ??
            (camionJson is String ? camionJson : null),
      );
    }

    // ------------------------------------------------------------
    // CHAUFFEUR
    // ------------------------------------------------------------

    String chauffeurNom = '';

    if (chauffeurJson is Map) {
      final dynamic userJson = chauffeurJson['user'];

      if (userJson is Map) {
        chauffeurNom = _firstNonEmpty([
          userJson['nom_complet'],
          '${_string(userJson['prenom'])} ${_string(userJson['nom'])}',
          userJson['nom'],
          userJson['prenom'],
        ]).trim();
      }

      if (chauffeurNom.isEmpty) {
        chauffeurNom = _firstNonEmpty([
          chauffeurJson['nom_complet'],
          '${_string(chauffeurJson['prenom'])} ${_string(chauffeurJson['nom'])}',
          chauffeurJson['nom'],
          chauffeurJson['prenom'],
          chauffeurJson['matricule'],
        ]).trim();
      }
    }

    if (chauffeurNom.isEmpty) {
      chauffeurNom = _string(
        json['chauffeur_nom'] ??
            (chauffeurJson is String ? chauffeurJson : null),
      );
    }

    // ------------------------------------------------------------
    // COORDONNÉES GPS
    // ------------------------------------------------------------

    final double? origineLat = _parseDouble(
      json['origine_lat'] ??
          json['origineLatitude'] ??
          json['origine_latitude'],
    );

    final double? origineLng = _parseDouble(
      json['origine_lng'] ??
          json['origineLongitude'] ??
          json['origine_longitude'],
    );

    final double? destinationLat = _parseDouble(
      json['destination_lat'] ??
          json['destinationLatitude'] ??
          json['destination_latitude'],
    );

    final double? destinationLng = _parseDouble(
      json['destination_lng'] ??
          json['destinationLongitude'] ??
          json['destination_longitude'],
    );

    // ------------------------------------------------------------
    // ITINÉRAIRE
    // ------------------------------------------------------------

    final List<LatLng> itineraire = _parseZone(
      json['itineraire'],
    );

    // ------------------------------------------------------------
    // ZONE (ancien champ)
    // ------------------------------------------------------------

    final List<LatLng> zone = _parseZone(
      json['zone_geographique'] ??
          json['zoneGeographique'],
    );

    return Mission(
      id: _parseInt(json['id']),

      reference: _string(json['reference']),
      objet: _string(json['objet']),
      type: _string(json['type']),
      priorite: _string(json['priorite']),

      origine: _string(json['origine']),
      destination: _string(json['destination']),

      camion: camionNom,
      chauffeur: chauffeurNom,

      camionId: _parseInt(
        json['camion_id'] ??
            (camionJson is Map ? camionJson['id'] : null),
      ),

      chauffeurId: _parseInt(
        json['chauffeur_id'] ??
            (chauffeurJson is Map ? chauffeurJson['id'] : null),
      ),

      date: _formatDate(json['date']),
      heure: _formatTime(json['heure']),

      distance: _formatDistance(json['distance']),

      statut: _normalizeStatus(
        _string(json['statut']),
      ),

      description: _string(json['description']),

      origineLat: origineLat,
      origineLng: origineLng,

      destinationLat: destinationLat,
      destinationLng: destinationLng,

      itineraire: itineraire,
      zoneGeographique: zone,
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      // ----------------------------------------------------------
      // INFORMATIONS
      // ----------------------------------------------------------

      'reference': reference,
      'objet': objet,
      'type': type,
      'priorite': priorite,

      'origine': origine,
      'destination': destination,

      // ----------------------------------------------------------
      // AFFECTATION
      // ----------------------------------------------------------

      'camion_id': camionId,
      'chauffeur_id': chauffeurId,

      // ----------------------------------------------------------
      // PLANIFICATION
      // ----------------------------------------------------------

      'date': date,
      'heure': heure.isEmpty ? null : heure,

      // ----------------------------------------------------------
      // DISTANCE
      // ----------------------------------------------------------

      'distance': distance.isEmpty ? null : distance,

      // ----------------------------------------------------------
      // STATUT
      // ----------------------------------------------------------

      'statut': _statusToBackend(statut),

      // ----------------------------------------------------------
      // DESCRIPTION
      // ----------------------------------------------------------

      'description': description.isEmpty ? null : description,

      // ----------------------------------------------------------
      // GPS DESTINATION (seule coordonnée envoyée à la création)
      // ----------------------------------------------------------

      'destination_lat': destinationLat,
      'destination_lng': destinationLng,

      // ----------------------------------------------------------
      // GPS ORIGINE (conservé pour compat, non renseigné par le
      // formulaire actuel)
      // ----------------------------------------------------------

      'origine_lat': origineLat,
      'origine_lng': origineLng,
    };
  }

  // ============================================================
  // DETAIL MAP
  // ============================================================

  Map<String, dynamic> toDetailMap() {
    return {
      'id': id,

      'reference': reference,
      'objet': objet,
      'type': type,
      'priorite': priorite,

      'origine': origine,
      'destination': destination,

      'camion': camion,
      'chauffeur': chauffeur,

      'camion_id': camionId,
      'chauffeur_id': chauffeurId,

      'date': date,
      'heure': heure,

      'distance': distance,
      'statut': statut,
      'description': description,

      'origine_lat': origineLat,
      'origine_lng': origineLng,

      'destination_lat': destinationLat,
      'destination_lng': destinationLng,

      'itineraire': itineraire
          .map((point) => {'lat': point.latitude, 'lng': point.longitude})
          .toList(),

      'zone_geographique': zoneGeographique
          .map((point) => {'lat': point.latitude, 'lng': point.longitude})
          .toList(),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  Mission copyWith({
    int? id,

    String? reference,
    String? objet,
    String? type,
    String? priorite,

    String? origine,
    String? destination,

    String? camion,
    String? chauffeur,

    int? camionId,
    int? chauffeurId,

    String? date,
    String? heure,

    String? distance,
    String? statut,
    String? description,

    double? origineLat,
    double? origineLng,

    double? destinationLat,
    double? destinationLng,

    List<LatLng>? itineraire,
    List<LatLng>? zoneGeographique,
  }) {
    return Mission(
      id: id ?? this.id,

      reference: reference ?? this.reference,
      objet: objet ?? this.objet,
      type: type ?? this.type,
      priorite: priorite ?? this.priorite,

      origine: origine ?? this.origine,
      destination: destination ?? this.destination,

      camion: camion ?? this.camion,
      chauffeur: chauffeur ?? this.chauffeur,

      camionId: camionId ?? this.camionId,
      chauffeurId: chauffeurId ?? this.chauffeurId,

      date: date ?? this.date,
      heure: heure ?? this.heure,

      distance: distance ?? this.distance,
      statut: statut ?? this.statut,
      description: description ?? this.description,

      origineLat: origineLat ?? this.origineLat,
      origineLng: origineLng ?? this.origineLng,

      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,

      itineraire: itineraire ?? this.itineraire,
      zoneGeographique: zoneGeographique ?? this.zoneGeographique,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static String _string(dynamic value) {
    if (value == null) {
      return '';
    }

    final String result = value.toString();

    if (result.toLowerCase() == 'null') {
      return '';
    }

    return result;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString().replaceAll(',', '.').trim(),
    );
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final dynamic value in values) {
      final String text = _string(value).trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  // ============================================================
  // PARSE ZONE / ITINÉRAIRE (même format : liste de points)
  // ============================================================

  static List<LatLng> _parseZone(dynamic value) {
    if (value == null) {
      return [];
    }

    // Si Laravel retourne une chaîne JSON brute (rare, mais on
    // évite de dépendre de dart:convert ici pour garder le modèle
    // simple — le backend renvoie normalement déjà un tableau).
    if (value is String) {
      return [];
    }

    if (value is! List) {
      return [];
    }

    final List<LatLng> result = [];

    for (final dynamic item in value) {
      // ----------------------------------------------------------
      // Format : {"lat": 12.34, "lng": -8.01}
      // ----------------------------------------------------------

      if (item is Map) {
        final double? lat = _parseDouble(item['lat'] ?? item['latitude']);

        final double? lng = _parseDouble(
          item['lng'] ?? item['lon'] ?? item['longitude'],
        );

        if (lat != null && lng != null) {
          result.add(LatLng(lat, lng));
        }

        continue;
      }

      // ----------------------------------------------------------
      // Format : [12.34, -8.01]
      // ----------------------------------------------------------

      if (item is List && item.length >= 2) {
        final double? lat = _parseDouble(item[0]);
        final double? lng = _parseDouble(item[1]);

        if (lat != null && lng != null) {
          result.add(LatLng(lat, lng));
        }
      }
    }

    return result;
  }

  // ============================================================
  // DISTANCE
  // ============================================================

  static String _formatDistance(dynamic value) {
    if (value == null) {
      return '';
    }

    final double? number = _parseDouble(value);

    if (number == null) {
      return _string(value);
    }

    return number.toStringAsFixed(2);
  }

  // ============================================================
  // DATE
  // ============================================================

  static String _formatDate(dynamic value) {
    if (value == null) {
      return '';
    }

    final String text = value.toString().trim();

    if (text.isEmpty) {
      return '';
    }

    if (text.length >= 10 &&
        RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(text)) {
      return text.substring(0, 10);
    }

    try {
      final DateTime date = DateTime.parse(text);

      return '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return text;
    }
  }

  // ============================================================
  // HEURE
  // ============================================================

  static String _formatTime(dynamic value) {
    if (value == null) {
      return '';
    }

    final String text = value.toString().trim();

    if (text.isEmpty) {
      return '';
    }

    final List<String> parts = text.split(':');

    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }

    return text;
  }

  // ============================================================
  // STATUS
  // ============================================================

  static String _normalizeStatus(String status) {
    switch (status.toLowerCase().trim()) {
      case 'a_venir':
      case 'a venir':
      case 'planifiee':
      case 'planifiée':
      case 'planifie':
      case 'planned':
        return 'Planifiée';

      case 'en_cours':
      case 'en cours':
      case 'encours':
      case 'in_progress':
        return 'En cours';

      case 'terminee':
      case 'terminée':
      case 'termine':
      case 'terminé':
      case 'completed':
        return 'Terminée';

      case 'annulee':
      case 'annulée':
      case 'annule':
      case 'annulé':
      case 'cancelled':
        return 'Annulée';

      default:
        return 'Planifiée';
    }
  }

  static String _statusToBackend(String status) {
    switch (status.toLowerCase().trim()) {
      case 'planifiée':
      case 'planifiee':
      case 'planifie':
      case 'a_venir':
      case 'a venir':
        return 'a_venir';

      case 'en cours':
      case 'en_cours':
        return 'en_cours';

      case 'terminée':
      case 'terminee':
      case 'termine':
      case 'terminé':
        return 'terminee';

      case 'annulée':
      case 'annulee':
      case 'annule':
      case 'annulé':
        return 'annulee';

      default:
        return 'a_venir';
    }
  }
}