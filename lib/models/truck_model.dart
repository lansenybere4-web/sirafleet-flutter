class TruckModel {
  // Identification
  final String id;
  final String matricule;

  // Informations générales du véhicule
  final String marque;
  final String modele;
  final int? annee;
  final String vin;
  final String numeroImmatriculation;

  // Informations techniques
  final String gpsId;
  final double kilometrage;

  // Données GPS
  final double latitude;
  final double longitude;

  // Données en temps réel
  final double vitesse;
  final double carburant;

  // État du véhicule
  final String statut;

  // Affectation
  // Sera gérée par le Responsable de flotte.
  // Conservée ici pour compatibilité avec les écrans actuels.
  final String chauffeur;

  const TruckModel({
    required this.id,
    required this.matricule,
    this.marque = '',
    this.modele = '',
    this.annee,
    this.vin = '',
    this.numeroImmatriculation = '',
    this.gpsId = '',
    this.kilometrage = 0,
    required this.latitude,
    required this.longitude,
    required this.vitesse,
    required this.carburant,
    required this.statut,
    this.chauffeur = 'Non affecté',
  });

  // -----------------------------
  // États du véhicule
  // -----------------------------

  bool get enCirculation => statut == 'en_circulation';

  bool get enPanne => statut == 'en_panne';

  bool get enMaintenance => statut == 'maintenance';

  // Compatibilité avec ton ancien code
  bool get maintenance => statut == 'maintenance';

  // -----------------------------
  // État GPS
  // -----------------------------

  bool get gpsConnecte =>
      gpsId.isNotEmpty && (latitude != 0 || longitude != 0);

  // -----------------------------
  // État carburant
  // -----------------------------

  bool get carburantFaible => carburant <= 20;

  bool get carburantCritique => carburant <= 10;

  // -----------------------------
  // État technique
  // -----------------------------

  bool get informationsTechniquesCompletes =>
      marque.isNotEmpty &&
          modele.isNotEmpty &&
          vin.isNotEmpty &&
          gpsId.isNotEmpty;

  // -----------------------------
  // Affichage
  // -----------------------------

  String get nomComplet =>
      marque.isEmpty && modele.isEmpty
          ? matricule
          : '$marque $modele';

  String get anneeLabel =>
      annee == null ? 'Non renseignée' : annee.toString();

  String get kilometrageLabel =>
      '${kilometrage.toStringAsFixed(0)} km';

  String get carburantLabel =>
      '${carburant.toStringAsFixed(0)} %';

  String get vitesseLabel =>
      '${vitesse.toStringAsFixed(0)} km/h';
}