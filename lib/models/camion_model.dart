class Camion {
  final int id;
  final String matricule;
  final String? marque;
  final String? modele;
  final int? annee; // année de fabrication
  final int? anneeAcquisition;
  final DateTime? dateMiseEnService;
  final double kilometrage;
  final String statut;

  // Statistiques (renvoyées par l'API)
  final int missionsCount;
  final int missionsTerminees;
  final int maintenancesCount;
  final int maintenancesEnCours;

  final int missionsEnCours;
  final int maintenancesProgrammees;
  final DateTime? prochaineMaintenanceDate;

  Camion({
    required this.id,
    required this.matricule,
    this.marque,
    this.modele,
    this.annee,
    this.anneeAcquisition,
    this.dateMiseEnService,
    required this.kilometrage,
    required this.statut,
    this.missionsCount = 0,
    this.missionsTerminees = 0,
    this.maintenancesCount = 0,
    this.maintenancesEnCours = 0,
    this.missionsEnCours = 0,
    this.maintenancesProgrammees = 0,
    this.prochaineMaintenanceDate,
  });

  /// Vrai si au moins une maintenance est en cours sur ce camion.
  bool get enMaintenance => maintenancesEnCours > 0 || statut == 'maintenance';

  /// 'en_panne' | 'maintenance' | 'en_mission' | 'disponible'
  String get statutAffiche {
    if (statut == 'en_panne') return 'en_panne';
    if (enMaintenance) return 'maintenance';
    if (missionsEnCours > 0 || statut == 'en_circulation') return 'en_mission';
    return 'disponible';
  }

  bool get estDisponible => statutAffiche == 'disponible';

  /// Ancienneté en années complètes depuis la mise en service.
  int? get ancienneteAnnees {
    final d = dateMiseEnService;
    if (d == null) return null;
    final now = DateTime.now();
    var y = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) y--;
    return y < 0 ? 0 : y;
  }
  static int _int(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

  factory Camion.fromJson(Map<String, dynamic> json) {
    final pm = json['prochaine_maintenance'];
    final prochaine = pm is Map
        ? DateTime.tryParse(pm['date_planifiee']?.toString() ?? '')
        : null;
    return Camion(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      matricule: json['matricule']?.toString() ?? '',
      marque: json['marque']?.toString(),
      modele: json['modele']?.toString(),
      annee: json['annee'] == null
          ? null
          : int.tryParse(json['annee'].toString()),
      anneeAcquisition: json['annee_acquisition'] == null
          ? null
          : int.tryParse(json['annee_acquisition'].toString()),
      dateMiseEnService: json['date_mise_en_service'] == null
          ? null
          : DateTime.tryParse(json['date_mise_en_service'].toString()),
      kilometrage:
      double.tryParse(json['kilometrage']?.toString() ?? '0') ?? 0.0,
      statut: json['statut']?.toString() ?? 'disponible',
      missionsCount: _int(json['missions_count']),
      missionsTerminees: _int(json['missions_terminees_count']),
      maintenancesCount: _int(json['maintenances_count']),
      maintenancesEnCours: _int(json['maintenances_en_cours_count']),
      missionsEnCours: _int(json['missions_en_cours_count']),
      maintenancesProgrammees: _int(json['maintenances_programmees_count']),
      prochaineMaintenanceDate: prochaine,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'matricule': matricule,
    'marque': marque,
    'modele': modele,
    'annee': annee,
    'annee_acquisition': anneeAcquisition,
    'date_mise_en_service': dateMiseEnService == null
        ? null
        : dateMiseEnService!.toIso8601String().substring(0, 10),
    'kilometrage': kilometrage,
    'statut': statut,
  };
}


/// Format jj/mm/aaaa (ou '-' si null).
String formatDateFr(DateTime? d) {
  if (d == null) return '-';
  String p(int n) => n.toString().padLeft(2, '0');
  return '${p(d.day)}/${p(d.month)}/${d.year}';
}
