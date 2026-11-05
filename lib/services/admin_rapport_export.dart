import 'dart:typed_data';

import 'package:excel/excel.dart' as xl;
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Impression (PDF) et export Excel d'un rapport administrateur.
class AdminRapportExport {
  static const _navy = PdfColor.fromInt(0xFF1D3557);

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _day(String? iso) {
    final d = DateTime.tryParse(iso ?? '');
    return d == null ? '-' : '${_two(d.day)}/${_two(d.month)}/${d.year}';
  }

  static String _dateTime(String? iso) {
    final d = DateTime.tryParse(iso ?? '')?.toLocal();
    return d == null ? '-' : '${_two(d.day)}/${_two(d.month)}/${d.year} ${_two(d.hour)}:${_two(d.minute)}';
  }

  static int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

  /// Les polices PDF par défaut ne gèrent pas certains caractères typographiques.
  static String _pdfSafe(String s) =>
      s.replaceAll('’', "'").replaceAll('→', '->').replaceAll('•', '-').replaceAll('…', '...');

  static String _role(dynamic r) {
    switch ('$r') {
      case 'admin':
        return 'Administrateur';
      case 'responsable':
        return 'Responsable';
      case 'chauffeur':
        return 'Chauffeur';
      default:
        return 'Système';
    }
  }

