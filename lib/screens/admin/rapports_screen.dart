/*import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/admin_rapport_service.dart';
import '../../widgets/sidebar_admin.dart';

class RapportsScreen extends StatefulWidget {
  const RapportsScreen({super.key});

  @override
  State<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends State<RapportsScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // COULEURS
  // ============================================================
  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color warningColor = Color(0xFFF4A261);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color borderColor = Color(0xFFE5E7EB);

  // ============================================================
  // ÉTAT
  // ============================================================
  late final TabController _tabs;

  // Période
  final List<String> _periodes = ['Journalier', 'Hebdomadaire', 'Mensuel', 'Annuel', 'Personnalisé'];
  String _periode = 'Hebdomadaire';
  DateTimeRange? _custom;

  // Statistiques
  Map<String, dynamic>? _stats;
  bool _loadingStats = true;
  String? _errorStats;

  // Journal
  final List<Map<String, dynamic>> _logs = [];
  List<String> _modules = [];
  int _page = 1;
  int _lastPage = 1;
  bool _loadingLogs = false;
  String? _errorLogs;
  String _roleFilter = 'tous';
  String _statutFilter = 'tous';
  String _moduleFilter = 'tous';
  String _search = '';
  Timer? _debounce;

  // Rapports générés
  List<Map<String, dynamic>> _rapports = [];
  bool _loadingRapports = true;
  bool _generating = false;

  AdminRapportService get _service =>
      AdminRapportService(token: context.read<AuthProvider>().token ?? '');

  // ============================================================
  // INIT
  // ============================================================
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (mounted) setState(() {}); // met à jour l'onglet actif
    });
    _refreshAll();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadStats(),
      _loadLogs(reset: true),
      _loadRapports(),
      _loadModules(),
    ]);
  }

  // ============================================================
  // PÉRIODE
  // ============================================================
  DateTimeRange get _range {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_periode) {
      case 'Journalier':
        return DateTimeRange(start: today, end: today);
      case 'Mensuel':
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: today);
      case 'Annuel':
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: today);
      case 'Personnalisé':
        return _custom ?? DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today);
      default: // Hebdomadaire = 7 derniers jours
        return DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today);
    }
  }

  String get _periodeApi => _periode
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('personnalise', 'personnalise');

  Future<void> _pickPeriode(String p) async {
    if (p == 'Personnalisé') {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2024),
        lastDate: DateTime.now(),
        initialDateRange: _range,
      );
      if (picked == null) return;
      _custom = picked;
    }
    setState(() => _periode = p);
    _loadStats();
    _loadLogs(reset: true);
  }

  // ============================================================
  // CHARGEMENTS
  // ============================================================
  Future<void> _loadStats() async {
    setState(() {
      _loadingStats = true;
      _errorStats = null;
    });
    try {
      final r = _range;
      final s = await _service.stats(r.start, r.end);
      if (!mounted) return;
      setState(() {
        _stats = s;
        _loadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorStats = e.toString().replaceFirst('Exception: ', '');
        _loadingStats = false;
      });
    }
  }

  Future<void> _loadLogs({bool reset = false}) async {
    if (_loadingLogs) return;
    if (reset) {
      _page = 1;
      _logs.clear();
    }
    setState(() {
      _loadingLogs = true;
      _errorLogs = null;
    });
    try {
      final r = _range;
      final res = await _service.journal(
        page: _page,
        role: _roleFilter == 'tous' ? null : _roleFilter,
        statut: _statutFilter == 'tous' ? null : _statutFilter,
        module: _moduleFilter == 'tous' ? null : _moduleFilter,
        search: _search,
        debut: r.start,
        fin: r.end,
      );
      if (!mounted) return;
      setState(() {
        _logs.addAll(res.items);
        _lastPage = res.lastPage;
        _loadingLogs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorLogs = e.toString().replaceFirst('Exception: ', '');
        _loadingLogs = false;
      });
    }
  }

  Future<void> _loadModules() async {
    try {
      final m = await _service.modules();
      if (mounted) setState(() => _modules = m);
    } catch (_) {}
  }

  Future<void> _loadRapports() async {
    setState(() => _loadingRapports = true);
    try {
      final r = await _service.lister();
      if (!mounted) return;
      setState(() {
        _rapports = r;
        _loadingRapports = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rapports = [];
        _loadingRapports = false;
      });
    }
  }

  // ============================================================
  // GÉNÉRATION D'UN RAPPORT ADMIN
  // ============================================================
  Future<void> _generer() async {
    final notesCtrl = TextEditingController();
    final r = _range;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Générer un rapport administrateur',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 17)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.date_range_outlined, color: primaryColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$_periode  •  ${_fmtDay(r.start)} → ${_fmtDay(r.end)}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: notesCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Observations (facultatif)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.description_outlined, size: 18),
            label: const Text('Générer'),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    setState(() => _generating = true);
    try {
      await _service.generer(
        periodeType: _periodeApi,
        debut: r.start,
        fin: r.end,
        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      );
      await _loadRapports();
      if (!mounted) return;
      _tabs.animateTo(2);
      _snack('Rapport généré et enregistré.', accentColor);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''), dangerColor);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _ouvrirRapport(int id) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final res = await _service.detail(id);
      if (!mounted) return;
      Navigator.pop(context);
      _showRapportDetail(
        Map<String, dynamic>.from(res['data']),
        List<Map<String, dynamic>>.from(res['activites'] ?? []),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _snack(e.toString().replaceFirst('Exception: ', ''), dangerColor);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ============================================================
  // HELPERS
  // ============================================================
  String _two(int n) => n.toString().padLeft(2, '0');
  String _fmtDay(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

  String _fmtDateTime(String? iso) {
    final d = DateTime.tryParse(iso ?? '')?.toLocal();
    if (d == null) return '—';
    return '${_fmtDay(d)}  ${_two(d.hour)}:${_two(d.minute)}';
  }

  String _fmtIsoDay(String? iso) {
    final d = DateTime.tryParse(iso ?? '');
    return d == null ? '—' : _fmtDay(d);
  }

  int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

  ({Color color, IconData icon, String label}) _roleStyle(String? role) {
    switch (role) {
      case 'admin':
        return (color: primaryColor, icon: Icons.admin_panel_settings_outlined, label: 'Administrateur');
      case 'responsable':
        return (color: accentColor, icon: Icons.manage_accounts_outlined, label: 'Responsable');
      case 'chauffeur':
        return (color: warningColor, icon: Icons.local_shipping_outlined, label: 'Chauffeur');
      default:
        return (color: Colors.blueGrey, icon: Icons.memory_outlined, label: 'Système');
    }
  }

  IconData _actionIcon(String? action) {
    switch (action) {
      case 'connexion':
        return Icons.login;
      case 'deconnexion':
        return Icons.logout;
      case 'creation':
        return Icons.add_circle_outline;
      case 'modification':
        return Icons.edit_outlined;
      case 'suppression':
        return Icons.delete_outline;
      case 'demarrage':
        return Icons.play_circle_outline;
      case 'fin':
        return Icons.check_circle_outline;
      case 'sos':
        return Icons.emergency_outlined;
      case 'statut':
        return Icons.sync_alt;
      case 'message':
        return Icons.chat_bubble_outline;
      default:
        return Icons.info_outline;
    }
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
          const SidebarAdmin(selectedIndex: 8),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _buildOverviewTab(),
                      _buildJournalTab(),
                      _buildHistoryTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _buildHeader() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          const Text('Rapports',
              style: TextStyle(color: primaryColor, fontSize: 21, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: () async {
              await _refreshAll();
              if (mounted) _snack('Données actualisées.', accentColor);
            },
            icon: const Icon(Icons.refresh_outlined, color: primaryColor),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _generating ? null : _generer,
            icon: _generating
                ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.note_add_outlined, size: 18),
            label: const Text('Générer un rapport'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      alignment: Alignment.centerLeft,
      child: TabBar(
        controller: _tabs,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: primaryColor,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: accentColor,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(icon: Icon(Icons.insights_outlined, size: 18), text: 'Vue d’ensemble'),
          Tab(icon: Icon(Icons.history_outlined, size: 18), text: 'Journal d’activité'),
          Tab(icon: Icon(Icons.folder_open_outlined, size: 18), text: 'Mes rapports'),
        ],
      ),
    );
  }

  // ============================================================
  // SÉLECTEUR DE PÉRIODE
  // ============================================================
  Widget _buildPeriodSelector() {
    final r = _range;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _cardDecoration(radius: 12),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ..._periodes.map((p) {
            final selected = _periode == p;
            return ChoiceChip(
              avatar: p == 'Personnalisé'
                  ? Icon(Icons.calendar_month_outlined,
                  size: 16, color: selected ? Colors.white : primaryColor)
                  : null,
              label: Text(p),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) => _pickPeriode(p),
              selectedColor: primaryColor,
              backgroundColor: Colors.transparent,
              side: BorderSide.none,
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }),
          const SizedBox(width: 8),
          Text('${_fmtDay(r.start)}  →  ${_fmtDay(r.end)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 16}) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor),
    boxShadow: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
    ],
  );

  // ============================================================
  // ONGLET 1 — VUE D'ENSEMBLE
  // ============================================================
  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(),
            const SizedBox(height: 20),
            _buildPeriodSelector(),
            const SizedBox(height: 22),
            if (_loadingStats)
              const Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator()))
            else if (_errorStats != null)
              _buildError(_errorStats!, _loadStats)
            else if (_stats != null) ...[
                _buildKpis(),
                const SizedBox(height: 22),
                _buildChartAndRoles(),
                const SizedBox(height: 22),
                _buildModulesAndPlatform(),
              ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [primaryColor, Color(0xFF264E7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.assessment_outlined, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rapport d’activité de la plateforme',
                    style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text(
                  'Toutes les actions réalisées sur SiraFleet par les administrateurs, '
                      'les responsables de flotte et les chauffeurs.',
                  style: TextStyle(color: Color(0xFFD6E2F0), fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- KPI ----------
  Widget _buildKpis() {
    final s = _stats!;
    final roles = Map<String, dynamic>.from(s['par_role'] ?? {});
    final pf = Map<String, dynamic>.from(s['plateforme'] ?? {});

    final alertes = _int(pf['alertes']);
    final resolues = _int(pf['alertes_resolues']);
    final tauxAlertes = alertes == 0 ? '—' : '${(resolues * 100 / alertes).round()} %';

    final cards = <Widget>[
      _kpi(Icons.bolt_outlined, 'Activités totales', '${_int(s['total'])}', primaryColor),
      _kpi(Icons.admin_panel_settings_outlined, 'Actions admin', '${_int(roles['admin'])}', primaryColor),
      _kpi(Icons.manage_accounts_outlined, 'Actions responsables', '${_int(roles['responsable'])}', accentColor),
      _kpi(Icons.local_shipping_outlined, 'Actions chauffeurs', '${_int(roles['chauffeur'])}', warningColor),
      _kpi(Icons.login_outlined, 'Connexions', '${_int(s['connexions'])}', Colors.teal),
      _kpi(Icons.error_outline, 'Actions en échec', '${_int(s['echecs'])}', dangerColor),
      _kpi(Icons.people_outline, 'Utilisateurs', '${_int(pf['utilisateurs'])}', Colors.indigo),
      _kpi(Icons.local_shipping_outlined, 'Camions', '${_int(pf['camions'])}', accentColor),
      _kpi(Icons.memory_outlined, 'Équipements', '${_int(pf['equipements'])}', warningColor),
      _kpi(Icons.verified_outlined, 'Alertes résolues', tauxAlertes, Colors.green),
    ];

    return _responsiveWrap(cards, minWidth: 210);
  }

  Widget _responsiveWrap(List<Widget> children, {double minWidth = 220, double spacing = 14}) {
    return LayoutBuilder(builder: (context, c) {
      final cols = (c.maxWidth / minWidth).floor().clamp(1, 6);
      final w = (c.maxWidth - spacing * (cols - 1)) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: children.map((e) => SizedBox(width: w, child: e)).toList(),
      );
    });
  }

  Widget _kpi(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(color: primaryColor, fontSize: 21, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Graphique + répartition par rôle ----------
  Widget _buildChartAndRoles() {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth > 900;
      final chart = _sectionCard(
        title: 'Évolution de l’activité',
        subtitle: 'Nombre d’actions enregistrées par ${_stats!['regroupe_par'] == 'mois' ? 'mois' : 'jour'}.',
        child: _buildBarChart(),
      );
      final roles = _sectionCard(
        title: 'Répartition par profil',
        subtitle: 'Qui fait quoi sur la plateforme.',
        child: _buildRoleBars(),
      );

      if (!wide) return Column(children: [chart, const SizedBox(height: 16), roles]);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: chart),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: roles),
        ],
      );
    });
  }

  Widget _buildBarChart() {
    final jours = List<Map<String, dynamic>>.from(_stats!['par_jour'] ?? []);
    if (jours.isEmpty) return _empty('Aucune activité sur cette période.');

    final maxV = jours.map((j) => _int(j['total'])).reduce((a, b) => a > b ? a : b);
    const double maxH = 130;

    String label(String raw) {
      if (raw.length == 7) return '${raw.substring(5)}/${raw.substring(2, 4)}'; // 2026-10 -> 10/26
      if (raw.length >= 10) return '${raw.substring(8, 10)}/${raw.substring(5, 7)}';
      return raw;
    }

    return SizedBox(
      height: maxH + 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: jours.map((j) {
            final v = _int(j['total']);
            final h = maxV == 0 ? 4.0 : (v / maxV * maxH).clamp(4.0, maxH);
            return Container(
              width: 46,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('$v', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(height: 4),
                  Container(
                    height: h,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      gradient: const LinearGradient(
                        colors: [accentColor, Color(0xFF52C4B6)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(label('${j['jour']}'), style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRoleBars() {
    final roles = Map<String, dynamic>.from(_stats!['par_role'] ?? {});
    final total = _int(_stats!['total']);

    Widget row(String key) {
      final st = _roleStyle(key);
      final v = _int(roles[key]);
      final pct = total == 0 ? 0.0 : v / total;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(st.icon, size: 18, color: st.color),
              const SizedBox(width: 8),
              Expanded(child: Text(st.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
              Text('$v  •  ${(pct * 100).round()} %',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5)),
            ]),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 9,
                backgroundColor: backgroundColor,
                color: st.color,
              ),
            ),
          ],
        ),
      );
    }

    return Column(children: [row('admin'), row('responsable'), row('chauffeur')]);
  }

  // ---------- Modules + plateforme ----------
  Widget _buildModulesAndPlatform() {
    final modules = List<Map<String, dynamic>>.from(_stats!['par_module'] ?? []);
    final maxV = modules.isEmpty ? 1 : modules.map((m) => _int(m['total'])).reduce((a, b) => a > b ? a : b);

    return _sectionCard(
      title: 'Modules les plus sollicités',
      subtitle: 'Les 8 modules ayant généré le plus d’actions sur la période.',
      child: modules.isEmpty
          ? _empty('Aucune activité enregistrée.')
          : Column(
        children: modules.map((m) {
          final v = _int(m['total']);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              SizedBox(
                width: 150,
                child: Text('${m['module']}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: v / maxV,
                    minHeight: 10,
                    backgroundColor: backgroundColor,
                    color: primaryColor,
                  ),
                ),
              ),
              SizedBox(
                width: 46,
                child: Text('$v',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // ONGLET 2 — JOURNAL D'ACTIVITÉ
  // ============================================================
  Widget _buildJournalTab() {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 14),
          _buildFilters(),
          const SizedBox(height: 14),
          Expanded(
            child: Container(
              decoration: _cardDecoration(),
              child: _buildLogList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    Widget roleChip(String key, String label) {
      final selected = _roleFilter == key;
      final color = key == 'tous' ? primaryColor : _roleStyle(key).color;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) {
          setState(() => _roleFilter = key);
          _loadLogs(reset: true);
        },
        selectedColor: color,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? color : borderColor),
        labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            onChanged: (v) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 450), () {
                _search = v;
                _loadLogs(reset: true);
              });
            },
            decoration: InputDecoration(
              hintText: 'Rechercher (nom, action, module…)',
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.search, size: 19),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: borderColor),
              ),
            ),
          ),
        ),
        roleChip('tous', 'Tous'),
        roleChip('admin', 'Administrateurs'),
        roleChip('responsable', 'Responsables'),
        roleChip('chauffeur', 'Chauffeurs'),
        _dropdown<String>(
          value: _moduleFilter,
          items: ['tous', ..._modules],
          labelOf: (v) => v == 'tous' ? 'Tous les modules' : v,
          onChanged: (v) {
            setState(() => _moduleFilter = v);
            _loadLogs(reset: true);
          },
        ),
        _dropdown<String>(
          value: _statutFilter,
          items: const ['tous', 'succes', 'echec'],
          labelOf: (v) => v == 'tous' ? 'Tous statuts' : (v == 'succes' ? 'Succès' : 'Échec'),
          onChanged: (v) {
            setState(() => _statutFilter = v);
            _loadLogs(reset: true);
          },
        ),
      ],
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelOf,
    required ValueChanged<T> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: items.contains(value) ? value : items.first,
          isDense: true,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          items: items.map((e) => DropdownMenuItem<T>(value: e, child: Text(labelOf(e)))).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _buildLogList() {
    if (_errorLogs != null && _logs.isEmpty) return _buildError(_errorLogs!, () => _loadLogs(reset: true));
    if (_loadingLogs && _logs.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_logs.isEmpty) return _empty('Aucune activité ne correspond à ces filtres.');

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: _logs.length + 1,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
      itemBuilder: (context, i) {
        if (i == _logs.length) return _buildLoadMore();
        return _buildLogRow(_logs[i]);
      },
    );
  }

  Widget _buildLoadMore() {
    final hasMore = _page < _lastPage;
    if (_loadingLogs) {
      return const Padding(padding: EdgeInsets.all(18), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text('Fin du journal', style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5)),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: () {
            _page++;
            _loadLogs();
          },
          icon: const Icon(Icons.expand_more),
          label: const Text('Charger plus'),
        ),
      ),
    );
  }

  Widget _buildLogRow(Map<String, dynamic> log) {
    final st = _roleStyle(log['role'] as String?);
    final echec = log['statut'] == 'echec';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: st.color.withValues(alpha: 0.10), shape: BoxShape.circle),
            child: Icon(_actionIcon(log['action'] as String?), color: st.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${log['description'] ?? ''}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${log['user_nom'] ?? 'Système'}  •  ${log['module'] ?? ''}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _pill(st.label, st.color),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(_fmtDateTime(log['created_at'] as String?),
                textAlign: TextAlign.right,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5)),
          ),
          const SizedBox(width: 10),
          _pill(echec ? 'Échec' : 'Succès', echec ? dangerColor : accentColor),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.bold)),
    );
  }

  // ============================================================
  // ONGLET 3 — MES RAPPORTS
  // ============================================================
  Widget _buildHistoryTab() {
    if (_loadingRapports) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _loadRapports,
      child: _rapports.isEmpty
          ? ListView(
        children: [
          const SizedBox(height: 80),
          _empty('Aucun rapport généré pour le moment.\nUtilise « Générer un rapport » en haut à droite.'),
        ],
      )
          : ListView.separated(
        padding: const EdgeInsets.all(25),
        itemCount: _rapports.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _buildRapportCard(_rapports[i]),
      ),
    );
  }

  Widget _buildRapportCard(Map<String, dynamic> r) {
    final type = '${r['periode_type'] ?? ''}';
    final typeLabel = type.isEmpty ? '' : '${type[0].toUpperCase()}${type.substring(1)}';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _ouvrirRapport(_int(r['id'])),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.description_outlined, color: primaryColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rapport $typeLabel  #${r['id']}',
                      style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    'Du ${_fmtIsoDay(r['periode_debut'] as String?)} au ${_fmtIsoDay(r['periode_fin'] as String?)}'
                        '  •  généré le ${_fmtDateTime(r['created_at'] as String?)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            _miniStat('Activités', '${_int(r['total_activites'])}', primaryColor),
            _miniStat('Connexions', '${_int(r['total_connexions'])}', Colors.teal),
            _miniStat('Échecs', '${_int(r['total_echecs'])}', dangerColor),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 18),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 10.5)),
        ],
      ),
    );
  }

  // ============================================================
  // DÉTAIL D'UN RAPPORT
  // ============================================================
  void _showRapportDetail(Map<String, dynamic> r, List<Map<String, dynamic>> activites) {
    final modules = List<Map<String, dynamic>>.from(r['repartition_modules'] ?? []);
    final pf = Map<String, dynamic>.from(r['etat_plateforme'] ?? {});

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.assessment_outlined, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rapport administrateur #${r['id']}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 3),
                          Text(
                            'Du ${_fmtIsoDay(r['periode_debut'] as String?)} au ${_fmtIsoDay(r['periode_fin'] as String?)}',
                            style: const TextStyle(color: Color(0xFFD6E2F0), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _responsiveWrap([
                        _kpi(Icons.bolt_outlined, 'Activités', '${_int(r['total_activites'])}', primaryColor),
                        _kpi(Icons.admin_panel_settings_outlined, 'Admin', '${_int(r['activites_admin'])}', primaryColor),
                        _kpi(Icons.manage_accounts_outlined, 'Responsables', '${_int(r['activites_responsable'])}', accentColor),
                        _kpi(Icons.local_shipping_outlined, 'Chauffeurs', '${_int(r['activites_chauffeur'])}', warningColor),
                        _kpi(Icons.login_outlined, 'Connexions', '${_int(r['total_connexions'])}', Colors.teal),
                        _kpi(Icons.error_outline, 'Échecs', '${_int(r['total_echecs'])}', dangerColor),
                      ], minWidth: 220),
                      if (pf.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _detailTitle('État de la plateforme à la génération'),
                        Text(
                          '${_int(pf['utilisateurs'])} utilisateurs  •  ${_int(pf['camions'])} camions  •  '
                              '${_int(pf['equipements'])} équipements  •  '
                              '${_int(pf['alertes_resolues'])}/${_int(pf['alertes'])} alertes résolues',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5),
                        ),
                      ],
                      if (modules.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _detailTitle('Modules les plus sollicités'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: modules
                              .map((m) => _pill('${m['module']}  •  ${m['total']}', primaryColor))
                              .toList(),
                        ),
                      ],
                      if ((r['notes'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _detailTitle('Observations'),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(10)),
                          child: Text('${r['notes']}', style: const TextStyle(fontSize: 12.5, height: 1.4)),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _detailTitle('Activités de la période (${activites.length})'),
                      if (activites.isEmpty)
                        _empty('Aucune activité.')
                      else
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: activites.take(100).map((a) => _buildLogRow(a)).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
  );

  // ============================================================
  // COMPOSANTS COMMUNS
  // ============================================================
  Widget _sectionCard({required String title, required String subtitle, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5)),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _empty(String msg) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 44, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(msg, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String msg, VoidCallback retry) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 44, color: dangerColor),
            const SizedBox(height: 10),
            Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5)),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}*/



