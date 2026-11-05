class Chauffeur {
  final int? id;
  final int? userId;

  final String nom;
  final String prenom;
  final String nomComplet;

  final String telephone;
  final String email;

  final String matricule;
  final String permis;
  final String typePermis;

  final String siteAffectation;
  final String address;
  final String? photoProfil;

  final String statut;

  final String? dateEmbauche;

  // ============================================================
  // STATISTIQUES (ajoutées pour l'écran profil)
  // ============================================================

  final int missionsCount;
  final int missionsTermineesCount;
  final int signalementsCount;

  // ============================================================
  // VÉHICULE ACTUELLEMENT AFFECTÉ (via la mission active)
  // ============================================================

  final String? camionActuel;
  final String? camionActuelType;

  const Chauffeur({
    this.id,
    this.userId,
    required this.nom,
    required this.prenom,
    required this.nomComplet,
    required this.telephone,
    required this.email,
    required this.matricule,
    required this.permis,
    required this.typePermis,
    required this.statut,
    this.dateEmbauche,
    this.missionsCount = 0,
    this.missionsTermineesCount = 0,
    this.signalementsCount = 0,
    this.camionActuel,
    this.camionActuelType,
    this.address = "",
    this.siteAffectation = '',
    this.photoProfil,
  });

  // ============================================================
  // FROM JSON
  // ------------------------------------------------------------
  // Accepte soit la réponse "plate" d'un chauffeur (ex: /chauffeurs),
  // soit la réponse enveloppée { chauffeur: {...}, camion: {...} }
  // renvoyée par ChauffeurController@me / @show — voir
  // ChauffeurService.getMyChauffeurProfile / getChauffeurById qui
  // font la fusion avant d'appeler ce factory.
  // ============================================================

  factory Chauffeur.fromJson(Map<String, dynamic> json) {
    final dynamic userData = json['user'];

    Map<String, dynamic>? user;

    if (userData is Map) {
      user = Map<String, dynamic>.from(userData);
    }

    // ------------------------------------------------------------
    // NOM
    // ------------------------------------------------------------

    final String nom = _firstNonEmpty([
      json['nom'],
      user?['nom'],
    ]);

    // ------------------------------------------------------------
    // PRENOM
    // ------------------------------------------------------------

    final String prenom = _firstNonEmpty([
      json['prenom'],
      user?['prenom'],
    ]);

    // ------------------------------------------------------------
    // TELEPHONE
    // Laravel utilise "num_tel"
    // ------------------------------------------------------------

    final String telephone = _firstNonEmpty([
      json['telephone'],
      json['num_tel'],
      user?['num_tel'],
      user?['telephone'],
    ]);

    // ------------------------------------------------------------
    // EMAIL
    // ------------------------------------------------------------

    final String email = _firstNonEmpty([
      json['email'],
      user?['email'],
    ]);

    // ------------------------------------------------------------
    // NOM COMPLET
    // ------------------------------------------------------------

    final String nomComplet = _firstNonEmpty([
      json['nom_complet'],
      json['full_name'],
      json['name'],
      user?['name'],
      '${prenom.trim()} ${nom.trim()}',
      '${nom.trim()} ${prenom.trim()}',
    ]);

    // ------------------------------------------------------------
    // MATRICULE
    // ------------------------------------------------------------

    final String matricule = _firstNonEmpty([
      json['matricule'],
    ]);

    // ------------------------------------------------------------
    // PERMIS
    // ------------------------------------------------------------

    final String permis = _firstNonEmpty([
      json['permis'],
      json['numero_permis'],
      json['numero_permis_conduire'],
    ]);

    // ------------------------------------------------------------
    // TYPE PERMIS
    // ------------------------------------------------------------

    final String typePermis = _firstNonEmpty([
      json['type_permis'],
    ]);

    // ------------------------------------------------------------
    // STATUT
    // ------------------------------------------------------------

    final String statut = _firstNonEmpty([
      json['statut'],
      json['status'],
    ]);

    // ------------------------------------------------------------
    // DATE EMBAUCHE
    // ------------------------------------------------------------

    final String? dateEmbauche =
    _nullableString(json['date_embauche']);

    // ------------------------------------------------------------
    // STATISTIQUES (withCount côté Laravel)
    // ------------------------------------------------------------

    final int missionsCount =
        _parseInt(json['missions_count']) ?? 0;

    final int missionsTermineesCount =
        _parseInt(json['missions_terminees_count']) ?? 0;

    final int signalementsCount =
        _parseInt(json['signalements_count']) ?? 0;

    // ------------------------------------------------------------
    // CAMION ACTUEL
    // ------------------------------------------------------------

    Map<String, dynamic>? camion;
    final dynamic camionData = json['camion'];

    if (camionData is Map) {
      camion = Map<String, dynamic>.from(camionData);
    }

    final String? camionActuel = camion == null
        ? null
        : _nullableString(
      camion['immatriculation'] ??
          camion['nom'] ??
          camion['plaque'],
    );

    final String? camionActuelType =
    camion == null ? null : _nullableString(camion['type']);

    final String siteAffectation = _firstNonEmpty([
      json['siteAffectation'],
      json['site_affectation'],
      user?['siteAffectation'],
      user?['site_affectation'],
    ]);

    final String address = _firstNonEmpty([
      json['address'],
      user?['address'],
    ]);

    // On ne garde la photo que si c'est une URL complète.
    final String? photoProfil = _nullableString(
      json['photo_url'] ??
          user?['photo_url'] ??
          json['photoProfil'] ??
          user?['photoProfil'],
    );
   /* final String? photoProfil =
    (photoRaw != null && photoRaw.startsWith('http')) ? photoRaw : null;*/

    return Chauffeur(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      nom: nom,
      prenom: prenom,
      nomComplet: nomComplet,
      telephone: telephone,
      email: email,
      matricule: matricule,
      permis: permis,
      typePermis: typePermis,
      statut: statut,
      dateEmbauche: dateEmbauche,
      missionsCount: missionsCount,
      missionsTermineesCount: missionsTermineesCount,
      signalementsCount: signalementsCount,
      camionActuel: camionActuel,
      camionActuelType: camionActuelType,
      siteAffectation: siteAffectation,
      address: address,
      photoProfil: photoProfil,
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nom': nom,
      'prenom': prenom,
      'nom_complet': nomComplet,
      'telephone': telephone,
      'email': email,
      'matricule': matricule,
      'permis': permis,
      'type_permis': typePermis,
      'statut': statut,
      'date_embauche': dateEmbauche,
      'missions_count': missionsCount,
      'missions_terminees_count': missionsTermineesCount,
      'signalements_count': signalementsCount,
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  Chauffeur copyWith({
    int? id,
    int? userId,
    String? nom,
    String? prenom,
    String? nomComplet,
    String? telephone,
    String? email,
    String? matricule,
    String? permis,
    String? typePermis,
    String? statut,
    String? dateEmbauche,
    int? missionsCount,
    int? missionsTermineesCount,
    int? signalementsCount,
    String? camionActuel,
    String? camionActuelType,
  }) {
    return Chauffeur(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      nomComplet: nomComplet ?? this.nomComplet,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      matricule: matricule ?? this.matricule,
      permis: permis ?? this.permis,
      typePermis: typePermis ?? this.typePermis,
      statut: statut ?? this.statut,
      dateEmbauche: dateEmbauche ?? this.dateEmbauche,
      missionsCount: missionsCount ?? this.missionsCount,
      missionsTermineesCount:
      missionsTermineesCount ?? this.missionsTermineesCount,
      signalementsCount: signalementsCount ?? this.signalementsCount,
      camionActuel: camionActuel ?? this.camionActuel,
      camionActuelType: camionActuelType ?? this.camionActuelType,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static String _string(dynamic value) {
    if (value == null) {
      return '';
    }

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') {
      return '';
    }

    return text;
  }

  static String? _nullableString(dynamic value) {
    final text = _string(value);

    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = _string(value);

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }
}
