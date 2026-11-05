import 'camion_model.dart';
import 'carburant_model.dart';
import 'equipement_model.dart';
import 'alerte_model.dart';
import 'maintenance_model.dart';

class CamionDetails {
  final Camion camion;
  final List<EquipementModel> equipements;
  final CarburantModel? derniereMesure;
  final CarburantModel? dernierRavitaillement;
  final Map<String, dynamic>? missionActive;
  final List<Map<String, dynamic>> missionsRecentes;
  final List<AlerteModel> alertes;

  // Maintenances
  final MaintenanceModel? maintenanceEnCours;
  final MaintenanceModel? prochaineMaintenance;
  final List<MaintenanceModel> maintenances;
  final double coutMaintenanceTotal;

  CamionDetails({
    required this.camion,
    required this.equipements,
    this.derniereMesure,
    this.dernierRavitaillement,
    this.missionActive,
    required this.alertes,
    this.maintenanceEnCours,
    this.prochaineMaintenance,
    this.maintenances = const [],
    this.missionsRecentes = const [],
    this.coutMaintenanceTotal = 0,
  });

  bool get enMission => missionActive != null;

  bool get enMaintenance => maintenanceEnCours != null;

  int get alertesActives =>
      alertes.where((a) => a.statut != 'Résolu').length;

  factory CamionDetails.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(dynamic raw, T Function(Map<String, dynamic>) f) {
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((e) => f(Map<String, dynamic>.from(e)))
          .toList();
    }

    CarburantModel? parseOne(dynamic raw) => raw is Map
        ? CarburantModel.fromJson(Map<String, dynamic>.from(raw))
        : null;

    MaintenanceModel? parseMaintenance(dynamic raw) => raw is Map
        ? MaintenanceModel.fromJson(Map<String, dynamic>.from(raw))
        : null;

    final mission = json['mission_active'];

    return CamionDetails(
      camion: Camion.fromJson(json),
      equipements: parseList(json['equipements'], EquipementModel.fromJson),
      derniereMesure: parseOne(json['derniere_mesure_carburant']),
      dernierRavitaillement: parseOne(json['dernier_ravitaillement']),
      missionsRecentes: parseList(json['missions_recentes'], (m) => m),
      missionActive:
      mission is Map ? Map<String, dynamic>.from(mission) : null,
      alertes: parseList(json['alertes'], AlerteModel.fromJson),
      maintenanceEnCours: parseMaintenance(json['maintenance_en_cours']),
      prochaineMaintenance: parseMaintenance(json['prochaine_maintenance']),
      maintenances: parseList(json['maintenances'], MaintenanceModel.fromJson),
      coutMaintenanceTotal:
      double.tryParse(json['cout_maintenance_total']?.toString() ?? '') ??
          0,
    );
  }
}
