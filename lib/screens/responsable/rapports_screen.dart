/*import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/rapport_activite_service.dart';
import '../../services/rapport_mission_service.dart';
import '../../widgets/sidebar_responsable.dart';

class RapportsScreen extends StatefulWidget {
  const RapportsScreen({super.key});

  @override
  State<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends State<RapportsScreen> {
  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF059669);
  static const Color dangerColor = Color(0xFFDC2626);
  static const Color warningColor = Color(0xFFD97706);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color borderColor = Color(0xFFE5E7EB);

  String _selectedPeriod = 'Journalier';
  DateTime _periodeDebut = DateTime.now();
  DateTime _periodeFin = DateTime.now();

  bool _isGenerating = false;
  bool _isLoadingRapports = true;

  List<Map<String, dynamic>> _rapportsRecus = [];
  Map<String, dynamic>? _dernierRapportActivite;
  List<Map<String, dynamic>> _rapportsInclusDernierRapport = [];

  final List<String> _periods = [
    'Journalier',
    'Hebdomadaire',
    'Mensuel',
    'Annuel',
  ];

  @override
  void initState() {
    super.initState();
    _appliquerPeriode(_selectedPeriod);
    _chargerRapportsRecus();
  }

  // ============================================================
  // CHARGEMENT DES RAPPORTS CHAUFFEURS (réels, depuis l'API)
  // ============================================================

  Future<void> _chargerRapportsRecus() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() => _isLoadingRapports = true);

    try {
      final service = RapportMissionService(token: token);
      final rapports = await service.listerRapports();

      if (!mounted) return;
      setState(() {
        _rapportsRecus = rapports;
        _isLoadingRapports = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingRapports = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement des rapports : ${_cleanError(e)}'),
          backgroundColor: dangerColor,
        ),
      );
    }
  }

  String _cleanError(Object e) {
    final m = e.toString();
    return m.startsWith('Exception: ') ? m.substring('Exception: '.length) : m;
  }

  void _appliquerPeriode(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'Journalier':
        _periodeDebut = DateTime(now.year, now.month, now.day);
        _periodeFin = _periodeDebut;
        break;
      case 'Hebdomadaire':
        _periodeDebut = now.subtract(Duration(days: now.weekday - 1));
        _periodeFin = _periodeDebut.add(const Duration(days: 6));
        break;
      case 'Mensuel':
        _periodeDebut = DateTime(now.year, now.month, 1);
        _periodeFin = DateTime(now.year, now.month + 1, 0);
        break;
      case 'Annuel':
        _periodeDebut = DateTime(now.year, 1, 1);
        _periodeFin = DateTime(now.year, 12, 31);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          const ResponsableSidebar(current: ResponsableMenuItem.rapports),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _chargerRapportsRecus,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      child: _buildContent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bar_chart_rounded, color: primaryColor, size: 23),
          const SizedBox(width: 10),
          const Text(
            'Rapports',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _chargerRapportsRecus,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF374151)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(),
        const SizedBox(height: 24),
        _buildFilters(),
        const SizedBox(height: 24),
        _buildRapportsRecusSection(),
        const SizedBox(height: 24),
        if (_dernierRapportActivite != null) _buildDernierRapportGenere(),
      ],
    );
  }

  Widget _buildPageHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rapports de la flotte',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Consultez les rapports envoyés par vos chauffeurs et générez votre rapport d\'activité.',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        ),
      ],
    );
  }

  // ============================================================
  // FILTRES DE PÉRIODE + GÉNÉRATION
  // ============================================================

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 700;

          final periodDropdown = DropdownButtonFormField<String>(
            initialValue: _selectedPeriod,
            decoration: InputDecoration(
              labelText: 'Période du rapport',
              prefixIcon: const Icon(Icons.calendar_month_rounded, color: primaryColor),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            items: _periods
                .map((p) => DropdownMenuItem<String>(value: p, child: Text(p)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedPeriod = value;
                _appliquerPeriode(value);
              });
            },
          );

          final dateLabel = Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range_rounded, color: primaryColor, size: 20),
                const SizedBox(width: 10),
                Text(
                  '${DateFormat('dd/MM/yyyy').format(_periodeDebut)}  →  ${DateFormat('dd/MM/yyyy').format(_periodeFin)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );

          if (narrow) {
            return Column(
              children: [
                periodDropdown,
                const SizedBox(height: 12),
                dateLabel,
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: _buildGenerateButton()),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: periodDropdown),
              const SizedBox(width: 15),
              Expanded(child: dateLabel),
              const SizedBox(width: 15),
              _buildGenerateButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      height: 55,
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : _genererRapportActivite,
        icon: _isGenerating
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : const Icon(Icons.analytics_rounded),
        label: Text(_isGenerating ? 'Génération...' : 'Générer mon rapport'),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Future<void> _genererRapportActivite() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() => _isGenerating = true);

    try {
      final service = RapportActiviteService(token: token);
      final resultat = await service.generer(
        periodeType: _selectedPeriod.toLowerCase() == 'journalier'
            ? 'journalier'
            : _selectedPeriod.toLowerCase() == 'hebdomadaire'
            ? 'hebdomadaire'
            : _selectedPeriod.toLowerCase() == 'mensuel'
            ? 'mensuel'
            : 'annuel',
        periodeDebut: _periodeDebut,
        periodeFin: _periodeFin,
      );

      if (!mounted) return;

      final rapportsInclus = (resultat['rapports_missions'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList() ??
          [];

      setState(() {
        _dernierRapportActivite = Map<String, dynamic>.from(resultat['data']);
        _rapportsInclusDernierRapport = rapportsInclus;
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resultat['message']?.toString() ??
                'Rapport $_selectedPeriod généré et enregistré avec succès.',
          ),
          backgroundColor: accentColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${_cleanError(e)}'),
          backgroundColor: dangerColor,
        ),
      );
    }
  }

  // ============================================================
  // RAPPORTS REÇUS DES CHAUFFEURS (boîte de réception)
  // ============================================================

  Widget _buildRapportsRecusSection() {
    return _buildSectionCard(
      title: 'Rapports reçus des chauffeurs',
      icon: Icons.inbox_rounded,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${_rapportsRecus.length}',
          style: const TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      child: _isLoadingRapports
          ? const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(child: CircularProgressIndicator()),
      )
          : _rapportsRecus.isEmpty
          ? Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(
            'Aucun rapport de mission reçu pour le moment.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      )
          : Column(
        children: _rapportsRecus
            .map((rapport) => _buildRapportRecuTile(rapport))
            .toList(),
      ),
    );
  }

  Widget _buildRapportRecuTile(Map<String, dynamic> rapport) {
    final mission = rapport['mission'] as Map<String, dynamic>?;
    final chauffeur = rapport['chauffeur'] as Map<String, dynamic>?;
    final user = chauffeur?['user'] as Map<String, dynamic>?;

    final nomChauffeur = user != null
        ? '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim()
        : 'Chauffeur';

    final etat = rapport['etat_camion']?.toString() ?? 'RAS';
    final incident = rapport['incident_signale'] == true;

    final Color etatColor = etat == 'Problème signalé'
        ? dangerColor
        : etat == 'À vérifier'
        ? warningColor
        : accentColor;

    final dateStr = rapport['created_at']?.toString();
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: etatColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            incident ? Icons.warning_amber_rounded : Icons.description_rounded,
            color: etatColor,
          ),
        ),
        title: Text(
          'Mission #${mission?['id'] ?? '—'} — ${mission?['origine'] ?? ''} → ${mission?['destination'] ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '$nomChauffeur • ${rapport['distance_reelle']} km • Carburant ${rapport['niveau_carburant']}%'
                '${date != null ? ' • ${DateFormat('dd/MM/yyyy HH:mm').format(date)}' : ''}',
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: etatColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                etat,
                style: TextStyle(
                  color: etatColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.5,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Voir / Imprimer',
              icon: const Icon(Icons.print_outlined, color: primaryColor, size: 20),
              onPressed: () => _imprimerRapportUnique(rapport),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DERNIER RAPPORT D'ACTIVITÉ GÉNÉRÉ
  // ============================================================

  Widget _buildDernierRapportGenere() {
    final r = _dernierRapportActivite!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_rounded, color: Colors.white),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Rapport d\'activité généré',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Période du ${r['periode_debut']} au ${r['periode_fin']} — '
                '${r['total_missions']} missions, ${r['distance_totale']} km, '
                '${r['total_incidents']} incident(s). Inclut ${_rapportsInclusDernierRapport.length} rapport(s) chauffeur.',
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _imprimerRapportActivite,
            icon: const Icon(Icons.print_rounded),
            label: const Text('Imprimer le rapport d\'activité'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // IMPRESSION D'UN RAPPORT CHAUFFEUR UNIQUE
  // ============================================================

  Future<void> _imprimerRapportUnique(Map<String, dynamic> rapport) async {
    final mission = rapport['mission'] as Map<String, dynamic>?;
    final chauffeur = rapport['chauffeur'] as Map<String, dynamic>?;
    final user = chauffeur?['user'] as Map<String, dynamic>?;
    final nomChauffeur = user != null
        ? '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim()
        : 'Chauffeur';

    final doc = pw.Document();
    final pdfPrimary = PdfColor.fromInt(0xFF1D3557);
    final pdfGrey = PdfColor.fromInt(0xFF6B7280);
    final pdfBorder = PdfColor.fromInt(0xFFE2E8F0);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('RAPPORT DE MISSION',
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold, color: pdfPrimary)),
            pw.SizedBox(height: 4),
            pw.Text('Mission #${mission?['id'] ?? '—'}',
                style: pw.TextStyle(fontSize: 10, color: pdfGrey)),
            pw.SizedBox(height: 14),
            pw.Table(
              border: pw.TableBorder.all(color: pdfBorder, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.3),
                1: const pw.FlexColumnWidth(2.5),
              },
              children: [
                ['Chauffeur', nomChauffeur],
                ['Trajet', '${mission?['origine'] ?? ''} -> ${mission?['destination'] ?? ''}'],
                ['Distance réelle', '${rapport['distance_reelle']} km'],
                ['Carburant restant', '${rapport['niveau_carburant']}%'],
                ['État du camion', '${rapport['etat_camion']}'],
                ['Incident', rapport['incident_signale'] == true
                    ? (rapport['incident_description'] ?? 'Signalé').toString()
                    : 'Aucun'],
                ['Remarque', (rapport['commentaire']?.toString().isNotEmpty == true)
                    ? rapport['commentaire'].toString()
                    : '—'],
              ]
                  .map((row) => pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(row[0], style: pw.TextStyle(fontSize: 9, color: pdfGrey)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(row[1],
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ),
              ]))
                  .toList(),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  // ============================================================
  // IMPRESSION DU RAPPORT D'ACTIVITÉ CONSOLIDÉ (RESPONSABLE)
  // ============================================================

  Future<void> _imprimerRapportActivite() async {
    final r = _dernierRapportActivite;
    if (r == null) return;

    final currentUser = context.read<AuthProvider>().user;
    final nomResponsable = currentUser != null
        ? '${currentUser.prenom} ${currentUser.nom}'.trim()
        : 'Responsable de flotte';

    final doc = pw.Document();
    final pdfPrimary = PdfColor.fromInt(0xFF1D3557);
    final pdfAccent = PdfColor.fromInt(0xFF059669);
    final pdfGrey = PdfColor.fromInt(0xFF6B7280);
    final pdfBorder = PdfColor.fromInt(0xFFE2E8F0);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('SiraFleet', style: pw.TextStyle(fontSize: 10, color: pdfGrey)),
                    pw.Text('RAPPORT D\'ACTIVITÉ DE LA FLOTTE',
                        style: pw.TextStyle(
                            fontSize: 17, fontWeight: pw.FontWeight.bold, color: pdfPrimary)),
                  ],
                ),
                pw.Text(
                  'Période : ${r['periode_debut']} au ${r['periode_fin']}',
                  style: pw.TextStyle(fontSize: 10, color: pdfGrey),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: pdfBorder),
            pw.SizedBox(height: 10),
          ],
        ),
        build: (context) => [
          pw.Text('SYNTHÈSE',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: pdfPrimary)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: pdfBorder, width: 0.5),
            children: [
              ['Total missions', '${r['total_missions']}'],
              ['Missions terminées', '${r['missions_terminees']}'],
              ['Missions en cours', '${r['missions_en_cours']}'],
              ['Missions annulées', '${r['missions_annulees']}'],
              ['Distance totale parcourue', '${r['distance_totale']} km'],
              ['Total incidents signalés', '${r['total_incidents']}'],
            ]
                .map((row) => pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(row[0], style: pw.TextStyle(fontSize: 9, color: pdfGrey)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(row[1],
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ),
            ]))
                .toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Text('RAPPORTS DE MISSION INCLUS (${_rapportsInclusDernierRapport.length})',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: pdfPrimary)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: pdfBorder, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.6),
              1: const pw.FlexColumnWidth(1.4),
              2: const pw.FlexColumnWidth(1.4),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F4F6)),
                children: ['Mission', 'Chauffeur', 'Trajet', 'Distance', 'État']
                    .map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(h,
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                ))
                    .toList(),
              ),
              ..._rapportsInclusDernierRapport.map((rapport) {
                final mission = rapport['mission'] as Map<String, dynamic>?;
                final chauffeur = rapport['chauffeur'] as Map<String, dynamic>?;
                final user = chauffeur?['user'] as Map<String, dynamic>?;
                final nom =
                user != null ? '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim() : '—';

                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('#${mission?['id'] ?? '—'}', style: const pw.TextStyle(fontSize: 8.5)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(nom, style: const pw.TextStyle(fontSize: 8.5)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        '${mission?['origine'] ?? ''} -> ${mission?['destination'] ?? ''}',
                        style: const pw.TextStyle(fontSize: 8.5),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('${rapport['distance_reelle']} km',
                          style: const pw.TextStyle(fontSize: 8.5)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('${rapport['etat_camion']}',
                          style: const pw.TextStyle(fontSize: 8.5)),
                    ),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Divider(color: pdfBorder),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Rapport établi par', style: pw.TextStyle(fontSize: 9, color: pdfGrey)),
                  pw.Text(nomResponsable,
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Text('Signature : ____________________',
                  style: pw.TextStyle(fontSize: 10, color: pdfGrey)),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 15),
          const Divider(color: borderColor),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
*/


