class EquipementModel {
  final String id;

  final int? camionId;
  final String camionMatricule;

  final String type;
  final String numeroSerie;
  final String imei;

  final String fabricant;
  final String modele;
  final String versionFirmware;

  final String statut;

  final String dateInstallation;
  final String dateDernierControle;
  final String observation;

  const EquipementModel({
    required this.id,
    this.camionId,
    this.camionMatricule = 'Non affecté',
    required this.type,
    required this.numeroSerie,
    this.imei = '',
    this.fabricant = '',
    this.modele = '',
    this.versionFirmware = '',
    required this.statut,
    this.dateInstallation = '',
    this.dateDernierControle = '',
    this.observation = '',
  });

  factory EquipementModel.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;

      if (value is int) {
        return value;
      }

      return int.tryParse(value.toString());
    }

    String extractCamionMatricule(Map<String, dynamic> json) {
      final direct =
          json['camion_matricule'] ??
              json['camionMatricule'];

      if (direct != null && direct.toString().isNotEmpty) {
        return direct.toString();
      }

      final camion = json['camion'];

      if (camion is Map) {
        final matricule =
        camion['matricule']?.toString();

        if (matricule != null && matricule.isNotEmpty) {
          return matricule;
        }
      }

      return 'Non affecté';
    }

    return EquipementModel(
      id: json['id']?.toString() ?? '',

      camionId: parseInt(
        json['camion_id'] ??
            json['camionId'],
      ),

      camionMatricule:
      extractCamionMatricule(json),

      type:
      json['type']?.toString() ?? '',

      numeroSerie:
      json['numero_serie']?.toString() ??
          json['numeroSerie']?.toString() ??
          '',

      imei:
      json['imei']?.toString() ?? '',

      fabricant:
      json['fabricant']?.toString() ?? '',

      modele:
      json['modele']?.toString() ??
          json['modèle']?.toString() ??
          '',

      versionFirmware:
      json['version_firmware']?.toString() ??
          json['versionFirmware']?.toString() ??
          '',

      statut:
      json['statut']?.toString() ?? 'actif',

      dateInstallation:
      json['date_installation']?.toString() ??
          json['dateInstallation']?.toString() ??
          '',

      dateDernierControle:
      json['date_dernier_controle']?.toString() ??
          json['dateDernierControle']?.toString() ??
          '',

      observation:
      json['observation']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'camion_id': camionId,
      'camion_matricule':
      camionMatricule == 'Non affecté'
          ? null
          : camionMatricule,
      'type': type,
      'numero_serie': numeroSerie,
      'imei': imei.isEmpty ? null : imei,
      'fabricant':
      fabricant.isEmpty ? null : fabricant,
      'modele':
      modele.isEmpty ? null : modele,
      'version_firmware':
      versionFirmware.isEmpty
          ? null
          : versionFirmware,
      'statut': statut,
      'date_installation':
      dateInstallation.isEmpty
          ? null
          : dateInstallation,
      'date_dernier_controle':
      dateDernierControle.isEmpty
          ? null
          : dateDernierControle,
      'observation':
      observation.isEmpty
          ? null
          : observation,
    };
  }

  bool get estActif => statut == 'actif';

  bool get estEnPanne => statut == 'en_panne';

  bool get aRemplacer => statut == 'a_remplacer';

  bool get estEnMaintenance =>
      statut == 'maintenance';

  bool get estNonAffecte =>
      camionId == null ||
          camionMatricule == 'Non affecté';
}