import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/admin_rapport_export.dart';
import '../../services/admin_rapport_service.dart';
import '../../widgets/sidebar_admin.dart';

class RapportsScreen extends StatefulWidget {
  const RapportsScreen({super.key});

  @override
  State<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends State<RapportsScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // COULEURS
  // ============================================================
  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color warningColor = Color(0xFFF4A261);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color borderColor = Color(0xFFE5E7EB);

  // ============================================================
  // ÉTAT
  // ============================================================
  late final TabController _tabs;

  // Période
  final List<String> _periodes = ['Journalier', 'Hebdomadaire', 'Mensuel', 'Annuel', 'Personnalisé'];
  String _periode = 'Hebdomadaire';
  DateTimeRange? _custom;

  // Journal
  final List<Map<String, dynamic>> _logs = [];
  List<String> _modules = [];
  int _page = 1;
  int _lastPage = 1;
  bool _loadingLogs = false;
  String? _errorLogs;
  String _roleFilter = 'tous';
  String _statutFilter = 'tous';
  String _moduleFilter = 'tous';
  String _search = '';
  Timer? _debounce;

  // Rapports générés
  List<Map<String, dynamic>> _rapports = [];
  bool _loadingRapports = true;
  bool _generating = false;

  AdminRapportService get _service =>
      AdminRapportService(token: context.read<AuthProvider>().token ?? '');

