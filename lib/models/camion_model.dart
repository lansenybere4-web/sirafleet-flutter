class Camion {
  final int id;
  final String matricule;
  final String? marque;
  final String? modele;
  final int? annee;
  final double kilometrage;
  final String statut;

  Camion({
    required this.id,
    required this.matricule,
    this.marque,
    this.modele,
    this.annee,
    required this.kilometrage,
    required this.statut,
  });

  factory Camion.fromJson(Map<String, dynamic> json) {
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

      kilometrage: double.tryParse(
        json['kilometrage']?.toString() ?? '0',
      ) ??
          0.0,

      statut: json['statut']?.toString() ?? 'disponible',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricule': matricule,
      'marque': marque,
      'modele': modele,
      'annee': annee,
      'kilometrage': kilometrage,
      'statut': statut,
    };
  }
}