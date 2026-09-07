class AlerteModel {
  final int id;

  /// Type de l'alerte :
  /// Accident, Problème camion, Problème route, Panne, Autre
  final String type;

  /// Source : matricule du camion ou nom du chauffeur
  final String source;

  final String message;

  /// critique, importante, info
  final String gravite;

  /// Nouveau, En cours, Résolu
  final String statut;

  final String date;
  final String heure;

  /// Informations supplémentaires
  final int? signalementId;
  final int? missionId;
  final int? chauffeurId;
  final int? camionId;

  final double? latitude;
  final double? longitude;

  AlerteModel({
    required this.id,
    required this.type,
    required this.source,
    required this.message,
    required this.gravite,
    required this.statut,
    required this.date,
    required this.heure,
    this.signalementId,
    this.missionId,
    this.chauffeurId,
    this.camionId,
    this.latitude,
    this.longitude,
  });

  factory AlerteModel.fromJson(Map<String, dynamic> json) {
    final dateSignalement =
        json['date_signalement']?.toString() ??
            json['created_at']?.toString();

    DateTime? dateTime;

    if (dateSignalement != null) {
      dateTime = DateTime.tryParse(dateSignalement);
    }

    final camion = json['camion'];
    final chauffeur = json['chauffeur'];

    String source = 'Inconnu';

    if (camion is Map<String, dynamic>) {
      source =
          camion['matricule']?.toString() ??
              camion['immatriculation']?.toString() ??
              'Camion inconnu';
    } else if (chauffeur is Map<String, dynamic>) {
      final nom = chauffeur['nom']?.toString() ?? '';
      final prenom = chauffeur['prenom']?.toString() ?? '';

      source = '$prenom $nom'.trim();

      if (source.isEmpty) {
        source = 'Chauffeur inconnu';
      }
    }

    return AlerteModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      type: json['type']?.toString() ?? 'Autre',
      source: source,
      message: json['description']?.toString() ?? '',
      gravite: _calculerGravite(
        json['type']?.toString() ?? 'Autre',
      ),
      statut: json['statut']?.toString() ?? 'Nouveau',
      date: dateTime != null
          ? '${dateTime.day.toString().padLeft(2, '0')}/'
          '${dateTime.month.toString().padLeft(2, '0')}/'
          '${dateTime.year}'
          : '',
      heure: dateTime != null
          ? '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}'
          : '',
      signalementId: int.tryParse(
        json['id']?.toString() ?? '',
      ),
      missionId: int.tryParse(
        json['mission_id']?.toString() ?? '',
      ),
      chauffeurId: int.tryParse(
        json['chauffeur_id']?.toString() ?? '',
      ),
      camionId: int.tryParse(
        json['camion_id']?.toString() ?? '',
      ),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
    );
  }

  static String _calculerGravite(String type) {
    switch (type) {
      case 'Accident':
        return 'critique';

      case 'Panne':
        return 'critique';

      case 'Problème camion':
        return 'importante';

      case 'Problème route':
        return 'importante';

      case 'Autre':
      default:
        return 'info';
    }
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is double) return value;

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}