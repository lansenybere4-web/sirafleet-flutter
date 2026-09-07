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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawRole = json['role'];

    String roleName = '';

    if (rawRole is Map) {
      roleName =
          rawRole['name']?.toString() ??
              rawRole['nom']?.toString() ??
              '';
    } else if (rawRole != null) {
      roleName = rawRole.toString();
    }

    return UserModel(
      id: json['id']?.toString() ?? '',

      nom: json['nom']?.toString() ?? '',

      prenom: json['prenom']?.toString() ?? '',

      email: json['email']?.toString() ?? '',

      numTel:
      json['numTel']?.toString() ??
          json['num_tel']?.toString() ??
          '',

      roleId:
      json['roleId']?.toString() ??
          json['role_id']?.toString() ??
          '',

      role: roleName,

      address: json['address']?.toString() ?? '',

      statut: json['statut']?.toString() ?? 'actif',

      photoProfil:
      json['photoProfil']?.toString() ??
          json['photo_profil']?.toString() ??
          json['photo']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
    };
  }

  String get fullName {
    return '$prenom $nom'.trim();
  }
}