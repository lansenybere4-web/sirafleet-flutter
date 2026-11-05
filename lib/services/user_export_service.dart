import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

import '../models/user_model.dart';

/// Export Excel (.xlsx) sans dépendance externe.
/// Un .xlsx est un zip de fichiers XML : on l'écrit directement.
class UserExportService {
  static const _headers = [
    'ID', 'Nom', 'Prénom', 'Email', 'Téléphone', 'Adresse',
    "Site d'affectation", 'Rôle', 'Statut', 'Créé le',
    'Matricule', 'N° permis', 'Type permis', "Date d'embauche",
    'Missions (total)', 'Missions terminées', 'Missions en cours',
    'Accidents',
  ];

  static const _widths = [
    6, 18, 18, 30, 16, 26, 24, 16, 10, 20, 14, 16, 12, 16, 16, 18, 16, 10,
  ];

  static Future<void> exporter(
      List<UserModel> users, {
        String fileName = 'utilisateurs_sirafleet',
      }) async {
    final rows = <List<Object>>[
      for (final u in users)
        [
          u.id, u.nom, u.prenom, u.email, u.numTel, u.address,
          u.siteAffectation, u.role, u.statut, u.createdAt ?? '',
          u.matricule ?? '', u.permis ?? '', u.typePermis ?? '',
          u.dateEmbauche ?? '',
          u.nbMissions, u.nbMissionsTerminees, u.nbMissionsEnCours,
          u.nbAccidents,
        ],
    ];

    final bytes = _buildXlsx(_headers, rows);

    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  // ============================================================
  // XLSX
  // ============================================================

  static Uint8List _buildXlsx(List<String> headers, List<List<Object>> rows) {
    final files = <String, String>{
      '[Content_Types].xml':
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
          '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
          '<Default Extension="xml" ContentType="application/xml"/>'
          '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
          '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
          '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
          '</Types>',
      '_rels/.rels':
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
          '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
          '</Relationships>',
      'xl/workbook.xml':
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
          'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
          '<sheets><sheet name="Utilisateurs" sheetId="1" r:id="rId1"/></sheets>'
          '</workbook>',
      'xl/_rels/workbook.xml.rels':
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
          '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
          '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
          '</Relationships>',
      'xl/styles.xml':
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
          '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>'
          '<font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font></fonts>'
          '<fills count="3"><fill><patternFill patternType="none"/></fill>'
          '<fill><patternFill patternType="gray125"/></fill>'
          '<fill><patternFill patternType="solid"><fgColor rgb="FF1D3557"/><bgColor indexed="64"/></patternFill></fill></fills>'
          '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
          '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
          '<cellXfs count="2">'
          '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
          '<xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/>'
          '</cellXfs></styleSheet>',
      'xl/worksheets/sheet1.xml': _sheetXml(headers, rows),
    };

    return _zipStored(files);
  }

  static String _sheetXml(List<String> headers, List<List<Object>> rows) {
    final b = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..write('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">')
      ..write('<sheetViews><sheetView workbookViewId="0">'
          '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>'
          '</sheetView></sheetViews>')
      ..write('<cols>');

    for (var i = 0; i < _widths.length; i++) {
      b.write('<col min="${i + 1}" max="${i + 1}" width="${_widths[i]}" customWidth="1"/>');
    }
    b.write('</cols><sheetData>');

    // En-tête
    b.write('<row r="1">');
    for (var c = 0; c < headers.length; c++) {
      b.write('<c r="${_col(c)}1" t="inlineStr" s="1"><is><t>${_esc(headers[c])}</t></is></c>');
    }
    b.write('</row>');

    // Données
    for (var r = 0; r < rows.length; r++) {
      final rowNum = r + 2;
      b.write('<row r="$rowNum">');
      for (var c = 0; c < rows[r].length; c++) {
        final v = rows[r][c];
        final ref = '${_col(c)}$rowNum';
        if (v is num) {
          b.write('<c r="$ref"><v>$v</v></c>');
        } else {
          b.write('<c r="$ref" t="inlineStr"><is><t>${_esc(v.toString())}</t></is></c>');
        }
      }
      b.write('</row>');
    }

    b.write('</sheetData></worksheet>');
    return b.toString();
  }

  static String _col(int index) {
    var n = index;
    var s = '';
    do {
      s = String.fromCharCode(65 + n % 26) + s;
      n = n ~/ 26 - 1;
    } while (n >= 0);
    return s;
  }

  static String _esc(String s) {
    final cleaned = s.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
    return cleaned
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  // ============================================================
  // ZIP (sans compression) + CRC32
  // ============================================================

  static final List<int> _crcTable = () {
    final table = List<int>.filled(256, 0);
    for (var i = 0; i < 256; i++) {
      var c = i;
      for (var k = 0; k < 8; k++) {
        c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1);
      }
      table[i] = c;
    }
    return table;
  }();

  static int _crc32(List<int> data) {
    var c = 0xFFFFFFFF;
    for (final byte in data) {
      c = _crcTable[(c ^ byte) & 0xFF] ^ (c >> 8);
    }
    return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }

  static Uint8List _zipStored(Map<String, String> files) {
    final out = BytesBuilder();
    final central = BytesBuilder();
    var count = 0;

    void u16(BytesBuilder b, int v) =>
        b.add([v & 0xFF, (v >> 8) & 0xFF]);
    void u32(BytesBuilder b, int v) => b.add(
        [v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF]);

    const dosTime = 0;
    const dosDate = (46 << 9) | (1 << 5) | 1; // 01/01/2026

    files.forEach((name, content) {
      final nameBytes = utf8.encode(name);
      final data = utf8.encode(content);
      final crc = _crc32(data);
      final offset = out.length;

      // En-tête local
      u32(out, 0x04034b50);
      u16(out, 20);
      u16(out, 0x0800); // noms en UTF-8
      u16(out, 0); // méthode : stored
      u16(out, dosTime);
      u16(out, dosDate);
      u32(out, crc);
      u32(out, data.length);
      u32(out, data.length);
      u16(out, nameBytes.length);
      u16(out, 0);
      out.add(nameBytes);
      out.add(data);

      // Répertoire central
      u32(central, 0x02014b50);
      u16(central, 20);
      u16(central, 20);
      u16(central, 0x0800);
      u16(central, 0);
      u16(central, dosTime);
      u16(central, dosDate);
      u32(central, crc);
      u32(central, data.length);
      u32(central, data.length);
      u16(central, nameBytes.length);
      u16(central, 0);
      u16(central, 0);
      u16(central, 0);
      u16(central, 0);
      u32(central, 0);
      u32(central, offset);
      central.add(nameBytes);

      count++;
    });

    final centralOffset = out.length;
    final centralBytes = central.toBytes();
    out.add(centralBytes);

    // Fin du répertoire central
    u32(out, 0x06054b50);
    u16(out, 0);
    u16(out, 0);
    u16(out, count);
    u16(out, count);
    u32(out, centralBytes.length);
    u32(out, centralOffset);
    u16(out, 0);

    return out.toBytes();
  }
}