// lib/models/user_model.dart
class UserModel {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String numTel;
  final String roleId;
  final String role;
  final String address;
  final String statut;
  final String? photoProfil;
  final int? chauffeurId;
  final String siteAffectation;
  final String? createdAt;
  final String? matricule;
  final String? permis;
  final String? typePermis;
  final String? dateEmbauche;
  final int nbMissions;
  final int nbMissionsTerminees;
  final int nbMissionsEnCours;
  final int nbAccidents;

  UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.numTel,
    required this.roleId,
    required this.role,
    required this.address,
    required this.statut,
    this.photoProfil,
    this.chauffeurId,
    this.siteAffectation = '',
    this.createdAt,
    this.matricule,
    this.permis,
    this.typePermis,
    this.dateEmbauche,
    this.nbMissions = 0,
    this.nbMissionsTerminees = 0,
    this.nbMissionsEnCours = 0,
    this.nbAccidents = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawRole = json['role'];
    final ch = json['chauffeur'] is Map
        ? Map<String, dynamic>.from(json['chauffeur'])
        : null;
    final st = json['stats'] is Map
        ? Map<String, dynamic>.from(json['stats'])
        : null;
    int n(dynamic v) => int.tryParse('${v ?? 0}') ?? 0;

    String roleName = '';
    if (rawRole is Map) {
      roleName = rawRole['name']?.toString() ?? rawRole['nom']?.toString() ?? '';
    } else if (rawRole != null) {
      roleName = rawRole.toString();
    }

    // Photo : on ignore les valeurs vides pour que l'avatar par défaut s'affiche.
    String? photo = json['photoProfil']?.toString() ??
        json['photo_profil']?.toString() ??
        json['photo']?.toString();
    if (photo != null && photo.trim().isEmpty) photo = null;

    return UserModel(
      id: json['id']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      prenom: json['prenom']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      numTel: json['numTel']?.toString() ?? json['num_tel']?.toString() ?? '',
      roleId: json['roleId']?.toString() ?? json['role_id']?.toString() ?? '',
      role: roleName,
      address: json['address']?.toString() ?? '',
      statut: json['statut']?.toString() ?? 'actif',
      photoProfil: photo,
      siteAffectation: json['siteAffectation']?.toString() ??
          json['site_affectation']?.toString() ??
          '',
      createdAt: json['createdAt']?.toString(),
      matricule: ch?['matricule']?.toString(),
      permis: ch?['permis']?.toString(),
      typePermis: ch?['typePermis']?.toString(),
      dateEmbauche: ch?['dateEmbauche']?.toString(),
      nbMissions: n(st?['missions']),
      nbMissionsTerminees: n(st?['terminees']),
      nbMissionsEnCours: n(st?['enCours']),
      nbAccidents: n(st?['accidents']),
      chauffeurId: ch != null ? int.tryParse('${ch['id']}') : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'prenom': prenom,
    'email': email,
    'numTel': numTel,
    'roleId': roleId,
    'role': role,
    'address': address,
    'statut': statut,
    'photoProfil': photoProfil,
    'siteAffectation': siteAffectation,
  };

  String get fullName => '$prenom $nom'.trim();
}
