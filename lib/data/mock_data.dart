import '../models/alerte_model.dart';
import '../models/equipement_model.dart';
import '../models/truck_model.dart';
import '../models/user_model.dart';

class MockData {
  // ============================================================
  // CAMIONS
  // ============================================================

  static List<TruckModel> trucks = [
    TruckModel(
      id: '1',
      matricule: 'TR-045',
      marque: 'Volvo',
      modele: 'FH16',
      annee: 2024,
      vin: 'YV2A4B3C045001',
      numeroImmatriculation: 'TR-045-MD',
      gpsId: 'GPS-TR-045',
      kilometrage: 125400,
      latitude: 12.6392,
      longitude: -8.0029,
      vitesse: 67,
      carburant: 78,
      statut: 'en_circulation',
      chauffeur: 'Moussa Traoré',
    ),

    TruckModel(
      id: '2',
      matricule: 'TR-089',
      marque: 'Mercedes-Benz',
      modele: 'Actros 2651',
      annee: 2023,
      vin: 'WDBA89TR089002',
      numeroImmatriculation: 'TR-089-MD',
      gpsId: 'GPS-TR-089',
      kilometrage: 98750,
      latitude: 12.6460,
      longitude: -8.0150,
      vitesse: 34,
      carburant: 64,
      statut: 'en_circulation',
      chauffeur: 'Ibrahim Coulibaly',
    ),

    TruckModel(
      id: '3',
      matricule: 'TR-021',
      marque: 'Scania',
      modele: 'R500',
      annee: 2022,
      vin: 'YS2R21SC021003',
      numeroImmatriculation: 'TR-021-MD',
      gpsId: 'GPS-TR-021',
      kilometrage: 156300,
      latitude: 12.6320,
      longitude: -7.9910,
      vitesse: 65,
      carburant: 82,
      statut: 'en_circulation',
      chauffeur: 'Amadou Diallo',
    ),

    TruckModel(
      id: '4',
      matricule: 'TR-067',
      marque: 'MAN',
      modele: 'TGX 18.510',
      annee: 2021,
      vin: 'WMA067TGX21004',
      numeroImmatriculation: 'TR-067-MD',
      gpsId: 'GPS-TR-067',
      kilometrage: 198600,
      latitude: 12.6510,
      longitude: -7.9960,
      vitesse: 0,
      carburant: 42,
      statut: 'en_panne',
      chauffeur: 'Bakary Konaté',
    ),

    TruckModel(
      id: '5',
      matricule: 'TR-103',
      marque: 'Renault Trucks',
      modele: 'T High 520',
      annee: 2020,
      vin: 'VFTR103TH52005',
      numeroImmatriculation: 'TR-103-MD',
      gpsId: 'GPS-TR-103',
      kilometrage: 234800,
      latitude: 12.6250,
      longitude: -8.0100,
      vitesse: 0,
      carburant: 91,
      statut: 'maintenance',
      chauffeur: 'Non affecté',
    ),
  ];

  // ============================================================
  // RÔLES
  // ============================================================

  static List<MockRole> roles = [
    MockRole(
      nom: 'Admin',
      description: 'Accès complet à la plateforme',
    ),
    MockRole(
      nom: 'Directeur',
      description: 'Consultation des rapports et statistiques',
    ),
    MockRole(
      nom: 'Responsable de flotte',
      description: 'Gestion des missions, camions et chauffeurs',
    ),
    MockRole(
      nom: 'Chauffeur',
      description: 'Exécution des missions assignées',
    ),
  ];

  // ============================================================
  // ÉQUIPEMENTS
  // ============================================================

