import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';

import '../models/camion_details_model.dart';
import '../models/camion_model.dart';

class CamionExportService {
  // Statut réel (calculé par Camion.statutAffiche)
  static const Map<String, String> _statuts = {
    'disponible': 'Disponible',
    'en_mission': 'En mission',
    'maintenance': 'En maintenance',
    'en_panne': 'En panne',
  };

  static const Map<String, String> _statutsMission = {
    'a_venir': 'Planifiée',
    'en_cours': 'En cours',
    'terminee': 'Terminée',
    'annulee': 'Annulée',
  };

  static final CellStyle _headerStyle = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#1D3557'),
    fontColorHex: ExcelColor.white,
  );

  static void _header(Sheet sheet, List<String> titles) {
    sheet.appendRow(titles.map<CellValue?>((t) => TextCellValue(t)).toList());
    for (var i = 0; i < titles.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .cellStyle = _headerStyle;
      sheet.setColumnWidth(i, 24);
    }
  }

  static CellValue _t(Object? v) {
    final s = v?.toString() ?? '';
    return TextCellValue(s.isEmpty ? '-' : s);
  }

  static String _iso(dynamic v) {
    final d = DateTime.tryParse(v?.toString() ?? '');
    if (d == null) return '-';
    final l = d.toLocal();
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(l.day)}/${p(l.month)}/${l.year} ${p(l.hour)}:${p(l.minute)}';
  }

  static String _nomChauffeur(dynamic chauffeur) {
    final u = chauffeur is Map ? chauffeur['user'] : null;
    if (u is! Map) return '-';
    final nom = '${u['prenom'] ?? ''} ${u['nom'] ?? ''}'.trim();
    return nom.isEmpty ? '-' : nom;
  }

  static Future<void> _save(Excel excel, String baseName) async {
    final bytes = excel.encode();

    if (bytes == null) {
      throw Exception('Impossible de générer le fichier Excel.');
    }

    final now = DateTime.now();
    String p(int n) => n.toString().padLeft(2, '0');

    await FileSaver.instance.saveFile(
      name: '${baseName}_${now.year}${p(now.month)}${p(now.day)}',
      bytes: Uint8List.fromList(bytes),
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  // ============================================================
  // EXPORT DE LA LISTE COMPLÈTE
  // ============================================================

  static Future<void> exporterListe(List<Camion> camions) async {
    final excel = Excel.createExcel();
    excel.rename(excel.getDefaultSheet() ?? 'Sheet1', 'Véhicules');
    final sheet = excel['Véhicules'];

    _header(sheet, [
      'Matricule',
      'Marque',
      'Modèle',
      'Année de fabrication',
      'Année d’acquisition',
      'Date de mise en service',
      'Statut',
      'Prochaine maintenance',
      'Kilométrage (km)',
      'Missions (total)',
      'Missions terminées',
      'Maintenances',
    ]);

    var totalKm = 0.0, totalMissions = 0, totalTerminees = 0, totalMaint = 0;

    for (final c in camions) {
      totalKm += c.kilometrage;
      totalMissions += c.missionsCount;
      totalTerminees += c.missionsTerminees;
      totalMaint += c.maintenancesCount;

      sheet.appendRow(<CellValue?>[
        _t(c.matricule),
        _t(c.marque),
        _t(c.modele),
        _t(c.annee),
        _t(c.anneeAcquisition),
        _t(formatDateFr(c.dateMiseEnService)),
        _t(_statuts[c.statutAffiche] ?? c.statutAffiche),
        _t(formatDateFr(c.prochaineMaintenanceDate)),
        DoubleCellValue(c.kilometrage),
        IntCellValue(c.missionsCount),
        IntCellValue(c.missionsTerminees),
        IntCellValue(c.maintenancesCount),
      ]);
    }

    // Ligne de totaux
    sheet.appendRow(<CellValue?>[
      TextCellValue('TOTAL (${camions.length} véhicules)'),
      null, null, null, null, null, null, null,
      DoubleCellValue(totalKm),
      IntCellValue(totalMissions),
      IntCellValue(totalTerminees),
      IntCellValue(totalMaint),
    ]);

    await _save(excel, 'sirafleet_vehicules');
  }

  // ============================================================
  // EXPORT DÉTAILLÉ D'UN VÉHICULE (5 feuilles)
  // ============================================================

  static Future<void> exporterDetails(CamionDetails d) async {
    final c = d.camion;
    final excel = Excel.createExcel();

    // --- Feuille 1 : informations ---
    excel.rename(excel.getDefaultSheet() ?? 'Sheet1', 'Informations');
    final info = excel['Informations'];
    _header(info, ['Champ', 'Valeur']);

    final prochaine = d.prochaineMaintenance;
    final enCours = d.maintenanceEnCours;

    final lignes = <List<Object?>>[
      ['Matricule', c.matricule],
      ['Marque', c.marque],
      ['Modèle', c.modele],
      ['Année de fabrication', c.annee],
      ['Année d’acquisition', c.anneeAcquisition],
      ['Date de mise en service', formatDateFr(c.dateMiseEnService)],
      ['Ancienneté (ans)', c.ancienneteAnnees],
      ['Statut', _statuts[c.statutAffiche] ?? c.statutAffiche],
      ['Kilométrage (km)', c.kilometrage],
      ['Missions (total)', c.missionsCount],
      ['Missions terminées', c.missionsTerminees],
      ['Maintenances (total)', c.maintenancesCount],
      ['Maintenance en cours', enCours == null ? 'Aucune' : enCours.reference],
      [
        'Prochaine maintenance',
        prochaine == null
            ? 'Aucune programmée'
            : '${prochaine.reference} - ${formatDateFr(prochaine.datePlanifiee)}'
      ],
      ['Coût maintenance (terminées, FCFA)', d.coutMaintenanceTotal],
      ['Alertes actives', d.alertesActives],
      ['Niveau carburant (%)', d.derniereMesure?.niveauPourcentage],
      ['Mission en cours', d.enMission ? d.missionActive!['reference'] : 'Aucune'],
    ];
    for (final l in lignes) {
      info.appendRow(<CellValue?>[_t(l[0]), _t(l[1])]);
    }

    // --- Feuille 2 : maintenances ---
    final mt = excel['Maintenances'];
    _header(mt, [
      'Référence',
      'Type',
      'Statut',
      'Priorité',
      'Date planifiée',
      'Début',
      'Fin',
      'Coût estimé',
      'Coût réel',
      'Description',
      'Notes',
    ]);
    for (final m in d.maintenances) {
      mt.appendRow(<CellValue?>[
        _t(m.reference),
        _t(m.typeLabel),
        _t(m.statutLabel),
        _t(m.prioriteLabel),
        _t(formatDateFr(m.datePlanifiee)),
        _t(formatDateFr(m.dateDebut)),
        _t(formatDateFr(m.dateFin)),
        DoubleCellValue(m.coutEstime),
        m.coutReel == null ? _t(null) : DoubleCellValue(m.coutReel!),
        _t(m.description),
        _t(m.notes),
      ]);
    }

    // --- Feuille 3 : missions ---
    final ms = excel['Missions'];
    _header(ms, [
      'Référence',
      'Origine',
      'Destination',
      'Chauffeur',
      'Date',
      'Statut',
      'Démarrée le',
      'Terminée le',
      'Distance (km)',
    ]);
    for (final m in d.missionsRecentes) {
      ms.appendRow(<CellValue?>[
        _t(m['reference']),
        _t(m['origine']),
        _t(m['destination']),
        _t(_nomChauffeur(m['chauffeur'])),
        _t(m['date']),
        _t(_statutsMission[m['statut']] ?? m['statut']),
        _t(_iso(m['started_at'])),
        _t(_iso(m['completed_at'])),
        _t(m['distance']),
      ]);
    }

    // --- Feuille 4 : équipements ---
    final eq = excel['Équipements'];
    _header(eq, ['Type', 'N° de série', 'IMEI', 'Statut']);
    for (final e in d.equipements) {
      eq.appendRow(<CellValue?>[_t(e.type), _t(e.numeroSerie), _t(e.imei), _t(e.statut)]);
    }

    // --- Feuille 5 : alertes ---
    final al = excel['Alertes'];
    _header(al, ['Type', 'Gravité', 'Statut', 'Mission', 'Date', 'Message']);
    for (final a in d.alertes) {
      al.appendRow(<CellValue?>[
        _t(a.type),
        _t(a.gravite),
        _t(a.statut),
        _t(a.missionReference),
        _t('${a.date} ${a.heure}'),
        _t(a.message),
      ]);
    }

    await _save(excel, 'sirafleet_${c.matricule}');
  }
}