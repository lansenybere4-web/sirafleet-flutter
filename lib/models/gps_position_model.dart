class PositionGpsModel {
  final int id;

  final int? equipementId;
  final int? camionId;
  final int? chauffeurId;
  final int? missionId;

  final double latitude;
  final double longitude;

  final double vitesse;
  final double? altitude;
  final double? direction;
  final double? precisionGps;

  final DateTime? datePosition;
  final DateTime? receivedAt;

  // Informations camion
  final String? matricule;
  final String? camionStatut;

  // Informations chauffeur
  final String? chauffeurNom;

  PositionGpsModel({
    required this.id,
    this.equipementId,
    this.camionId,
    this.chauffeurId,
    this.missionId,
    required this.latitude,
    required this.longitude,
    this.vitesse = 0,
    this.altitude,
    this.direction,
    this.precisionGps,
    this.datePosition,
    this.receivedAt,
    this.matricule,
    this.camionStatut,
    this.chauffeurNom,
  });

  factory PositionGpsModel.fromJson(
      Map<String, dynamic> json,
      ) {
    final camion = json['camion'] is Map
        ? Map<String, dynamic>.from(json['camion'])
        : null;

    final chauffeur = json['chauffeur'] is Map
        ? Map<String, dynamic>.from(json['chauffeur'])
        : null;

    final user = chauffeur?['user'] is Map
        ? Map<String, dynamic>.from(chauffeur!['user'])
        : null;

    return PositionGpsModel(
      id: _toInt(json['id']) ?? 0,

      equipementId: _toInt(
        json['equipement_id'],
      ),

      camionId: _toInt(
        json['camion_id'],
      ),

      chauffeurId: _toInt(
        json['chauffeur_id'],
      ),

      missionId: _toInt(
        json['mission_id'],
      ),

      latitude: _toDouble(
        json['latitude'],
      ),

      longitude: _toDouble(
        json['longitude'],
      ),

      vitesse: _toDouble(
        json['vitesse'],
      ),

      altitude: _toNullableDouble(
        json['altitude'],
      ),

      direction: _toNullableDouble(
        json['direction'],
      ),

      precisionGps: _toNullableDouble(
        json['precision_gps'],
      ),

      datePosition: _toDateTime(
        json['date_position'],
      ),

      receivedAt: _toDateTime(
        json['received_at'],
      ),

      matricule: camion?['matricule']?.toString(),

      camionStatut: camion?['statut']?.toString(),

      chauffeurNom: _getChauffeurName(
        user,
      ),
    );
  }

  // ============================================================
  // CONVERSIONS
  // ============================================================

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    ) ??
        0;
  }

  static double? _toNullableDouble(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  static DateTime? _toDateTime(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  static String? _getChauffeurName(
      Map<String, dynamic>? user,
      ) {
    if (user == null) {
      return null;
    }

    final prenom = user['prenom']?.toString() ?? '';
    final nom = user['nom']?.toString() ?? '';

    final fullName = '$prenom $nom'.trim();

    return fullName.isEmpty ? null : fullName;
  }

  // ============================================================
  // LABELS
  // ============================================================

  String get vitesseLabel {
    return '${vitesse.toStringAsFixed(0)} km/h';
  }

  String get positionLabel {
    return '${latitude.toStringAsFixed(6)}, '
        '${longitude.toStringAsFixed(6)}';
  }

  String get datePositionLabel {
    if (datePosition == null) {
      return 'Date inconnue';
    }

    final d = datePosition!;

    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }
}