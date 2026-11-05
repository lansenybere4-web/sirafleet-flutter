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
  // ============================================================
  // COULEURS
  // ============================================================

  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF059669);
  static const Color dangerColor = Color(0xFFDC2626);
  static const Color warningColor = Color(0xFFD97706);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color inkColor = Color(0xFF1F2937);
  static const Color mutedColor = Color(0xFF6B7280);

  // ============================================================
  // ETAT
  // ============================================================

  // Génération du rapport d'activité
  String _selectedPeriod = 'Journalier';
  DateTime _periodeDebut = DateTime.now();
  DateTime _periodeFin = DateTime.now();
  bool _isGenerating = false;

  // Rapports reçus des chauffeurs
  bool _isLoadingRapports = true;
  List<Map<String, dynamic>> _rapportsRecus = [];

  // Filtres de la boîte de réception
  final TextEditingController _searchController = TextEditingController();
  String _filtreEtat = 'Tous';
  bool _seulementIncidents = false;

  // Historique des rapports d'activité générés
  final List<Map<String, dynamic>> _historiqueActivite = [];

  final List<String> _periods = [
    'Journalier',
    'Hebdomadaire',
    'Mensuel',
    'Annuel',
  ];

  final List<String> _filtresEtat = [
    'Tous',
    'RAS',
    'À vérifier',
    'Problème signalé',
  ];

  @override
  void initState() {
    super.initState();
    _appliquerPeriode(_selectedPeriod);
    _chargerRapportsRecus();
    _chargerHistorique();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // OUTILS
  // ============================================================

  String _txt(dynamic v, [String fallback = '—']) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  Map<String, dynamic>? _map(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : null;

  List<Map<String, dynamic>> _liste(dynamic v) {
    if (v is! List) return [];
    return v
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  DateTime? _date(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString())?.toLocal();
  }

  double? _num(dynamic v) {
    if (v == null) return null;
    return double.tryParse(v.toString().replaceAll(',', '.'));
  }

  String _jour(dynamic v) {
    if (v == null) return '—';
    final d = DateTime.tryParse(v.toString());
    return d == null ? _txt(v) : DateFormat('dd/MM/yyyy').format(d);
  }

  String _fcfa(dynamic v) {
    final n = _num(v) ?? 0;
    return '${NumberFormat('#,##0', 'fr_FR').format(n)} FCFA';
  }

  String _cleanError(Object e) {
    final m = e.toString();
    return m.startsWith('Exception: ') ? m.substring('Exception: '.length) : m;
  }

  String _nomChauffeur(Map<String, dynamic> rapport) {
    final chauffeur = _map(rapport['chauffeur']);
    final user = _map(chauffeur?['user']);
    if (user == null) return 'Chauffeur';
    final nom = '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim();
    return nom.isEmpty ? 'Chauffeur' : nom;
  }

  String _matricule(Map<String, dynamic> rapport) {
    final mission = _map(rapport['mission']);
    final camionObj = _map(mission?['camion']);
    if (camionObj != null) {
      return _txt(camionObj['matricule'] ?? camionObj['immatriculation']);
    }
    return _txt(mission?['camion']);
  }

  String _numero(Map<String, dynamic> rapport) {
    final id = _txt(rapport['id'], '0');
    final d = _date(rapport['created_at']) ?? DateTime.now();
    return 'RM-${DateFormat('yyMMdd').format(d)}-${id.padLeft(4, '0')}';
  }

  List<String> _photos(Map<String, dynamic> rapport) {
    return (rapport['photos_urls'] as List?)?.map((e) => e.toString()).toList() ??
        [];
  }

  Color _etatColor(String etat) {
    switch (etat) {
      case 'Problème signalé':
        return dangerColor;
      case 'À vérifier':
        return warningColor;
      default:
        return accentColor;
    }
  }

  IconData _etatIcon(String etat) {
    switch (etat) {
      case 'Problème signalé':
        return Icons.error_outline_rounded;
      case 'À vérifier':
        return Icons.warning_amber_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  String _etatDescription(String etat) {
    switch (etat) {
      case 'Problème signalé':
        return 'Une intervention est nécessaire sur le véhicule.';
      case 'À vérifier':
        return 'Un contrôle est recommandé au dépôt.';
      default:
        return 'Aucun problème constaté par le chauffeur.';
    }
  }

  Color _fuelColor(num pct) {
    if (pct < 20) return dangerColor;
    if (pct < 50) return warningColor;
    return accentColor;
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

  List<Map<String, dynamic>> get _rapportsFiltres {
    final q = _searchController.text.trim().toLowerCase();

    return _rapportsRecus.where((r) {
      final etat = _txt(r['etat_camion'], 'RAS');
      if (_filtreEtat != 'Tous' && etat != _filtreEtat) return false;
      if (_seulementIncidents && r['incident_signale'] != true) return false;

      if (q.isNotEmpty) {
        final mission = _map(r['mission']);
        final haystack = [
          _nomChauffeur(r),
          _matricule(r),
          _txt(mission?['id'], ''),
          _txt(mission?['origine'], ''),
          _txt(mission?['destination'], ''),
          _numero(r),
        ].join(' ').toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();
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
      _snack('Erreur de chargement des rapports : ${_cleanError(e)}', dangerColor);
    }
  }

  void _snack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

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
                fontSize: 20, fontWeight: FontWeight.bold, color: inkColor),
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
        const SizedBox(height: 22),
        _buildKpis(),
        const SizedBox(height: 24),
        _buildRapportsRecusSection(),
        const SizedBox(height: 24),
        _buildMesRapportsSection(),
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
              fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
        ),
        SizedBox(height: 6),
        Text(
          'Consultez le détail des rapports envoyés par vos chauffeurs et générez vos rapports d\'activité.',
          style: TextStyle(color: mutedColor, fontSize: 14),
        ),
      ],
    );
  }

  // ============================================================
  // KPI
  // ============================================================

  Widget _buildKpis() {
    final total = _rapportsRecus.length;
    final incidents =
        _rapportsRecus.where((r) => r['incident_signale'] == true).length;
    final aControler =
        _rapportsRecus.where((r) => _txt(r['etat_camion'], 'RAS') != 'RAS').length;
    final distance = _rapportsRecus.fold<double>(
        0, (sum, r) => sum + (_num(r['distance_reelle']) ?? 0));

    final tiles = [
      _kpiTile(Icons.inbox_rounded, 'Rapports reçus', '$total', primaryColor),
      _kpiTile(Icons.report_problem_outlined, 'Avec incident', '$incidents',
          dangerColor),
      _kpiTile(Icons.build_circle_outlined, 'Véhicules à contrôler',
          '$aControler', warningColor),
      _kpiTile(Icons.route_rounded, 'Distance cumulée',
          '${distance.toStringAsFixed(1)} km', accentColor),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w >= 900 ? 4 : (w >= 500 ? 2 : 1);
        const spacing = 14.0;
        final itemWidth = (w - spacing * (cols - 1)) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: tiles
              .map((t) => SizedBox(width: itemWidth, child: t))
              .toList(),
        );
      },
    );
  }

  Widget _kpiTile(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D3557).withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_outward_rounded,
                size: 17,
                color: Colors.grey.shade400,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: Color(0xFF1D3557),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RAPPORTS REÇUS DES CHAUFFEURS
  // ============================================================

  Widget _buildRapportsRecusSection() {
    final filtres = _rapportsFiltres;

    return _buildSectionCard(
      title: 'Rapports reçus des chauffeurs',
      icon: Icons.inbox_rounded,
      trailing: _countBadge(
        filtres.length == _rapportsRecus.length
            ? '${_rapportsRecus.length}'
            : '${filtres.length} / ${_rapportsRecus.length}',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInboxFilters(),
          const SizedBox(height: 16),
          if (_isLoadingRapports)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filtres.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  _rapportsRecus.isEmpty
                      ? 'Aucun rapport de mission reçu pour le moment.'
                      : 'Aucun rapport ne correspond à vos filtres.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            Column(children: filtres.map(_buildRapportRecuTile).toList()),
        ],
      ),
    );
  }

  Widget _countBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
              color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildInboxFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Rechercher un chauffeur, un camion, une mission, un trajet...',
            hintStyle: const TextStyle(fontSize: 13, color: mutedColor),
            prefixIcon: const Icon(Icons.search_rounded, color: primaryColor),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () => setState(_searchController.clear),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: primaryColor, width: 1.3)),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ..._filtresEtat.map((etat) {
              final selected = _filtreEtat == etat;
              final color = etat == 'Tous' ? primaryColor : _etatColor(etat);
              return ChoiceChip(
                label: Text(etat),
                selected: selected,
                selectedColor: color.withValues(alpha: 0.15),
                backgroundColor: Colors.white,
                side: BorderSide(color: selected ? color : borderColor),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? color : mutedColor,
                ),
                showCheckmark: false,
                onSelected: (_) => setState(() => _filtreEtat = etat),
              );
            }),
            FilterChip(
              avatar: Icon(Icons.warning_amber_rounded,
                  size: 16,
                  color: _seulementIncidents ? dangerColor : mutedColor),
              label: const Text('Avec incident'),
              selected: _seulementIncidents,
              selectedColor: dangerColor.withValues(alpha: 0.12),
              backgroundColor: Colors.white,
              side: BorderSide(
                  color: _seulementIncidents ? dangerColor : borderColor),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _seulementIncidents ? dangerColor : mutedColor,
              ),
              showCheckmark: false,
              onSelected: (v) => setState(() => _seulementIncidents = v),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(text,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildRapportRecuTile(Map<String, dynamic> rapport) {
    final mission = _map(rapport['mission']);
    final etat = _txt(rapport['etat_camion'], 'RAS');
    final incident = rapport['incident_signale'] == true;
    final photosUrls = _photos(rapport);
    final etatColor = _etatColor(etat);
    final date = _date(rapport['created_at']);
    final distance = _num(rapport['distance_reelle']);
    final carburant = _num(rapport['niveau_carburant']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _ouvrirDetailRapport(rapport),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: etatColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: etatColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                incident
                                    ? Icons.warning_amber_rounded
                                    : Icons.description_rounded,
                                color: etatColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mission #${_txt(mission?['id'])} — ${_txt(mission?['origine'], '')} → ${_txt(mission?['destination'], '')}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        color: inkColor),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${_nomChauffeur(rapport)} • ${_matricule(rapport)}'
                                        '${date != null ? ' • ${DateFormat('dd/MM/yyyy HH:mm').format(date)}' : ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 11.5, color: mutedColor),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Imprimer / Exporter en PDF',
                              icon: const Icon(Icons.print_outlined,
                                  color: primaryColor, size: 20),
                              onPressed: () => _imprimerRapportUnique(rapport),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: mutedColor),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _chip(_etatIcon(etat), etat, etatColor),
                            _chip(
                                Icons.speed_outlined,
                                distance != null
                                    ? '${distance.toStringAsFixed(1)} km'
                                    : 'Distance n/d',
                                primaryColor),
                            _chip(
                                Icons.local_gas_station,
                                carburant != null
                                    ? '${carburant.round()} %'
                                    : 'Carburant n/d',
                                carburant != null
                                    ? _fuelColor(carburant)
                                    : mutedColor),
                            if (photosUrls.isNotEmpty)
                              _chip(Icons.photo_camera_outlined,
                                  '${photosUrls.length} photo(s)', primaryColor),
                            if (incident)
                              _chip(Icons.report_problem_outlined,
                                  'Incident signalé', dangerColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DÉTAIL COMPLET D'UN RAPPORT CHAUFFEUR
  // ============================================================

  void _ouvrirDetailRapport(Map<String, dynamic> rapport) {
    final etat = _txt(rapport['etat_camion'], 'RAS');
    final etatColor = _etatColor(etat);
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints:
            BoxConstraints(maxWidth: 820, maxHeight: screenHeight * 0.92),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 16, 10, 16),
                  color: primaryColor,
                  child: Row(
                    children: [
                      const Icon(Icons.description_rounded, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Rapport de fin de mission',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            const SizedBox(height: 2),
                            Text(_numero(rapport),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: etatColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(etat,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                ),
                // Corps
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: _buildDetailBody(rapport),
                  ),
                ),
                // Pied
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    border: Border(top: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Fermer'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _imprimerRapportUnique(rapport),
                        icon: const Icon(Icons.print_outlined, size: 18),
                        label: const Text('Imprimer / PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailBody(Map<String, dynamic> rapport) {
    final mission = _map(rapport['mission']);
    final etat = _txt(rapport['etat_camion'], 'RAS');
    final etatColor = _etatColor(etat);
    final incident = rapport['incident_signale'] == true;
    final photosUrls = _photos(rapport);
    final date = _date(rapport['created_at']);
    final distance = _num(rapport['distance_reelle']);
    final carburant = _num(rapport['niveau_carburant']);
    final commentaire = _txt(rapport['commentaire'], '');
    final description = _txt(rapport['incident_description'], '');

    final infos = <List<String>>[
      ['N° mission', '#${_txt(mission?['id'])}'],
      if (_txt(mission?['reference'], '').isNotEmpty)
        ['Référence', _txt(mission?['reference'])],
      [
        'Trajet',
        '${_txt(mission?['origine'])}  →  ${_txt(mission?['destination'])}'
      ],
      ['Chauffeur', _nomChauffeur(rapport)],
      ['Camion', _matricule(rapport)],
      if (_txt(mission?['date'] ?? mission?['date_depart'], '').isNotEmpty)
        ['Date de mission', _txt(mission?['date'] ?? mission?['date_depart'])],
      if (_txt(mission?['heure'], '').isNotEmpty)
        ['Heure', _txt(mission?['heure'])],
      if (_txt(mission?['type'], '').isNotEmpty)
        ['Type', _txt(mission?['type'])],
      if (_txt(mission?['priorite'], '').isNotEmpty)
        ['Priorité', _txt(mission?['priorite'])],
      if (_txt(mission?['objet'], '').isNotEmpty)
        ['Objet', _txt(mission?['objet'])],
      [
        'Rapport reçu le',
        date != null ? DateFormat('dd/MM/yyyy à HH:mm').format(date) : '—'
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Identification
        _detailSection(
            '1', 'Identification de la mission', Icons.assignment_outlined),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: infos.map((i) => _detailCell(i[0], i[1])).toList(),
        ),
        const SizedBox(height: 24),

        // 2. Données équipement
        _detailSection(
            '2', 'Données relevées par l\'équipement', Icons.sensors_rounded),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _metricCard(
                Icons.speed_outlined,
                'Distance parcourue',
                distance != null
                    ? '${distance.toStringAsFixed(2)} km'
                    : 'Non disponible',
                primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                Icons.local_gas_station,
                'Carburant restant',
                carburant != null ? '${carburant.round()} %' : 'Non disponible',
                carburant != null ? _fuelColor(carburant) : mutedColor,
                progress: carburant != null ? carburant / 100 : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 3. État du véhicule
        _detailSection(
            '3', 'État du véhicule à l\'arrivée', Icons.local_shipping_outlined),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: etatColor.withValues(alpha: 0.06),
            border: Border.all(color: etatColor.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(_etatIcon(etat), color: etatColor, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(etat,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: etatColor)),
                    const SizedBox(height: 2),
                    Text(_etatDescription(etat),
                        style:
                        const TextStyle(fontSize: 12, color: mutedColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 4. Incident
        _detailSection(
            '4', 'Déclaration d\'incident', Icons.report_problem_outlined),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: incident
                ? dangerColor.withValues(alpha: 0.06)
                : accentColor.withValues(alpha: 0.06),
            border: Border.all(
                color: (incident ? dangerColor : accentColor)
                    .withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(incident ? Icons.warning_rounded : Icons.check_circle_outline,
                  color: incident ? dangerColor : accentColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident
                          ? 'Incident signalé par le chauffeur'
                          : 'Aucun incident signalé',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: incident ? dangerColor : accentColor),
                    ),
                    if (incident) ...[
                      const SizedBox(height: 6),
                      Text(
                        description.isNotEmpty
                            ? description
                            : 'Aucune description fournie.',
                        style: const TextStyle(
                            fontSize: 13, color: inkColor, height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 5. Observations
        _detailSection('5', 'Observations du chauffeur', Icons.comment_outlined),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            commentaire.isNotEmpty ? commentaire : 'Aucune remarque.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: commentaire.isNotEmpty ? inkColor : mutedColor,
              fontStyle:
              commentaire.isNotEmpty ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 6. Photos
        _detailSection('6', 'Pièces jointes (${photosUrls.length})',
            Icons.photo_library_outlined),
        if (photosUrls.isEmpty)
          const Text('Aucune photo jointe.',
              style: TextStyle(
                  fontSize: 13, color: mutedColor, fontStyle: FontStyle.italic))
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: photosUrls.map((url) {
              return InkWell(
                onTap: () => _zoomerPhoto(photosUrls, photosUrls.indexOf(url)),
                borderRadius: BorderRadius.circular(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    url,
                    width: 130,
                    height: 130,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: 130,
                        height: 130,
                        color: const Color(0xFFF3F4F6),
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                    errorBuilder: (context, error, stack) => Container(
                      width: 130,
                      height: 130,
                      color: const Color(0xFFF3F4F6),
                      child: const Icon(Icons.broken_image_outlined,
                          color: Colors.grey),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _detailSection(String number, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(number,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 18, color: primaryColor),
          const SizedBox(width: 6),
          Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: inkColor,
                  letterSpacing: 0.3)),
          const SizedBox(width: 10),
          const Expanded(child: Divider(color: borderColor, thickness: 1)),
        ],
      ),
    );
  }

  Widget _detailCell(String label, String value) {
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 9.5,
                  color: mutedColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: inkColor)),
        ],
      ),
    );
  }

  Widget _metricCard(IconData icon, String label, String value, Color color,
      {double? progress}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: const TextStyle(fontSize: 11.5, color: mutedColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // ZOOM SUR LES PHOTOS (navigation entre photos)
  // ============================================================

  void _zoomerPhoto(List<String> urls, int startIndex) {
    int index = startIndex < 0 ? 0 : startIndex;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return Dialog(
              backgroundColor: Colors.black,
              insetPadding: const EdgeInsets.all(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ConstrainedBox(
                    constraints:
                    const BoxConstraints(maxWidth: 900, maxHeight: 700),
                    child: InteractiveViewer(
                      child: Image.network(
                        urls[index],
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) => const Padding(
                          padding: EdgeInsets.all(40),
                          child: Icon(Icons.broken_image_outlined,
                              color: Colors.white54, size: 48),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ),
                  if (urls.length > 1) ...[
                    Positioned(
                      left: 4,
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left_rounded,
                            color: Colors.white, size: 36),
                        onPressed: () => setLocal(
                                () => index = (index - 1 + urls.length) % urls.length),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      child: IconButton(
                        icon: const Icon(Icons.chevron_right_rounded,
                            color: Colors.white, size: 36),
                        onPressed: () =>
                            setLocal(() => index = (index + 1) % urls.length),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${index + 1} / ${urls.length}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // MES RAPPORTS D'ACTIVITÉ (génération + historique)
  // ============================================================

  Widget _buildMesRapportsSection() {
    return _buildSectionCard(
      title: 'Mes rapports d\'activité',
      icon: Icons.fact_check_rounded,
      trailing: _countBadge('${_historiqueActivite.length}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Générez un rapport consolidé de l\'activité de la flotte sur une période. '
                'Il regroupe les missions, les maintenances et les rapports envoyés par les chauffeurs.',
            style: TextStyle(fontSize: 12.5, color: mutedColor),
          ),
          const SizedBox(height: 14),
          _buildFilters(),
          const SizedBox(height: 20),
          const Text('Rapports générés',
              style: TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.bold, color: inkColor)),
          const SizedBox(height: 10),
          if (_historiqueActivite.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 26),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Icon(Icons.folder_open_rounded,
                      size: 32, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text('Aucun rapport d\'activité généré pour le moment.',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12.5)),
                ],
              ),
            )
          else
            Column(
                children:
                _historiqueActivite.map(_buildHistoriqueTile).toList()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 700;

          final periodDropdown = DropdownButtonFormField<String>(
            initialValue: _selectedPeriod,
            decoration: InputDecoration(
              labelText: 'Période du rapport',
              prefixIcon:
              const Icon(Icons.calendar_month_rounded, color: primaryColor),
              filled: true,
              fillColor: Colors.white,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range_rounded,
                    color: primaryColor, size: 20),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    '${DateFormat('dd/MM/yyyy').format(_periodeDebut)}  →  ${DateFormat('dd/MM/yyyy').format(_periodeFin)}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
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
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Colors.white),
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
        periodeType: _selectedPeriod.toLowerCase(),
        periodeDebut: _periodeDebut,
        periodeFin: _periodeFin,
      );

      if (!mounted) return;

      final rapportsInclus = _liste(resultat['rapports_missions']);

      setState(() {
        _historiqueActivite.insert(0, {
          'rapport': Map<String, dynamic>.from(resultat['data']),
          'inclus': rapportsInclus,
          'periode_type': _selectedPeriod,
          'genere_le': DateTime.now(),
          'complet': true,
        });
        _isGenerating = false;
      });

      _snack(
        resultat['message']?.toString() ??
            'Rapport $_selectedPeriod généré et enregistré avec succès.',
        accentColor,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      _snack('Erreur : ${_cleanError(e)}', dangerColor);
    }
  }

  Future<void> _chargerHistorique() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      final liste = await RapportActiviteService(token: token).lister();
      if (!mounted) return;

      setState(() {
        _historiqueActivite
          ..clear()
          ..addAll(liste.map((r) => {
            'rapport': r,
            'inclus': <Map<String, dynamic>>[],
            'periode_type': _txt(r['periode_type']),
            'genere_le': _date(r['created_at']) ?? DateTime.now(),
            'complet': false,
          }));
      });
    } catch (_) {
      // L'historique reste vide, ce n'est pas bloquant.
    }
  }

  Widget _buildHistoriqueTile(Map<String, dynamic> entry) {
    final r = entry['rapport'] as Map<String, dynamic>;
    final genereLe = entry['genere_le'] as DateTime;
    final act = _map(r['activites']);
    final nbMaint = _txt(_map(act?['stats'])?['maintenances_total'], '0');
    final nbRapports = (r['rapport_mission_ids'] as List?)?.length ??
        _liste(entry['inclus']).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.fact_check_rounded, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rapport ${_txt(entry['periode_type']).toLowerCase()} — du ${_jour(r['periode_debut'])} au ${_jour(r['periode_fin'])}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: inkColor),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_txt(r['total_missions'], '0')} missions • ${_txt(r['distance_totale'], '0')} km • '
                      '${_txt(r['total_incidents'], '0')} incident(s) • $nbMaint maintenance(s) • $nbRapports rapport(s) chauffeur',
                  style: const TextStyle(fontSize: 11.5, color: mutedColor),
                ),
                const SizedBox(height: 2),
                Text(
                  'Généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(genereLe)}',
                  style: const TextStyle(fontSize: 10.5, color: mutedColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _ouvrirRapportActivite(entry),
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('Afficher'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: const BorderSide(color: primaryColor),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final complet = await _chargerComplet(entry);
              if (complet == null || !mounted) return;
              _imprimerRapportActivite(
                complet['rapport'] as Map<String, dynamic>,
                complet['inclus'] as List<Map<String, dynamic>>,
              );
            },
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text('Imprimer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RAPPORT D'ACTIVITÉ : CHARGEMENT COMPLET + AFFICHAGE
  // ============================================================

  /// Charge le détail complet (rapports chauffeurs inclus) si nécessaire.
  Future<Map<String, dynamic>?> _chargerComplet(
      Map<String, dynamic> entry) async {
    var r = Map<String, dynamic>.from(entry['rapport'] as Map);
    var inclus = _liste(entry['inclus']);

    if (entry['complet'] != true) {
      try {
        final token = context.read<AuthProvider>().token!;
        final d = await RapportActiviteService(token: token)
            .detail(int.parse(r['id'].toString()));

        final data = _map(d['data']);
        if (data != null) r = data;
        inclus = _liste(d['rapports_missions']);

        entry['rapport'] = r;
        entry['inclus'] = inclus;
        entry['complet'] = true;
      } catch (e) {
        _snack('Erreur : ${_cleanError(e)}', dangerColor);
        return null;
      }
    }

    return {'rapport': r, 'inclus': inclus};
  }

  Future<void> _ouvrirRapportActivite(Map<String, dynamic> entry) async {
    final complet = await _chargerComplet(entry);
    if (complet == null || !mounted) return;

    final r = complet['rapport'] as Map<String, dynamic>;
    final inclus = complet['inclus'] as List<Map<String, dynamic>>;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints:
            BoxConstraints(maxWidth: 900, maxHeight: screenHeight * 0.92),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 16, 10, 16),
                  color: primaryColor,
                  child: Row(
                    children: [
                      const Icon(Icons.fact_check_rounded, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Rapport d'activité de la flotte",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            const SizedBox(height: 2),
                            Text(
                              'Du ${_jour(r['periode_debut'])} au ${_jour(r['periode_fin'])}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: _buildActiviteBody(r, inclus),
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    border: Border(top: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Fermer'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _imprimerRapportActivite(r, inclus),
                        icon: const Icon(Icons.print_outlined, size: 18),
                        label: const Text('Imprimer / PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiviteBody(
      Map<String, dynamic> r, List<Map<String, dynamic>> inclus) {
    final act = _map(r['activites']);
    final missions = _liste(act?['missions']);
    final maintenances = _liste(act?['maintenances']);
    final stats = _map(act?['stats']) ?? {};

    Widget kpi(IconData icon, String label, String value, Color color) {
      return SizedBox(width: 205, child: _metricCard(icon, label, value, color));
    }

    Widget ligne(IconData icon, String titre, String sous, Color color,
        {String? badge}) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: inkColor)),
                  const SizedBox(height: 2),
                  Text(sous,
                      style:
                      const TextStyle(fontSize: 11.5, color: mutedColor)),
                ],
              ),
            ),
            if (badge != null) _countBadge(badge),
          ],
        ),
      );
    }

    Widget vide(String texte) => Text(texte,
        style: const TextStyle(
            fontSize: 13, color: mutedColor, fontStyle: FontStyle.italic));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailSection('1', 'Synthèse de la période', Icons.dashboard_outlined),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            kpi(Icons.local_shipping_outlined, 'Missions',
                _txt(r['total_missions'], '0'), primaryColor),
            kpi(Icons.check_circle_outline, 'Terminées',
                _txt(r['missions_terminees'], '0'), accentColor),
            kpi(Icons.timelapse_rounded, 'En cours',
                _txt(r['missions_en_cours'], '0'), warningColor),
            kpi(Icons.cancel_outlined, 'Annulées',
                _txt(r['missions_annulees'], '0'), mutedColor),
            kpi(Icons.route_rounded, 'Distance totale',
                '${_txt(r['distance_totale'], '0')} km', primaryColor),
            kpi(Icons.report_problem_outlined, 'Incidents',
                _txt(r['total_incidents'], '0'), dangerColor),
            kpi(Icons.build_outlined, 'Maintenances',
                _txt(stats['maintenances_total'], '0'), warningColor),
            kpi(Icons.payments_outlined, 'Coût maintenances',
                _fcfa(stats['cout_estime_total']), primaryColor),
          ],
        ),
        const SizedBox(height: 24),
        _detailSection('2', 'Missions (${missions.length})',
            Icons.local_shipping_outlined),
        if (missions.isEmpty)
          vide('Aucune mission enregistrée sur la période.')
        else
          ...missions.map((m) => ligne(
            Icons.route_outlined,
            'Mission #${_txt(m['id'])} — ${_txt(m['origine'], '')} → ${_txt(m['destination'], '')}',
            '${_jour(m['date'])} • ${_txt(m['chauffeur'])} • ${_txt(m['camion'])}',
            primaryColor,
            badge: _txt(m['statut']),
          )),
        const SizedBox(height: 24),
        _detailSection('3', 'Maintenances (${maintenances.length})',
            Icons.build_circle_outlined),
        if (maintenances.isEmpty)
          vide('Aucune maintenance planifiée sur la période.')
        else
          ...maintenances.map((m) => ligne(
            Icons.build_outlined,
            _txt(m['description']),
            '${_txt(m['reference'])} • ${_txt(m['camion'])} • ${_jour(m['date_planifiee'])} • ${_fcfa(m['cout_estime'])}',
            warningColor,
            badge: _txt(m['statut']),
          )),
        const SizedBox(height: 24),
        _detailSection(
            '4',
            'Rapports envoyés par les chauffeurs (${inclus.length})',
            Icons.inbox_rounded),
        if (inclus.isEmpty)
          vide('Aucun rapport chauffeur sur la période.')
        else
          ...inclus.map((rap) {
            final mission = _map(rap['mission']);
            final etat = _txt(rap['etat_camion'], 'RAS');
            final dist = _num(rap['distance_reelle']);
            final incident = rap['incident_signale'] == true;
            return InkWell(
              onTap: () => _ouvrirDetailRapport(rap),
              borderRadius: BorderRadius.circular(10),
              child: ligne(
                incident ? Icons.warning_amber_rounded : _etatIcon(etat),
                'Mission #${_txt(mission?['id'])} — ${_nomChauffeur(rap)}',
                '${_matricule(rap)} • ${dist != null ? '${dist.toStringAsFixed(1)} km' : 'Distance n/d'}'
                    '${incident ? ' • Incident signalé' : ''}',
                incident ? dangerColor : _etatColor(etat),
                badge: etat,
              ),
            );
          }),
      ],
    );
  }

  // ============================================================
  // PDF — RAPPORT CHAUFFEUR UNIQUE (fiche complète)
  // ============================================================

  Future<void> _imprimerRapportUnique(Map<String, dynamic> rapport) async {
    final mission = _map(rapport['mission']);
    final etat = _txt(rapport['etat_camion'], 'RAS');
    final incident = rapport['incident_signale'] == true;
    final distance = _num(rapport['distance_reelle']);
    final carburant = _num(rapport['niveau_carburant']);
    final commentaire = _txt(rapport['commentaire'], '');
    final description = _txt(rapport['incident_description'], '');
    final date = _date(rapport['created_at']);
    final photosUrls = _photos(rapport);

    // Télécharge les photos jointes pour les intégrer au PDF.
    final photoImages = <pw.MemoryImage>[];
    for (final url in photosUrls) {
      try {
        final resp = await http.get(Uri.parse(url));
        if (resp.statusCode == 200) {
          photoImages.add(pw.MemoryImage(resp.bodyBytes));
        }
      } catch (_) {
        // Une photo qui échoue ne bloque pas l'impression.
      }
    }

    if (!mounted) return;

    final currentUser = context.read<AuthProvider>().user;
    final nomResponsable = currentUser != null
        ? '${currentUser.prenom} ${currentUser.nom}'.trim()
        : 'Responsable de flotte';

    final fontRegular = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
    );
    final pdfPrimary = PdfColor.fromInt(0xFF1D3557);
    final pdfGrey = PdfColor.fromInt(0xFF6B7280);
    final pdfBorder = PdfColor.fromInt(0xFFD8DFE7);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('SIRAFLEET',
                        style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: pdfPrimary)),
                    pw.Text('RAPPORT DE FIN DE MISSION',
                        style: pw.TextStyle(fontSize: 10, color: pdfGrey)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(_numero(rapport),
                        style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: pdfPrimary)),
                    pw.Text(
                        date != null
                            ? DateFormat('dd/MM/yyyy à HH:mm').format(date)
                            : '',
                        style: pw.TextStyle(fontSize: 9, color: pdfGrey)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: pdfBorder),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: pdfGrey)),
        ),
        build: (ctx) => [
          _pdfSectionTitle('1. Identification de la mission', pdfPrimary),
          pw.SizedBox(height: 6),
          _pdfInfoTable([
            ['N° Mission', '#${_txt(mission?['id'])}'],
            ['Chauffeur', _nomChauffeur(rapport)],
            [
              'Trajet',
              '${_txt(mission?['origine'])}  ->  ${_txt(mission?['destination'])}'
            ],
            ['Camion', _matricule(rapport)],
            if (_txt(mission?['date'] ?? mission?['date_depart'], '').isNotEmpty)
              [
                'Date de mission',
                _txt(mission?['date'] ?? mission?['date_depart'])
              ],
          ], pdfBorder, pdfGrey),
          pw.SizedBox(height: 14),
          _pdfSectionTitle('2. Données kilométriques et carburant', pdfPrimary),
          pw.SizedBox(height: 6),
          _pdfInfoTable([
            [
              'Distance parcourue',
              distance != null
                  ? '${distance.toStringAsFixed(2)} km'
                  : 'Non disponible'
            ],
            [
              'Carburant restant',
              carburant != null ? '${carburant.round()}%' : 'Non disponible'
            ],
          ], pdfBorder, pdfGrey),
          pw.SizedBox(height: 14),
          _pdfSectionTitle('3. État du véhicule', pdfPrimary),
          pw.SizedBox(height: 6),
          pw.Text(etat,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 14),
          _pdfSectionTitle('4. Incident', pdfPrimary),
          pw.SizedBox(height: 6),
          pw.Text(
            incident
                ? (description.isNotEmpty
                ? description
                : 'Incident signalé, aucune description fournie.')
                : 'Aucun incident signalé.',
            style: pw.TextStyle(fontSize: 10, color: pdfGrey),
          ),
          pw.SizedBox(height: 14),
          _pdfSectionTitle('5. Observations du chauffeur', pdfPrimary),
          pw.SizedBox(height: 6),
          pw.Text(commentaire.isNotEmpty ? commentaire : 'Aucune remarque.',
              style: pw.TextStyle(fontSize: 10, color: pdfGrey)),
          if (photoImages.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _pdfSectionTitle(
                '6. Pièces jointes (${photoImages.length} photo(s))', pdfPrimary),
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: photoImages
                  .map((img) => pw.Container(
                width: 160,
                height: 160,
                decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: pdfBorder)),
                child: pw.Image(img, fit: pw.BoxFit.cover),
              ))
                  .toList(),
            ),
          ],
          pw.SizedBox(height: 30),
          pw.Divider(color: pdfBorder),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Établi par le chauffeur',
                      style: pw.TextStyle(fontSize: 9, color: pdfGrey)),
                  pw.Text(_nomChauffeur(rapport),
                      style: pw.TextStyle(
                          fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 22),
                  pw.Text('Signature : ______________',
                      style: pw.TextStyle(fontSize: 9, color: pdfGrey)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Vu par le responsable de flotte',
                      style: pw.TextStyle(fontSize: 9, color: pdfGrey)),
                  pw.Text(nomResponsable,
                      style: pw.TextStyle(
                          fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 22),
                  pw.Text('Signature : ______________',
                      style: pw.TextStyle(fontSize: 9, color: pdfGrey)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  // ============================================================
  // PDF — RAPPORT D'ACTIVITÉ CONSOLIDÉ
  // ============================================================

  Future<void> _imprimerRapportActivite(
      Map<String, dynamic> r,
      List<Map<String, dynamic>> inclus,
      ) async {
    final currentUser = context.read<AuthProvider>().user;
    final nomResponsable = currentUser != null
        ? '${currentUser.prenom} ${currentUser.nom}'.trim()
        : 'Responsable de flotte';

    final act = _map(r['activites']);
    final missions = _liste(act?['missions']);
    final maintenances = _liste(act?['maintenances']);
    final stats = _map(act?['stats']) ?? {};

    final fontRegular = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
    );
    final pdfPrimary = PdfColor.fromInt(0xFF1D3557);
    final pdfGrey = PdfColor.fromInt(0xFF6B7280);
    final pdfBorder = PdfColor.fromInt(0xFFE2E8F0);

    pw.Widget cell(String text, {bool bold = false, double size = 8.5}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: size,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      );
    }

    pw.Widget tableau(List<String> entetes, List<List<String>> lignes) {
      return pw.Table(
        border: pw.TableBorder.all(color: pdfBorder, width: 0.5),
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F4F6)),
            children: entetes.map((h) => cell(h, bold: true)).toList(),
          ),
          ...lignes.map(
                (l) => pw.TableRow(children: l.map((c) => cell(c)).toList()),
          ),
        ],
      );
    }

    pw.Widget titre(String t) => pw.Text(t,
        style: pw.TextStyle(
            fontSize: 11, fontWeight: pw.FontWeight.bold, color: pdfPrimary));

    pw.Widget vide(String t) =>
        pw.Text(t, style: pw.TextStyle(fontSize: 9, color: pdfGrey));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('SiraFleet',
                        style: pw.TextStyle(fontSize: 10, color: pdfGrey)),
                    pw.Text("RAPPORT D'ACTIVITÉ DE LA FLOTTE",
                        style: pw.TextStyle(
                            fontSize: 17,
                            fontWeight: pw.FontWeight.bold,
                            color: pdfPrimary)),
                  ],
                ),
                pw.Text(
                  'Période : ${_jour(r['periode_debut'])} au ${_jour(r['periode_fin'])}',
                  style: pw.TextStyle(fontSize: 10, color: pdfGrey),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: pdfBorder),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: pdfGrey)),
        ),
        build: (ctx) => [
          titre('1. SYNTHÈSE'),
          pw.SizedBox(height: 8),
          _pdfInfoTable([
            ['Total missions', _txt(r['total_missions'], '0')],
            ['Missions terminées', _txt(r['missions_terminees'], '0')],
            ['Missions en cours', _txt(r['missions_en_cours'], '0')],
            ['Missions annulées', _txt(r['missions_annulees'], '0')],
            [
              'Distance totale parcourue',
              '${_txt(r['distance_totale'], '0')} km'
            ],
            ['Total incidents signalés', _txt(r['total_incidents'], '0')],
            [
              'Maintenances sur la période',
              _txt(stats['maintenances_total'], '0')
            ],
            ['Coût estimé des maintenances', _fcfa(stats['cout_estime_total'])],
          ], pdfBorder, pdfGrey),
          pw.SizedBox(height: 18),
          titre('2. MISSIONS (${missions.length})'),
          pw.SizedBox(height: 8),
          if (missions.isEmpty)
            vide('Aucune mission sur la période.')
          else
            tableau(
              ['N°', 'Date', 'Trajet', 'Chauffeur', 'Camion', 'Statut'],
              missions
                  .map((m) => [
                '#${_txt(m['id'])}',
                _jour(m['date']),
                '${_txt(m['origine'], '')} -> ${_txt(m['destination'], '')}',
                _txt(m['chauffeur']),
                _txt(m['camion']),
                _txt(m['statut']),
              ])
                  .toList(),
            ),
          pw.SizedBox(height: 18),
          titre('3. MAINTENANCES (${maintenances.length})'),
          pw.SizedBox(height: 8),
          if (maintenances.isEmpty)
            vide('Aucune maintenance sur la période.')
          else
            tableau(
              [
                'Référence',
                'Camion',
                'Description',
                'Date',
                'Statut',
                'Coût estimé'
              ],
              maintenances
                  .map((m) => [
                _txt(m['reference']),
                _txt(m['camion']),
                _txt(m['description']),
                _jour(m['date_planifiee']),
                _txt(m['statut']),
                _fcfa(m['cout_estime']),
              ])
                  .toList(),
            ),
          pw.SizedBox(height: 18),
          titre('4. RAPPORTS DES CHAUFFEURS (${inclus.length})'),
          pw.SizedBox(height: 8),
          if (inclus.isEmpty)
            vide('Aucun rapport chauffeur sur la période.')
          else
            tableau(
              ['Mission', 'Chauffeur', 'Trajet', 'Distance', 'Carburant', 'État'],
              inclus.map((rap) {
                final mission = _map(rap['mission']);
                final dist = _num(rap['distance_reelle']);
                final carb = _num(rap['niveau_carburant']);
                return [
                  '#${_txt(mission?['id'])}',
                  _nomChauffeur(rap),
                  '${_txt(mission?['origine'], '')} -> ${_txt(mission?['destination'], '')}',
                  dist != null ? '${dist.toStringAsFixed(1)} km' : '—',
                  carb != null ? '${carb.round()}%' : '—',
                  _txt(rap['etat_camion'], 'RAS'),
                ];
              }).toList(),
            ),
          if (inclus.any((e) => e['incident_signale'] == true)) ...[
            pw.SizedBox(height: 18),
            titre('5. INCIDENTS SIGNALÉS'),
            pw.SizedBox(height: 8),
            ...inclus.where((e) => e['incident_signale'] == true).map((e) {
              final mission = _map(e['mission']);
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Text(
                  'Mission #${_txt(mission?['id'])} (${_nomChauffeur(e)}) : '
                      '${_txt(e['incident_description'], 'Aucune description.')}',
                  style: pw.TextStyle(fontSize: 9, color: pdfGrey),
                ),
              );
            }),
          ],
          pw.SizedBox(height: 24),
          pw.Divider(color: pdfBorder),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Rapport établi par',
                      style: pw.TextStyle(fontSize: 9, color: pdfGrey)),
                  pw.Text(nomResponsable,
                      style: pw.TextStyle(
                          fontSize: 11, fontWeight: pw.FontWeight.bold)),
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

  pw.Widget _pdfSectionTitle(String title, PdfColor color) {
    return pw.Text(
      title.toUpperCase(),
      style: pw.TextStyle(
          fontSize: 10, fontWeight: pw.FontWeight.bold, color: color),
    );
  }

  pw.Widget _pdfInfoTable(
      List<List<String>> rows, PdfColor border, PdfColor grey) {
    return pw.Table(
      border: pw.TableBorder.all(color: border, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.3),
        1: const pw.FlexColumnWidth(2.5)
      },
      children: rows
          .map((row) => pw.TableRow(children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(row[0],
              style: pw.TextStyle(fontSize: 9, color: grey)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(row[1],
              style: pw.TextStyle(
                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ),
      ]))
          .toList(),
    );
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D3557).withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
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
                      color: inkColor),
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