import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/rapport_activite_service.dart';
import '../../services/rapport_mission_service.dart';
import '../../widgets/sidebar_responsable.dart';

class RapportsScreen extends StatefulWidget {
  const RapportsScreen({super.key});

  @override
  State<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends State<RapportsScreen> {
  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF059669);
  static const Color dangerColor = Color(0xFFDC2626);
  static const Color warningColor = Color(0xFFD97706);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color borderColor = Color(0xFFE5E7EB);

  String _selectedPeriod = 'Journalier';
  DateTime _periodeDebut = DateTime.now();
  DateTime _periodeFin = DateTime.now();

  bool _isGenerating = false;
  bool _isLoadingRapports = true;

  List<Map<String, dynamic>> _rapportsRecus = [];
  Map<String, dynamic>? _dernierRapportActivite;
  List<Map<String, dynamic>> _rapportsInclusDernierRapport = [];

  final List<String> _periods = [
    'Journalier',
    'Hebdomadaire',
    'Mensuel',
    'Annuel',
  ];

  @override
  void initState() {
    super.initState();
    _appliquerPeriode(_selectedPeriod);
    _chargerRapportsRecus();
  }

  // ============================================================
  // CHARGEMENT DES RAPPORTS CHAUFFEURS (réels, depuis l'API)
  // ============================================================