  // ============================================================
  // INIT
  // ============================================================
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
    _refreshAll();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadLogs(reset: true),
      _loadRapports(),
      _loadModules(),
    ]);
  }

  // ============================================================
  // PÉRIODE
  // ============================================================
  DateTimeRange get _range {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_periode) {
      case 'Journalier':
        return DateTimeRange(start: today, end: today);
      case 'Mensuel':
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: today);
      case 'Annuel':
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: today);
      case 'Personnalisé':
        return _custom ?? DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today);
      default: // Hebdomadaire = 7 derniers jours
        return DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today);
    }
  }

  String get _periodeApi => _periode
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('personnalise', 'personnalise');

  Future<void> _pickPeriode(String p) async {
    if (p == 'Personnalisé') {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2024),
        lastDate: DateTime.now(),
        initialDateRange: _range,
      );
      if (picked == null) return;
      _custom = picked;
    }
    setState(() => _periode = p);
    _loadLogs(reset: true);
  }

  // ============================================================
  // CHARGEMENTS
  // ============================================================
  Future<void> _loadLogs({bool reset = false}) async {
    if (_loadingLogs) return;
    if (reset) {
      _page = 1;
      _logs.clear();
    }
    setState(() {
      _loadingLogs = true;
      _errorLogs = null;
    });
    try {
      final r = _range;
      final res = await _service.journal(
        page: _page,
        role: _roleFilter == 'tous' ? null : _roleFilter,
        statut: _statutFilter == 'tous' ? null : _statutFilter,
        module: _moduleFilter == 'tous' ? null : _moduleFilter,
        search: _search,
        debut: r.start,
        fin: r.end,
      );
      if (!mounted) return;
      setState(() {
        _logs.addAll(res.items);
        _lastPage = res.lastPage;
        _loadingLogs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorLogs = e.toString().replaceFirst('Exception: ', '');
        _loadingLogs = false;
      });
    }
  }

  Future<void> _loadModules() async {
    try {
      final m = await _service.modules();
      if (mounted) setState(() => _modules = m);
    } catch (_) {}
  }

  Future<void> _loadRapports() async {
    setState(() => _loadingRapports = true);
    try {
      final r = await _service.lister();
      if (!mounted) return;
      setState(() {
        _rapports = r;
        _loadingRapports = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rapports = [];
        _loadingRapports = false;
      });
    }
  }

  // ============================================================
  // GÉNÉRATION D'UN RAPPORT ADMIN
  // ============================================================
  Future<void> _generer() async {
    final notesCtrl = TextEditingController();
    final r = _range;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Générer un rapport administrateur',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 17)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.date_range_outlined, color: primaryColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$_periode  •  ${_fmtDay(r.start)} → ${_fmtDay(r.end)}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: notesCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Observations (facultatif)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.description_outlined, size: 18),
            label: const Text('Générer'),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    setState(() => _generating = true);
    try {
      await _service.generer(
        periodeType: _periodeApi,
        debut: r.start,
        fin: r.end,
        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      );
      await _loadRapports();
      if (!mounted) return;
      _tabs.animateTo(1); // onglet « Mes rapports »
      _snack('Rapport généré et enregistré.', accentColor);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''), dangerColor);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _ouvrirRapport(int id) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final res = await _service.detail(id);
      if (!mounted) return;
      Navigator.pop(context);
      _showRapportDetail(
        Map<String, dynamic>.from(res['data']),
        List<Map<String, dynamic>>.from(res['activites'] ?? []),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _snack(e.toString().replaceFirst('Exception: ', ''), dangerColor);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ============================================================
  // HELPERS
  // ============================================================
  String _two(int n) => n.toString().padLeft(2, '0');
  String _fmtDay(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

  String _fmtDateTime(String? iso) {
    final d = DateTime.tryParse(iso ?? '')?.toLocal();
    if (d == null) return '—';
    return '${_fmtDay(d)}  ${_two(d.hour)}:${_two(d.minute)}';
  }

  String _fmtIsoDay(String? iso) {
    final d = DateTime.tryParse(iso ?? '');
    return d == null ? '—' : _fmtDay(d);
  }

  int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

  ({Color color, IconData icon, String label}) _roleStyle(String? role) {
    switch (role) {
      case 'admin':
        return (color: primaryColor, icon: Icons.admin_panel_settings_outlined, label: 'Administrateur');
      case 'responsable':
        return (color: accentColor, icon: Icons.manage_accounts_outlined, label: 'Responsable');
      case 'chauffeur':
        return (color: warningColor, icon: Icons.local_shipping_outlined, label: 'Chauffeur');
      default:
        return (color: Colors.blueGrey, icon: Icons.memory_outlined, label: 'Système');
    }
  }

  IconData _actionIcon(String? action) {
    switch (action) {
      case 'connexion':
        return Icons.login;
      case 'deconnexion':
        return Icons.logout;
      case 'creation':
        return Icons.add_circle_outline;
      case 'modification':
        return Icons.edit_outlined;
      case 'suppression':
        return Icons.delete_outline;
      case 'demarrage':
        return Icons.play_circle_outline;
      case 'fin':
        return Icons.check_circle_outline;
      case 'sos':
        return Icons.emergency_outlined;
      case 'statut':
        return Icons.sync_alt;
      case 'message':
        return Icons.chat_bubble_outline;
      default:
        return Icons.info_outline;
    }
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
          const SidebarAdmin(selectedIndex: 8),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _buildJournalTab(),
                      _buildHistoryTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _buildHeader() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          const Text('Rapports',
              style: TextStyle(color: primaryColor, fontSize: 21, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: () async {
              await _refreshAll();
              if (mounted) _snack('Données actualisées.', accentColor);
            },
            icon: const Icon(Icons.refresh_outlined, color: primaryColor),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _generating ? null : _generer,
            icon: _generating
                ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.note_add_outlined, size: 18),
            label: const Text('Générer un rapport'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      alignment: Alignment.centerLeft,
      child: TabBar(
        controller: _tabs,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: primaryColor,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: accentColor,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(icon: Icon(Icons.history_outlined, size: 18), text: 'Journal d’activité'),
          Tab(icon: Icon(Icons.folder_open_outlined, size: 18), text: 'Mes rapports'),
        ],
      ),
    );
  }

  // ============================================================
  // SÉLECTEUR DE PÉRIODE
  // ============================================================
  Widget _buildPeriodSelector() {
    final r = _range;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _cardDecoration(radius: 12),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ..._periodes.map((p) {
            final selected = _periode == p;
            return ChoiceChip(
              avatar: p == 'Personnalisé'
                  ? Icon(Icons.calendar_month_outlined,
                  size: 16, color: selected ? Colors.white : primaryColor)
                  : null,
              label: Text(p),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) => _pickPeriode(p),
              selectedColor: primaryColor,
              backgroundColor: Colors.transparent,
              side: BorderSide.none,
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }),
          const SizedBox(width: 8),
          Text('${_fmtDay(r.start)}  →  ${_fmtDay(r.end)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 16}) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor),
    boxShadow: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
    ],
  );

  Widget _responsiveWrap(List<Widget> children, {double minWidth = 220, double spacing = 14}) {
    return LayoutBuilder(builder: (context, c) {
      final cols = (c.maxWidth / minWidth).floor().clamp(1, 6);
      final w = (c.maxWidth - spacing * (cols - 1)) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: children.map((e) => SizedBox(width: w, child: e)).toList(),
      );
    });
  }

  Widget _kpi(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(color: primaryColor, fontSize: 21, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ONGLET 1 — JOURNAL D'ACTIVITÉ
  // ============================================================
  Widget _buildJournalTab() {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 14),
          _buildFilters(),
          const SizedBox(height: 14),
          Expanded(
            child: Container(
              decoration: _cardDecoration(),
              child: _buildLogList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    Widget roleChip(String key, String label) {
      final selected = _roleFilter == key;
      final color = key == 'tous' ? primaryColor : _roleStyle(key).color;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) {
          setState(() => _roleFilter = key);
          _loadLogs(reset: true);
        },
        selectedColor: color,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? color : borderColor),
        labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            onChanged: (v) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 450), () {
                _search = v;
                _loadLogs(reset: true);
              });
            },
            decoration: InputDecoration(
              hintText: 'Rechercher (nom, action, module…)',
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.search, size: 19),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: borderColor),
              ),
            ),
          ),
        ),
        roleChip('tous', 'Tous'),
        roleChip('admin', 'Administrateurs'),
        roleChip('responsable', 'Responsables'),
        roleChip('chauffeur', 'Chauffeurs'),
        _dropdown<String>(
          value: _moduleFilter,
          items: ['tous', ..._modules],
          labelOf: (v) => v == 'tous' ? 'Tous les modules' : v,
          onChanged: (v) {
            setState(() => _moduleFilter = v);
            _loadLogs(reset: true);
          },
        ),
        _dropdown<String>(
          value: _statutFilter,
          items: const ['tous', 'succes', 'echec'],
          labelOf: (v) => v == 'tous' ? 'Tous statuts' : (v == 'succes' ? 'Succès' : 'Échec'),
          onChanged: (v) {
            setState(() => _statutFilter = v);
            _loadLogs(reset: true);
          },
        ),
      ],
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelOf,
    required ValueChanged<T> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: items.contains(value) ? value : items.first,
          isDense: true,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          items: items.map((e) => DropdownMenuItem<T>(value: e, child: Text(labelOf(e)))).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _buildLogList() {
    if (_errorLogs != null && _logs.isEmpty) return _buildError(_errorLogs!, () => _loadLogs(reset: true));
    if (_loadingLogs && _logs.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_logs.isEmpty) return _empty('Aucune activité ne correspond à ces filtres.');

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: _logs.length + 1,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
      itemBuilder: (context, i) {
        if (i == _logs.length) return _buildLoadMore();
        return _buildLogRow(_logs[i]);
      },
    );
  }

  Widget _buildLoadMore() {
    final hasMore = _page < _lastPage;
    if (_loadingLogs) {
      return const Padding(
          padding: EdgeInsets.all(18), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text('Fin du journal', style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5)),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: () {
            _page++;
            _loadLogs();
          },
          icon: const Icon(Icons.expand_more),
          label: const Text('Charger plus'),
        ),
      ),
    );
  }

  Widget _buildLogRow(Map<String, dynamic> log) {
    final st = _roleStyle(log['role'] as String?);
    final echec = log['statut'] == 'echec';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: st.color.withValues(alpha: 0.10), shape: BoxShape.circle),
            child: Icon(_actionIcon(log['action'] as String?), color: st.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${log['description'] ?? ''}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${log['user_nom'] ?? 'Système'}  •  ${log['module'] ?? ''}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _pill(st.label, st.color),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(_fmtDateTime(log['created_at'] as String?),
                textAlign: TextAlign.right,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5)),
          ),
          const SizedBox(width: 10),
          _pill(echec ? 'Échec' : 'Succès', echec ? dangerColor : accentColor),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.bold)),
    );
  }

  // ============================================================
  // ONGLET 2 — MES RAPPORTS
  // ============================================================
  Widget _buildHistoryTab() {
    if (_loadingRapports) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _loadRapports,
      child: _rapports.isEmpty
          ? ListView(
        children: [
          const SizedBox(height: 80),
          _empty('Aucun rapport généré pour le moment.\nUtilise « Générer un rapport » en haut à droite.'),
        ],
      )
          : ListView.separated(
        padding: const EdgeInsets.all(25),
        itemCount: _rapports.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _buildRapportCard(_rapports[i]),
      ),
    );
  }

  Widget _buildRapportCard(Map<String, dynamic> r) {
    final type = '${r['periode_type'] ?? ''}';
    final typeLabel = type.isEmpty ? '' : '${type[0].toUpperCase()}${type.substring(1)}';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _ouvrirRapport(_int(r['id'])),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.description_outlined, color: primaryColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rapport $typeLabel  #${r['id']}',
                      style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    'Du ${_fmtIsoDay(r['periode_debut'] as String?)} au ${_fmtIsoDay(r['periode_fin'] as String?)}'
                        '  •  généré le ${_fmtDateTime(r['created_at'] as String?)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            _miniStat('Activités', '${_int(r['total_activites'])}', primaryColor),
            _miniStat('Connexions', '${_int(r['total_connexions'])}', Colors.teal),
            _miniStat('Échecs', '${_int(r['total_echecs'])}', dangerColor),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 18),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 10.5)),
        ],
      ),
    );
  }

  // ============================================================
  // DÉTAIL D'UN RAPPORT (avec impression + export Excel)
  // ============================================================
  void _showRapportDetail(Map<String, dynamic> r, List<Map<String, dynamic>> activites) {
    final modules = List<Map<String, dynamic>>.from(r['repartition_modules'] ?? []);
    final pf = Map<String, dynamic>.from(r['etat_plateforme'] ?? {});

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.assessment_outlined, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rapport administrateur #${r['id']}',
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 3),
                          Text(
                            'Du ${_fmtIsoDay(r['periode_debut'] as String?)} au ${_fmtIsoDay(r['periode_fin'] as String?)}',
                            style: const TextStyle(color: Color(0xFFD6E2F0), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Imprimer',
                      onPressed: () async {
                        try {
                          await AdminRapportExport.imprimer(r, activites);
                        } catch (e) {
                          _snack('Impression impossible : $e', dangerColor);
                        }
                      },
                      icon: const Icon(Icons.print_outlined, color: Colors.white),
                    ),
                    IconButton(
                      tooltip: 'Exporter en Excel',
                      onPressed: () async {
                        try {
                          await AdminRapportExport.exporterExcel(r, activites);
                          _snack('Fichier Excel exporté.', accentColor);
                        } catch (e) {
                          _snack('Export impossible : $e', dangerColor);
                        }
                      },
                      icon: const Icon(Icons.table_chart_outlined, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _responsiveWrap([
                        _kpi(Icons.bolt_outlined, 'Activités', '${_int(r['total_activites'])}', primaryColor),
                        _kpi(Icons.admin_panel_settings_outlined, 'Admin', '${_int(r['activites_admin'])}',
                            primaryColor),
                        _kpi(Icons.manage_accounts_outlined, 'Responsables',
                            '${_int(r['activites_responsable'])}', accentColor),
                        _kpi(Icons.local_shipping_outlined, 'Chauffeurs', '${_int(r['activites_chauffeur'])}',
                            warningColor),
                        _kpi(Icons.login_outlined, 'Connexions', '${_int(r['total_connexions'])}', Colors.teal),
                        _kpi(Icons.error_outline, 'Échecs', '${_int(r['total_echecs'])}', dangerColor),
                      ], minWidth: 220),
                      if (pf.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _detailTitle('État de la plateforme à la génération'),
                        Text(
                          '${_int(pf['utilisateurs'])} utilisateurs  •  ${_int(pf['camions'])} camions  •  '
                              '${_int(pf['equipements'])} équipements  •  '
                              '${_int(pf['alertes_resolues'])}/${_int(pf['alertes'])} alertes résolues',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5),
                        ),
                      ],
                      if (modules.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _detailTitle('Modules les plus sollicités'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: modules
                              .map((m) => _pill('${m['module']}  •  ${m['total']}', primaryColor))
                              .toList(),
                        ),
                      ],
                      if ((r['notes'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _detailTitle('Observations'),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration:
                          BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(10)),
                          child: Text('${r['notes']}', style: const TextStyle(fontSize: 12.5, height: 1.4)),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _detailTitle('Activités de la période (${activites.length})'),
                      if (activites.isEmpty)
                        _empty('Aucune activité.')
                      else
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: activites.take(100).map((a) => _buildLogRow(a)).toList(),
                          ),
                        ),
                      if (activites.length > 100)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Affichage limité aux 100 premières activités. '
                                'L’impression et l’export Excel contiennent toutes les activités.',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
  );

  // ============================================================
  // COMPOSANTS COMMUNS
  // ============================================================
  Widget _empty(String msg) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 44, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(msg,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String msg, VoidCallback retry) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 44, color: dangerColor),
            const SizedBox(height: 10),
            Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}