  /*static final List<EquipementModel> equipements = [
    EquipementModel(
      id: 'EQ-001',
      type: 'GPS/OBD',
      numeroSerie: 'SN-GPS-2201',
      camionMatricule: 'TR-045',
      statut: 'actif',
      dateInstallation: '12/01/2026',
    ),

    EquipementModel(
      id: 'EQ-002',
      type: 'Capteur carburant',
      numeroSerie: 'SN-FUEL-2201',
      camionMatricule: 'TR-045',
      statut: 'actif',
      dateInstallation: '12/01/2026',
    ),

    EquipementModel(
      id: 'EQ-003',
      type: 'Bouton SOS',
      numeroSerie: 'SN-SOS-2202',
      camionMatricule: 'TR-089',
      statut: 'en_panne',
      dateInstallation: '03/02/2026',
    ),

    EquipementModel(
      id: 'EQ-004',
      type: 'Caméra cabine',
      numeroSerie: 'SN-CAM-2203',
      camionMatricule: 'TR-021',
      statut: 'a_remplacer',
      dateInstallation: '20/03/2026',
    ),
  ];*/

  // ============================================================
  // ALERTES SYSTÈME
  // ============================================================

  /*static final List<AlerteModel> alertes = [
    AlerteModel(
      id: 'AL-001',
      type: 'SOS',
      source: 'TR-089',
      message: 'Bouton SOS déclenché par le chauffeur',
      gravite: 'critique',
      statut: 'nouvelle',
      date: '20/08/2026',
      heure: '08:12',
    ),

    AlerteModel(
      id: 'AL-002',
      type: 'Équipement',
      source: 'EQ-003 (Bouton SOS)',
      message: 'Équipement signalé en panne',
      gravite: 'importante',
      statut: 'nouvelle',
      date: '19/08/2026',
      heure: '16:40',
    ),

    AlerteModel(
      id: 'AL-003',
      type: 'Seuil dépassé',
      source: 'TR-045',
      message: 'Vitesse excessive détectée (98 km/h)',
      gravite: 'importante',
      statut: 'traitee',
      date: '18/08/2026',
      heure: '11:05',
    ),

    AlerteModel(
      id: 'AL-004',
      type: 'Sécurité',
      source: 'Compte Admin',
      message: 'Tentative de connexion échouée (3x)',
      gravite: 'info',
      statut: 'traitee',
      date: '17/08/2026',
      heure: '09:22',
    ),
  ];*/

  // ============================================================
  // UTILISATEURS
  // ============================================================

  /*static final List<UserModel> users = [
    UserModel(
      id: 'U-001',
      nom: 'Administrateur',
      prenom: 'Ali',
      email: 'admin@sirafleet.com',
      numTel: '87879090',
      role: 'Administrateur',
      address: 'BKO',
      statut: 'actif',
    ),

    UserModel(
      id: 'U-002',
      nom: 'Traoré',
      prenom: 'Ibrahim',
      email: 'ibrahim@gmail.com',
      numTel: '73679833',
      role: 'Responsable de flotte',
      address: 'Niamana',
      statut: 'actif',
    ),

    UserModel(
      id: 'U-003',
      nom: 'Sidibé',
      prenom: 'Fatoumata',
      email: 'fatoumata@gmail.com',
      numTel: '90000000',
      role: 'Responsable de flotte',
      address: 'Banakabougou',
      statut: 'actif',
    ),

    UserModel(
      id: 'U-004',
      nom: 'Diarra',
      prenom: 'Mamadou',
      email: 'mamadou@gmail.com',
      numTel: '76946533',
      role: 'Chauffeur',
      address: 'Sabalibougou',
      statut: 'actif',
    ),

    UserModel(
      id: 'U-005',
      nom: 'Coulibaly',
      prenom: 'Oumar',
      email: 'oumar@gmail.com',
      numTel: '65556566',
      role: 'Chauffeur',
      address: 'ACI',
      statut: 'actif',
    ),

    UserModel(
      id: 'U-006',
      nom: 'Keita',
      prenom: 'Seydou',
      email: 'seydou@gmail.com',
      numTel: '54545657',
      role: 'Chauffeur',
      address: 'Sotuba',
      statut: 'inactif',
    ),
  ];*/
}

// ============================================================
// MODÈLES MOCK POUR L'ADMINISTRATION
// ============================================================

class MockUtilisateur {
  String nom;
  String prenom;
  String email;
  String role;
  bool actif;
  String motDePasse;

  MockUtilisateur({
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    required this.actif,
    this.motDePasse = '',
  });
}

class MockRole {
  String nom;
  String description;

  MockRole({
    required this.nom,
    required this.description,
  });
}