  // ============================================================
  // IMPRESSION / PDF
  // ============================================================
  static Future<void> imprimer(Map<String, dynamic> r, List<Map<String, dynamic>> activites) async {
    final modules = List<Map<String, dynamic>>.from(r['repartition_modules'] ?? []);
    final pf = Map<String, dynamic>.from(r['etat_plateforme'] ?? {});
    final notes = (r['notes'] ?? '').toString();

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Page ${ctx.pageNumber}/${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: const pw.BoxDecoration(color: _navy),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('SiraFleet - Rapport administrateur #${r['id']}',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 17, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Période : du ${_day(r['periode_debut'] as String?)} au ${_day(r['periode_fin'] as String?)}',
                  style: const pw.TextStyle(color: PdfColors.white, fontSize: 11)),
              pw.Text('Généré le ${_dateTime(r['created_at'] as String?)}',
                  style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
            ]),
          ),
          pw.SizedBox(height: 16),
          _title('Indicateurs clés'),
          pw.TableHelper.fromTextArray(
            headers: ['Indicateur', 'Valeur'],
            data: [
              ['Activités totales', '${_int(r['total_activites'])}'],
              ['Actions administrateurs', '${_int(r['activites_admin'])}'],
              ['Actions responsables', '${_int(r['activites_responsable'])}'],
              ['Actions chauffeurs', '${_int(r['activites_chauffeur'])}'],
              ['Connexions', '${_int(r['total_connexions'])}'],
              ['Actions en échec', '${_int(r['total_echecs'])}'],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: _navy),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignments: {1: pw.Alignment.centerRight},
          ),
          if (pf.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _title('État de la plateforme à la génération'),
            pw.Text(
              '${_int(pf['utilisateurs'])} utilisateurs - ${_int(pf['camions'])} camions - '
                  '${_int(pf['equipements'])} équipements - '
                  '${_int(pf['alertes_resolues'])}/${_int(pf['alertes'])} alertes résolues',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
          if (modules.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _title('Modules les plus sollicités'),
            pw.TableHelper.fromTextArray(
              headers: ['Module', 'Actions'],
              data: modules.map((m) => ['${m['module']}', '${_int(m['total'])}']).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: _navy),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignments: {1: pw.Alignment.centerRight},
            ),
          ],
          if (notes.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _title('Observations'),
            pw.Text(_pdfSafe(notes), style: const pw.TextStyle(fontSize: 10)),
          ],
          pw.SizedBox(height: 14),
          _title('Activités de la période (${activites.length})'),
          if (activites.isEmpty)
            pw.Text('Aucune activité.', style: const pw.TextStyle(fontSize: 10))
          else
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Utilisateur', 'Profil', 'Module', 'Description', 'Statut'],
              data: activites
                  .map((a) => [
                _dateTime(a['created_at'] as String?),
                _pdfSafe('${a['user_nom'] ?? 'Système'}'),
                _role(a['role']),
                _pdfSafe('${a['module'] ?? ''}'),
                _pdfSafe('${a['description'] ?? ''}'),
                a['statut'] == 'echec' ? 'Échec' : 'Succès',
              ])
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: _navy),
              cellStyle: const pw.TextStyle(fontSize: 8),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(4),
                5: const pw.FlexColumnWidth(1),
              },
            ),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: 'Rapport_admin_${r['id']}',
      onLayout: (_) async => doc.save(),
    );
  }

  static pw.Widget _title(String t) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Text(t, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _navy)),
  );

  // ============================================================
  // EXPORT EXCEL
  // ============================================================
  static Future<void> exporterExcel(Map<String, dynamic> r, List<Map<String, dynamic>> activites) async {
    final modules = List<Map<String, dynamic>>.from(r['repartition_modules'] ?? []);
    final pf = Map<String, dynamic>.from(r['etat_plateforme'] ?? {});

    final excel = xl.Excel.createExcel();
    excel.rename(excel.getDefaultSheet() ?? 'Sheet1', 'Résumé');

    final head = xl.CellStyle(bold: true);
    xl.TextCellValue t(String s) => xl.TextCellValue(s);
    xl.IntCellValue n(int v) => xl.IntCellValue(v);

    // ---- Feuille Résumé ----
    final s1 = excel['Résumé'];
    s1.appendRow([t('Rapport administrateur #${r['id']}')]);
    s1.appendRow([t('Période'), t('${_day(r['periode_debut'] as String?)} au ${_day(r['periode_fin'] as String?)}')]);
    s1.appendRow([t('Généré le'), t(_dateTime(r['created_at'] as String?))]);
    s1.appendRow([]);
    s1.appendRow([t('Indicateur'), t('Valeur')]);
    s1.appendRow([t('Activités totales'), n(_int(r['total_activites']))]);
    s1.appendRow([t('Actions administrateurs'), n(_int(r['activites_admin']))]);
    s1.appendRow([t('Actions responsables'), n(_int(r['activites_responsable']))]);
    s1.appendRow([t('Actions chauffeurs'), n(_int(r['activites_chauffeur']))]);
    s1.appendRow([t('Connexions'), n(_int(r['total_connexions']))]);
    s1.appendRow([t('Actions en échec'), n(_int(r['total_echecs']))]);
    if (pf.isNotEmpty) {
      s1.appendRow([]);
      s1.appendRow([t('État de la plateforme'), t('Valeur')]);
      s1.appendRow([t('Utilisateurs'), n(_int(pf['utilisateurs']))]);
      s1.appendRow([t('Camions'), n(_int(pf['camions']))]);
      s1.appendRow([t('Équipements'), n(_int(pf['equipements']))]);
      s1.appendRow([t('Alertes'), n(_int(pf['alertes']))]);
      s1.appendRow([t('Alertes résolues'), n(_int(pf['alertes_resolues']))]);
    }
    if (modules.isNotEmpty) {
      s1.appendRow([]);
      s1.appendRow([t('Module'), t('Actions')]);
      for (final m in modules) {
        s1.appendRow([t('${m['module']}'), n(_int(m['total']))]);
      }
    }
    final notes = (r['notes'] ?? '').toString();
    if (notes.isNotEmpty) {
      s1.appendRow([]);
      s1.appendRow([t('Observations'), t(notes)]);
    }
    s1.cell(xl.CellIndex.indexByString('A1')).cellStyle = head;
    s1.cell(xl.CellIndex.indexByString('A5')).cellStyle = head;
    s1.cell(xl.CellIndex.indexByString('B5')).cellStyle = head;
    s1.setColumnWidth(0, 30);
    s1.setColumnWidth(1, 30);

    // ---- Feuille Activités ----
    final s2 = excel['Activités'];
    final headers = ['Date', 'Utilisateur', 'Profil', 'Module', 'Action', 'Description', 'Statut'];
    s2.appendRow(headers.map(t).toList());
    for (var i = 0; i < headers.length; i++) {
      s2.cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = head;
    }
    for (final a in activites) {
      s2.appendRow([
        t(_dateTime(a['created_at'] as String?)),
        t('${a['user_nom'] ?? 'Système'}'),
        t(_role(a['role'])),
        t('${a['module'] ?? ''}'),
        t('${a['action'] ?? ''}'),
        t('${a['description'] ?? ''}'),
        t(a['statut'] == 'echec' ? 'Échec' : 'Succès'),
      ]);
    }
    const widths = [20.0, 24.0, 16.0, 18.0, 16.0, 60.0, 10.0];
    for (var i = 0; i < widths.length; i++) {
      s2.setColumnWidth(i, widths[i]);
    }

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Impossible de générer le fichier Excel.');

    await FileSaver.instance.saveFile(
      name: 'rapport_admin_${r['id']}',
      bytes: Uint8List.fromList(bytes),
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }
}