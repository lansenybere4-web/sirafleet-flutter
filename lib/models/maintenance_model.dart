class MaintenanceModel {
  final int id;
  final String reference;
  final int camionId;

  final String type;
  final String description;
  final String statut;
  final String priorite;

  final DateTime datePlanifiee;
  final DateTime? dateDebut;
  final DateTime? dateFin;

  final double coutEstime;
  final double? coutReel;

  final String? notes;

  final String? camionMatricule;
  final String? camionModele;

  MaintenanceModel({
    required this.id,
    required this.reference,
    required this.camionId,
    required this.type,
    required this.description,
    required this.statut,
    required this.priorite,
    required this.datePlanifiee,
    this.dateDebut,
    this.dateFin,
    required this.coutEstime,
    this.coutReel,
    this.notes,
    this.camionMatricule,
    this.camionModele,
  });

  // ============================================================
  // FROM JSON
  // ============================================================

  factory MaintenanceModel.fromJson(
      Map<String, dynamic> json,
      ) {
    final camion = json['camion'];

    return MaintenanceModel(
      id: _toInt(json['id']),

      reference:
      json['reference']?.toString() ?? '',

      camionId:
      _toInt(json['camion_id']),

      type:
      json['type']?.toString() ?? '',

      description:
      json['description']?.toString() ?? '',

      statut:
      json['statut']?.toString() ?? 'programmée',

      priorite:
      json['priorite']?.toString() ?? 'normale',

      datePlanifiee:
      _parseDate(json['date_planifiee']),

      dateDebut:
      _parseNullableDate(json['date_debut']),

      dateFin:
      _parseNullableDate(json['date_fin']),

      coutEstime:
      _toDouble(json['cout_estime']),

      coutReel:
      json['cout_reel'] == null
          ? null
          : _toDouble(json['cout_reel']),

      notes:
      json['notes']?.toString(),

      camionMatricule:
      camion != null
          ? _getCamionMatricule(camion)
          : null,

      camionModele:
      camion != null
          ? _getCamionModele(camion)
          : null,
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'camion_id': camionId,
      'type': type,
      'description': description,
      'statut': statut,
      'priorite': priorite,

      'date_planifiee':
      _formatDate(datePlanifiee),

      'date_debut':
      dateDebut == null
          ? null
          : _formatDate(dateDebut!),

      'date_fin':
      dateFin == null
          ? null
          : _formatDate(dateFin!),

      'cout_estime': coutEstime,
      'cout_reel': coutReel,
      'notes': notes,
    };
  }

  // ============================================================
  // TYPE LABEL
  // ============================================================

  String get typeLabel {
    switch (type) {
      case 'préventive':
        return 'Maintenance préventive';

      case 'corrective':
        return 'Maintenance corrective';

      default:
        return type;
    }
  }

  // ============================================================
  // STATUT LABEL
  // ============================================================

  String get statutLabel {
    switch (statut) {
      case 'programmée':
        return 'Programmée';

      case 'en_cours':
        return 'En cours';

      case 'terminée':
        return 'Terminée';

      case 'annulée':
        return 'Annulée';

      default:
        return statut;
    }
  }

  // ============================================================
  // PRIORITÉ LABEL
  // ============================================================

  String get prioriteLabel {
    switch (priorite) {
      case 'normale':
        return 'Normale';

      case 'haute':
        return 'Haute';

      case 'urgente':
        return 'Urgente';

      case 'critique':
        return 'Critique';

      default:
        return priorite;
    }
  }

  // ============================================================
  // CONVERSION INT
  // ============================================================

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  // ============================================================
  // CONVERSION DOUBLE
  // ============================================================

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  // ============================================================
  // DATE OBLIGATOIRE
  // ============================================================

  static DateTime _parseDate(dynamic value) {
    return DateTime.tryParse(
      value?.toString() ?? '',
    ) ??
        DateTime.now();
  }

  // ============================================================
  // DATE NULLABLE
  // ============================================================

  static DateTime? _parseNullableDate(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    final text = value.toString();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  static String _formatDate(DateTime date) {
    final year =
    date.year.toString().padLeft(4, '0');

    final month =
    date.month.toString().padLeft(2, '0');

    final day =
    date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // ============================================================
  // CAMION - MATRICULE
  // ============================================================

  static String? _getCamionMatricule(
      dynamic camion,
      ) {
    if (camion is! Map) {
      return null;
    }

    return camion['matricule']?.toString() ??
        camion['immatriculation']?.toString() ??
        camion['numero']?.toString();
  }

  // ============================================================
  // CAMION - MODÈLE
  // ============================================================

  static String? _getCamionModele(
      dynamic camion,
      ) {
    if (camion is! Map) {
      return null;
    }

    return camion['modele']?.toString() ??
        camion['model']?.toString();
  }
}