  Future<void> _chargerRapportsRecus() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() => _isLoadingRapports = true);

    try {
      final service = RapportMissionService(token: token);
      final rapports = await service.listerRapports();

      if (!mounted) return;
      setState(() {
        _rapportsRecus = rapports;
        _isLoadingRapports = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingRapports = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement des rapports : ${_cleanError(e)}'),
          backgroundColor: dangerColor,
        ),
      );
    }
  }

  String _cleanError(Object e) {
    final m = e.toString();
    return m.startsWith('Exception: ') ? m.substring('Exception: '.length) : m;
  }

  void _appliquerPeriode(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'Journalier':
        _periodeDebut = DateTime(now.year, now.month, now.day);
        _periodeFin = _periodeDebut;
        break;
      case 'Hebdomadaire':
        _periodeDebut = now.subtract(Duration(days: now.weekday - 1));
        _periodeFin = _periodeDebut.add(const Duration(days: 6));
        break;
      case 'Mensuel':
        _periodeDebut = DateTime(now.year, now.month, 1);
        _periodeFin = DateTime(now.year, now.month + 1, 0);
        break;
      case 'Annuel':
        _periodeDebut = DateTime(now.year, 1, 1);
        _periodeFin = DateTime(now.year, 12, 31);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          const ResponsableSidebar(current: ResponsableMenuItem.rapports),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _chargerRapportsRecus,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      child: _buildContent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bar_chart_rounded, color: primaryColor, size: 23),
          const SizedBox(width: 10),
          const Text(
            'Rapports',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _chargerRapportsRecus,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF374151)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(),
        const SizedBox(height: 24),
        _buildFilters(),
        const SizedBox(height: 24),
        _buildRapportsRecusSection(),
        const SizedBox(height: 24),
        if (_dernierRapportActivite != null) _buildDernierRapportGenere(),
      ],
    );
  }

  Widget _buildPageHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rapports de la flotte',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Consultez les rapports envoyés par vos chauffeurs et générez votre rapport d\'activité.',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        ),
      ],
    );
  }

  // ============================================================
  // FILTRES DE PÉRIODE + GÉNÉRATION
  // ============================================================

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 700;

          final periodDropdown = DropdownButtonFormField<String>(
            initialValue: _selectedPeriod,
            decoration: InputDecoration(
              labelText: 'Période du rapport',
              prefixIcon: const Icon(Icons.calendar_month_rounded, color: primaryColor),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            items: _periods
                .map((p) => DropdownMenuItem<String>(value: p, child: Text(p)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedPeriod = value;
                _appliquerPeriode(value);
              });
            },
          );

          final dateLabel = Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range_rounded, color: primaryColor, size: 20),
                const SizedBox(width: 10),
                Text(
                  '${DateFormat('dd/MM/yyyy').format(_periodeDebut)}  →  ${DateFormat('dd/MM/yyyy').format(_periodeFin)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );

          if (narrow) {
            return Column(
              children: [
                periodDropdown,
                const SizedBox(height: 12),
                dateLabel,
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: _buildGenerateButton()),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: periodDropdown),
              const SizedBox(width: 15),
              Expanded(child: dateLabel),
              const SizedBox(width: 15),
              _buildGenerateButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      height: 55,
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : _genererRapportActivite,
        icon: _isGenerating
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : const Icon(Icons.analytics_rounded),
        label: Text(_isGenerating ? 'Génération...' : 'Générer mon rapport'),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Future<void> _genererRapportActivite() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() => _isGenerating = true);

    try {
      final service = RapportActiviteService(token: token);
      final resultat = await service.generer(
        periodeType: _selectedPeriod.toLowerCase() == 'journalier'
            ? 'journalier'
            : _selectedPeriod.toLowerCase() == 'hebdomadaire'
            ? 'hebdomadaire'
            : _selectedPeriod.toLowerCase() == 'mensuel'
            ? 'mensuel'
            : 'annuel',
        periodeDebut: _periodeDebut,
        periodeFin: _periodeFin,
      );

      if (!mounted) return;

      final rapportsInclus = (resultat['rapports_missions'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList() ??
          [];

      setState(() {
        _dernierRapportActivite = Map<String, dynamic>.from(resultat['data']);
        _rapportsInclusDernierRapport = rapportsInclus;
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resultat['message']?.toString() ??
                'Rapport $_selectedPeriod généré et enregistré avec succès.',
          ),
          backgroundColor: accentColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${_cleanError(e)}'),
          backgroundColor: dangerColor,
        ),
      );
    }
  }

  // ============================================================
  // RAPPORTS REÇUS DES CHAUFFEURS (boîte de réception)
  // ============================================================

  Widget _buildRapportsRecusSection() {
    return _buildSectionCard(
      title: 'Rapports reçus des chauffeurs',
      icon: Icons.inbox_rounded,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${_rapportsRecus.length}',
          style: const TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      child: _isLoadingRapports
          ? const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(child: CircularProgressIndicator()),
      )
          : _rapportsRecus.isEmpty
          ? Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(
            'Aucun rapport de mission reçu pour le moment.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      )
          : Column(
        children: _rapportsRecus
            .map((rapport) => _buildRapportRecuTile(rapport))
            .toList(),
      ),
    );
  }

  Widget _buildRapportRecuTile(Map<String, dynamic> rapport) {
    final mission = rapport['mission'] as Map<String, dynamic>?;
    final chauffeur = rapport['chauffeur'] as Map<String, dynamic>?;
    final user = chauffeur?['user'] as Map<String, dynamic>?;

    final nomChauffeur = user != null
        ? '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim()
        : 'Chauffeur';

    final etat = rapport['etat_camion']?.toString() ?? 'RAS';
    final incident = rapport['incident_signale'] == true;
    final photosUrls = (rapport['photos_urls'] as List?)
        ?.map((e) => e.toString())
        .toList() ??
        [];

    final Color etatColor = etat == 'Problème signalé'
        ? dangerColor
        : etat == 'À vérifier'
        ? warningColor
        : accentColor;

    final dateStr = rapport['created_at']?.toString();
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: etatColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            incident ? Icons.warning_amber_rounded : Icons.description_rounded,
            color: etatColor,
          ),
        ),
        title: Text(
          'Mission #${mission?['id'] ?? '—'} — ${mission?['origine'] ?? ''} → ${mission?['destination'] ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '$nomChauffeur • ${rapport['distance_reelle']} km • Carburant ${rapport['niveau_carburant']}%'
                '${date != null ? ' • ${DateFormat('dd/MM/yyyy HH:mm').format(date)}' : ''}',
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (photosUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_camera_outlined, size: 12, color: primaryColor),
                      const SizedBox(width: 3),
                      Text('${photosUrls.length}',
                          style: const TextStyle(
                              color: primaryColor, fontWeight: FontWeight.bold, fontSize: 10.5)),
                    ],
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: etatColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                etat,
                style: TextStyle(
                  color: etatColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.5,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Voir / Imprimer',
              icon: const Icon(Icons.print_outlined, color: primaryColor, size: 20),
              onPressed: () => _imprimerRapportUnique(rapport),
            ),
          ],
        ),
        onTap: photosUrls.isEmpty ? null : () => _voirPhotosRapport(context, photosUrls),
      ),
    );
  }

  // ============================================================
  // DERNIER RAPPORT D'ACTIVITÉ GÉNÉRÉ
  // ============================================================

  Widget _buildDernierRapportGenere() {
    final r = _dernierRapportActivite!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_rounded, color: Colors.white),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Rapport d\'activité généré',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Période du ${r['periode_debut']} au ${r['periode_fin']} — '
                '${r['total_missions']} missions, ${r['distance_totale']} km, '
                '${r['total_incidents']} incident(s). Inclut ${_rapportsInclusDernierRapport.length} rapport(s) chauffeur.',
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _imprimerRapportActivite,
            icon: const Icon(Icons.print_rounded),
            label: const Text('Imprimer le rapport d\'activité'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // IMPRESSION D'UN RAPPORT CHAUFFEUR UNIQUE
  // ============================================================

  // ============================================================
  // VISIONNEUSE DE PHOTOS JOINTES PAR LE CHAUFFEUR
  // ============================================================

  void _voirPhotosRapport(BuildContext context, List<String> photosUrls) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.photo_library_outlined, color: primaryColor),
                      const SizedBox(width: 8),
                      Text('Photos jointes (${photosUrls.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: photosUrls.length,
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            photosUrls[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: backgroundColor,
                              child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _imprimerRapportUnique(Map<String, dynamic> rapport) async {
    final mission = rapport['mission'] as Map<String, dynamic>?;
    final chauffeur = rapport['chauffeur'] as Map<String, dynamic>?;
    final user = chauffeur?['user'] as Map<String, dynamic>?;
    final nomChauffeur = user != null
        ? '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim()
        : 'Chauffeur';

    final photosUrls = (rapport['photos_urls'] as List?)
        ?.map((e) => e.toString())
        .toList() ??
        [];

    // Télécharge les photos jointes par le chauffeur pour les intégrer au PDF.
    final photoImages = <pw.MemoryImage>[];
    for (final url in photosUrls) {
      try {
        final resp = await http.get(Uri.parse(url));
        if (resp.statusCode == 200) {
          photoImages.add(pw.MemoryImage(resp.bodyBytes));
        }
      } catch (_) {
        // On ignore une photo qui échoue à charger, sans bloquer l'impression.
      }
    }

    final doc = pw.Document();
    final pdfPrimary = PdfColor.fromInt(0xFF1D3557);
    final pdfGrey = PdfColor.fromInt(0xFF6B7280);
    final pdfBorder = PdfColor.fromInt(0xFFE2E8F0);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text('RAPPORT DE MISSION',
              style: pw.TextStyle(
                  fontSize: 18, fontWeight: pw.FontWeight.bold, color: pdfPrimary)),
          pw.SizedBox(height: 4),
          pw.Text('Mission #${mission?['id'] ?? '—'}',
              style: pw.TextStyle(fontSize: 10, color: pdfGrey)),
          pw.SizedBox(height: 14),
          pw.Table(
            border: pw.TableBorder.all(color: pdfBorder, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.3),
              1: const pw.FlexColumnWidth(2.5),
            },
            children: [
              ['Chauffeur', nomChauffeur],
              ['Trajet', '${mission?['origine'] ?? ''} -> ${mission?['destination'] ?? ''}'],
              ['Distance réelle', '${rapport['distance_reelle']} km'],
              ['Carburant restant', '${rapport['niveau_carburant']}%'],
              ['État du camion', '${rapport['etat_camion']}'],
              ['Incident', rapport['incident_signale'] == true
                  ? (rapport['incident_description'] ?? 'Signalé').toString()
                  : 'Aucun'],
              ['Remarque', (rapport['commentaire']?.toString().isNotEmpty == true)
                  ? rapport['commentaire'].toString()
                  : '—'],
            ]
                .map((row) => pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(row[0], style: pw.TextStyle(fontSize: 9, color: pdfGrey)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(row[1],
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ),
            ]))
                .toList(),
          ),
          if (photoImages.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text('PIÈCES JOINTES (${photoImages.length})',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: pdfPrimary)),
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: photoImages
                  .map((img) => pw.Container(
                width: 140,
                height: 140,
                decoration: pw.BoxDecoration(border: pw.Border.all(color: pdfBorder)),
                child: pw.Image(img, fit: pw.BoxFit.cover),
              ))
                  .toList(),
            ),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  // ============================================================
  // IMPRESSION DU RAPPORT D'ACTIVITÉ CONSOLIDÉ (RESPONSABLE)
  // ============================================================

  Future<void> _imprimerRapportActivite() async {
    final r = _dernierRapportActivite;
    if (r == null) return;

    final currentUser = context.read<AuthProvider>().user;
    final nomResponsable = currentUser != null
        ? '${currentUser.prenom} ${currentUser.nom}'.trim()
        : 'Responsable de flotte';

    final doc = pw.Document();
    final pdfPrimary = PdfColor.fromInt(0xFF1D3557);
    final pdfAccent = PdfColor.fromInt(0xFF059669);
    final pdfGrey = PdfColor.fromInt(0xFF6B7280);
    final pdfBorder = PdfColor.fromInt(0xFFE2E8F0);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('SiraFleet', style: pw.TextStyle(fontSize: 10, color: pdfGrey)),
                    pw.Text('RAPPORT D\'ACTIVITÉ DE LA FLOTTE',
                        style: pw.TextStyle(
                            fontSize: 17, fontWeight: pw.FontWeight.bold, color: pdfPrimary)),
                  ],
                ),
                pw.Text(
                  'Période : ${r['periode_debut']} au ${r['periode_fin']}',
                  style: pw.TextStyle(fontSize: 10, color: pdfGrey),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: pdfBorder),
            pw.SizedBox(height: 10),
          ],
        ),
        build: (context) => [
          pw.Text('SYNTHÈSE',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: pdfPrimary)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: pdfBorder, width: 0.5),
            children: [
              ['Total missions', '${r['total_missions']}'],
              ['Missions terminées', '${r['missions_terminees']}'],
              ['Missions en cours', '${r['missions_en_cours']}'],
              ['Missions annulées', '${r['missions_annulees']}'],
              ['Distance totale parcourue', '${r['distance_totale']} km'],
              ['Total incidents signalés', '${r['total_incidents']}'],
            ]
                .map((row) => pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(row[0], style: pw.TextStyle(fontSize: 9, color: pdfGrey)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(row[1],
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ),
            ]))
                .toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Text('RAPPORTS DE MISSION INCLUS (${_rapportsInclusDernierRapport.length})',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: pdfPrimary)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: pdfBorder, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.6),
              1: const pw.FlexColumnWidth(1.4),
              2: const pw.FlexColumnWidth(1.4),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F4F6)),
                children: ['Mission', 'Chauffeur', 'Trajet', 'Distance', 'État']
                    .map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(h,
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                ))
                    .toList(),
              ),
              ..._rapportsInclusDernierRapport.map((rapport) {
                final mission = rapport['mission'] as Map<String, dynamic>?;
                final chauffeur = rapport['chauffeur'] as Map<String, dynamic>?;
                final user = chauffeur?['user'] as Map<String, dynamic>?;
                final nom =
                user != null ? '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim() : '—';

                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('#${mission?['id'] ?? '—'}', style: const pw.TextStyle(fontSize: 8.5)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(nom, style: const pw.TextStyle(fontSize: 8.5)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        '${mission?['origine'] ?? ''} -> ${mission?['destination'] ?? ''}',
                        style: const pw.TextStyle(fontSize: 8.5),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('${rapport['distance_reelle']} km',
                          style: const pw.TextStyle(fontSize: 8.5)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('${rapport['etat_camion']}',
                          style: const pw.TextStyle(fontSize: 8.5)),
                    ),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Divider(color: pdfBorder),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Rapport établi par', style: pw.TextStyle(fontSize: 9, color: pdfGrey)),
                  pw.Text(nomResponsable,
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Text('Signature : ____________________',
                  style: pw.TextStyle(fontSize: 10, color: pdfGrey)),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 15),
          const Divider(color: borderColor),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
