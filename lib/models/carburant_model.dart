class CarburantModel {
  // ============================================================
  // IDENTIFIANT
  // ============================================================

  final int id;

  // ============================================================
  // CAMION
  // ============================================================

  final int camionId;
  final String? camionMatricule;

  // ============================================================
  // ÉQUIPEMENT
  // ============================================================

  final int? equipementId;
  final String? equipementNom;

  // ============================================================
  // MESURE CARBURANT
  // ============================================================

  final double? niveauLitres;
  final double? niveauPourcentage;
  final DateTime? mesureAt;

  // ============================================================
  // RAVITAILLEMENT
  // ============================================================

  final int? userId;
  final String? utilisateurNom;

  final double? quantiteLitres;
  final double? cout;
  final String? station;
  final DateTime? ravitaillementAt;

  // ============================================================
  // DATES
  // ============================================================

  final DateTime? createdAt;
  final DateTime? updatedAt;

  CarburantModel({
    required this.id,
    required this.camionId,
    this.camionMatricule,
    this.equipementId,
    this.equipementNom,
    this.niveauLitres,
    this.niveauPourcentage,
    this.mesureAt,
    this.userId,
    this.utilisateurNom,
    this.quantiteLitres,
    this.cout,
    this.station,
    this.ravitaillementAt,
    this.createdAt,
    this.updatedAt,
  });

  // ============================================================
  // JSON -> MODEL
  // ============================================================

  factory CarburantModel.fromJson(Map<String, dynamic> json) {
    final camion = json['camion'];
    final equipement = json['equipement'];
    final user = json['user'];

    return CarburantModel(
      id: _toInt(json['id']) ?? 0,

      // --------------------------------------------------------
      // CAMION
      // --------------------------------------------------------

      camionId: _toInt(json['camion_id']) ??
          _toInt(camion?['id']) ??
          0,

      camionMatricule: camion?['matricule']?.toString(),

      // --------------------------------------------------------
      // ÉQUIPEMENT
      // --------------------------------------------------------

      equipementId: _toInt(json['equipement_id']) ??
          _toInt(equipement?['id']),

      equipementNom: _getEquipementNom(equipement),

      // --------------------------------------------------------
      // MESURE CARBURANT
      // --------------------------------------------------------

      niveauLitres: _toDouble(json['niveau_litres']),

      niveauPourcentage:
      _toDouble(json['niveau_pourcentage']),

      mesureAt: _toDateTime(json['mesure_at']),

      // --------------------------------------------------------
      // RAVITAILLEMENT
      // --------------------------------------------------------

      userId: _toInt(json['user_id']) ??
          _toInt(user?['id']),

      utilisateurNom: _getUserName(user),

      quantiteLitres:
      _toDouble(json['quantite_litres']),

      cout: _toDouble(json['cout']),

      station: json['station']?.toString(),

      ravitaillementAt:
      _toDateTime(json['ravitaillement_at']),

      // --------------------------------------------------------
      // DATES
      // --------------------------------------------------------

      createdAt:
      _toDateTime(json['created_at']),

      updatedAt:
      _toDateTime(json['updated_at']),
    );
  }

  // ============================================================
  // MODEL -> JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'camion_id': camionId,
    };

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
      data['mesure_at'] =
          mesureAt!.toIso8601String();
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
          ravitaillementAt!.toIso8601String();
    }

    return data;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }

  static String? _getEquipementNom(
      dynamic equipement,
      ) {
    if (equipement == null) return null;

    if (equipement['nom'] != null) {
      return equipement['nom'].toString();
    }

    if (equipement['type'] != null) {
      return equipement['type'].toString();
    }

    if (equipement['reference'] != null) {
      return equipement['reference'].toString();
    }

    return null;
  }

  static String? _getUserName(dynamic user) {
    if (user == null) return null;

    final nom = user['nom']?.toString() ?? '';
    final prenom = user['prenom']?.toString() ?? '';

    final fullName = '$prenom $nom'.trim();

    if (fullName.isNotEmpty) {
      return fullName;
    }

    return user['name']?.toString();
  }

  // ============================================================
  // TYPE DE DONNÉES
  // ============================================================

  bool get isMesure =>
      niveauLitres != null ||
          niveauPourcentage != null ||
          mesureAt != null;

  bool get isRavitaillement =>
      quantiteLitres != null ||
          ravitaillementAt != null ||
          station != null;
}