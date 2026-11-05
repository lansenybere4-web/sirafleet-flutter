/*import 'dart:async';

import 'package:flutter/material.dart';

import '../../widgets/sidebar_responsable.dart';
import 'signalement_detail_screen.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/signalement_service.dart';

class AlertesScreen extends StatefulWidget {
  const AlertesScreen({super.key});

  @override
  State<AlertesScreen> createState() => _AlertesScreenState();
}

class _AlertesScreenState extends State<AlertesScreen> {
  // ============================================================
  // COULEURS
  // ============================================================

  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color warningColor = Color(0xFFF4A261);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  // ============================================================
  // ÉTAT
  // ============================================================

  int selectedTab = 0;

  List<Map<String, dynamic>> signalements = [];

  bool isLoading = true;
  String? errorMessage;
  DateTime? _lastRefreshed;

  final SignalementService _signalementService = SignalementService();

  Timer? _autoRefreshTimer;

  final List<String> statuses = ['Nouveau', 'En cours', 'Résolu'];

  // ============================================================
  // INIT / DISPOSE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadSignalements();

    // Rafraîchissement automatique silencieux — essentiel pour ne
    // pas rater une alerte SOS déclenchée par un chauffeur.
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      _loadSignalements(silent: true);
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // CHARGEMENT
  // ============================================================

  Future<void> _loadSignalements({bool silent = false}) async {
    // En mode silencieux, on ne montre le loader plein écran que si
    // on n'a encore aucune donnée à afficher.
    if (!silent || signalements.isEmpty) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        throw Exception('Utilisateur non authentifié.');
      }

      final data = await _signalementService.getSignalements(token);

      final converted = data.map((item) {
        final chauffeur = item['chauffeur'];
        final user = chauffeur?['user'];
        final camion = item['camion'];
        final mission = item['mission'];

        final date = item['date_signalement'];
        DateTime? dateTime;

        if (date != null) {
          dateTime = DateTime.tryParse(date.toString());
        }

        final type = item['type'] ?? 'Autre';

        return {
          'id': item['id'],
          'chauffeur': user?['name'] ?? chauffeur?['nom'] ?? 'Chauffeur inconnu',
          'camion': camion?['immatriculation'] ?? camion?['numero'] ?? 'Camion inconnu',
          'mission': mission?['reference'] ??
              mission?['code'] ??
              mission?['id']?.toString() ??
              'N/A',
          'type': type,
          'message': item['description'] ?? 'Aucune description.',
          'heure': dateTime != null
              ? '${dateTime.hour.toString().padLeft(2, '0')}:'
              '${dateTime.minute.toString().padLeft(2, '0')}'
              : '--:--',
          'date': dateTime != null
              ? '${dateTime.day.toString().padLeft(2, '0')}/'
              '${dateTime.month.toString().padLeft(2, '0')}/'
              '${dateTime.year}'
              : 'Date inconnue',
          'dateTime': dateTime,
          'statut': item['statut'] ?? 'Nouveau',
          'latitude': item['latitude'],
          'longitude': item['longitude'],
          'icon': _getSignalementIcon(type),
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        signalements = converted;
        isLoading = false;
        errorMessage = null;
        _lastRefreshed = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        // En rafraîchissement silencieux, on garde les données déjà
        // affichées plutôt que de casser l'écran sur une erreur
        // réseau passagère.
        if (!silent) {
          errorMessage = e.toString().replaceFirst('Exception: ', '');
        }
      });
    }
  }

  // ============================================================
  // ICÔNES / COULEURS PAR TYPE
  // ============================================================

  IconData _getSignalementIcon(String type) {
    switch (type) {
      case 'Accident':
        return Icons.car_crash;
      case 'Problème camion':
        return Icons.local_shipping;
      case 'Problème route':
        return Icons.warning_amber;
      case 'Panne':
        return Icons.build;
      case 'SOS':
        return Icons.sos;
      default:
        return Icons.report_problem;
    }
  }

  Color _getSignalementColor(String type) {
    switch (type) {
      case 'Accident':
        return dangerColor;
      case 'Problème camion':
        return Colors.orange;
      case 'Problème route':
        return Colors.deepOrange;
      case 'Panne':
        return Colors.blueGrey;
      case 'SOS':
        return dangerColor;
      default:
        return primaryColor;
    }
  }

  // ============================================================
  // FILTRAGE / DONNÉES DÉRIVÉES
  // ============================================================

  List<Map<String, dynamic>> get filteredSignalements {
    return signalements
        .where((signalement) => signalement['statut'] == statuses[selectedTab])
        .toList();
  }

  List<Map<String, dynamic>> get activeSosAlerts {
    return signalements
        .where((s) => s['type'] == 'SOS' && s['statut'] != 'Résolu')
        .toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return _buildMobileLayout();
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          body: Row(
            children: [
              const ResponsableSidebar(current: ResponsableMenuItem.alertes),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: RefreshIndicator(
                        color: primaryColor,
                        onRefresh: () => _loadSignalements(silent: true),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          child: _buildDesktopContent(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // LAYOUT MOBILE
  // ============================================================

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alertes & Signalements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Gestion des incidents de la flotte',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: () => _loadSignalements(silent: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      drawer: const Drawer(
        child: ResponsableSidebar(current: ResponsableMenuItem.alertes),
      ),
      body: _buildMobileContent(),
    );
  }

  // ============================================================
  // CONTENU MOBILE
  // ============================================================

  Widget _buildMobileContent() {
    if (isLoading && signalements.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (errorMessage != null && signalements.isEmpty) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: () => _loadSignalements(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 20),
        children: [
          _buildLiveStatusBar(),
          const SizedBox(height: 14),
          if (activeSosAlerts.isNotEmpty) ...[
            _buildSosBanner(),
            const SizedBox(height: 15),
          ],
          _buildStatistics(),
          const SizedBox(height: 15),
          _buildTabs(),
          const SizedBox(height: 12),
          if (filteredSignalements.isEmpty)
            _buildEmptyState()
          else
            ...filteredSignalements.map(_buildSignalementCard),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: dangerColor),
            const SizedBox(height: 15),
            const Text(
              'Impossible de récupérer les signalements.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _loadSignalements(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BARRE "EN DIRECT"
  // ============================================================

  Widget _buildLiveStatusBar() {
    final label = _lastRefreshed != null
        ? 'Actualisé à ${_formatTime(_lastRefreshed!)}'
        : 'Synchronisation...';

    return Row(
      children: [
        _buildPulsingDot(color: accentColor),
        const SizedBox(width: 7),
        Text(
          'Suivi en direct',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '•  $label',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 10.5),
        ),
      ],
    );
  }

  Widget _buildPulsingDot({required Color color, double size = 8}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // ============================================================
  // BANNIÈRE SOS ACTIVE
  // ============================================================

  Widget _buildSosBanner() {
    final count = activeSosAlerts.length;
    final latest = activeSosAlerts.first;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SignalementDetailScreen(signalement: latest),
          ),
        );
        _loadSignalements(silent: true);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [dangerColor, Color(0xFFC1121F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: dangerColor.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sos, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count > 1
                        ? '$count alertes SOS actives'
                        : 'Alerte SOS active',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${latest['chauffeur']} • ${latest['camion']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CONTENU DESKTOP
  // ============================================================

  Widget _buildDesktopContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(),
        const SizedBox(height: 18),
        _buildLiveStatusBar(),
        const SizedBox(height: 20),
        if (activeSosAlerts.isNotEmpty) ...[
          _buildSosBanner(),
          const SizedBox(height: 20),
        ],
        _buildDesktopStatistics(),
        const SizedBox(height: 24),
        _buildDesktopTabs(),
        const SizedBox(height: 20),
        _buildDesktopSignalements(),
      ],
    );
  }

  // ============================================================
  // TOP BAR DESKTOP
  // ============================================================

  Widget _buildTopBar() {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          const Text(
            'Alertes & Signalements',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: dangerColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: dangerColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  '${_countStatus('Nouveau')} nouvelle(s)',
                  style: const TextStyle(
                    color: dangerColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: () => _loadSignalements(silent: true),
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF374151)),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 20,
            backgroundColor: primaryColor,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildPageHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alertes & Signalements',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Gérez les incidents et les signalements transmis par les chauffeurs.',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _loadSignalements(),
          icon: const Icon(Icons.refresh),
          label: const Text('Actualiser'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATISTIQUES MOBILE
  // ============================================================

  Widget _buildStatistics() {
    final nouveaux = _countStatus('Nouveau');
    final enCours = _countStatus('En cours');
    final resolus = _countStatus('Résolu');

    return Row(
      children: [
        Expanded(
          child: _buildStatisticCard('Nouveaux', nouveaux.toString(), dangerColor, Icons.notifications_active),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatisticCard('En cours', enCours.toString(), warningColor, Icons.pending_actions),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatisticCard('Résolus', resolus.toString(), accentColor, Icons.check_circle),
        ),
      ],
    );
  }

  // ============================================================
  // STATISTIQUES DESKTOP
  // ============================================================

  Widget _buildDesktopStatistics() {
    final nouveaux = _countStatus('Nouveau');
    final enCours = _countStatus('En cours');
    final resolus = _countStatus('Résolu');
    final total = signalements.length;

    final cards = [
      _AlertStatData(title: 'Total signalements', value: '$total', icon: Icons.notifications_outlined, color: primaryColor),
      _AlertStatData(title: 'Nouveaux', value: '$nouveaux', icon: Icons.notifications_active, color: dangerColor),
      _AlertStatData(title: 'En cours', value: '$enCours', icon: Icons.pending_actions, color: warningColor),
      _AlertStatData(title: 'Résolus', value: '$resolus', icon: Icons.check_circle, color: accentColor),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 700
            ? 2
            : 1;

        const spacing = 16.0;
        final width = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((card) {
            return SizedBox(width: width, child: _buildDesktopStatCard(card));
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatisticCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(height: 7),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDesktopStatCard(_AlertStatData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.color),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.title, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
              const SizedBox(height: 5),
              Text(
                data.value,
                style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ONGLETS
  // ============================================================

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          _buildTab(index: 0, title: 'Nouveaux'),
          _buildTab(index: 1, title: 'En cours'),
          _buildTab(index: 2, title: 'Résolus'),
        ],
      ),
    );
  }

  Widget _buildDesktopTabs() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          _buildDesktopTab(index: 0, title: 'Nouveaux', count: _countStatus('Nouveau')),
          _buildDesktopTab(index: 1, title: 'En cours', count: _countStatus('En cours')),
          _buildDesktopTab(index: 2, title: 'Résolus', count: _countStatus('Résolu')),
        ],
      ),
    );
  }

  Widget _buildTab({required int index, required String title}) {
    final selected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey.shade700,
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTab({required int index, required String title, required int count}) {
    final selected = selectedTab == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: selected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF374151),
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF6B7280),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LISTE DESKTOP
  // ============================================================

  Widget _buildDesktopSignalements() {
    if (filteredSignalements.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Liste des signalements',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                ),
                const Spacer(),
                Text(
                  '${filteredSignalements.length} signalement(s)',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: filteredSignalements.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _buildSignalementCard(filteredSignalements[index]),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARTE SIGNALEMENT
  // ============================================================

  Widget _buildSignalementCard(Map<String, dynamic> signalement) {
    final type = signalement['type'] as String;
    final statut = signalement['statut'] as String;
    final isSos = type == 'SOS';

    final color = _getSignalementColor(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSos ? Border.all(color: dangerColor.withValues(alpha: 0.35), width: 1.4) : null,
        boxShadow: [
          BoxShadow(
            color: (isSos ? dangerColor : Colors.black).withValues(alpha: isSos ? 0.10 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SignalementDetailScreen(signalement: signalement)),
          );
          _loadSignalements(silent: true);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(signalement['icon'] as IconData, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            type,
                            style: TextStyle(
                              color: isSos ? dangerColor : primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          signalement['heure'],
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      signalement['chauffeur'],
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${signalement['camion']} • Mission ${signalement['mission']}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      signalement['message'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 11, height: 1.3),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        _buildStatusBadge(statut),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String statut) {
    Color color;

    switch (statut) {
      case 'Nouveau':
        color = dangerColor;
        break;
      case 'En cours':
        color = warningColor;
        break;
      default:
        color = accentColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statut,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ============================================================
  // ÉTAT VIDE
  // ============================================================

  Widget _buildEmptyState() {
    String message;

    switch (selectedTab) {
      case 0:
        message = 'Aucun nouveau signalement.';
        break;
      case 1:
        message = 'Aucun signalement en cours.';
        break;
      default:
        message = 'Aucun signalement résolu.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 65, color: Colors.grey.shade400),
          const SizedBox(height: 15),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================

  int _countStatus(String status) {
    return signalements.where((s) => s['statut'] == status).length;
  }
}

// ============================================================
// MODÈLE STATISTIQUE
// ============================================================

class _AlertStatData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AlertStatData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}*/





import 'dart:async';

import 'package:flutter/material.dart';

import '../../widgets/sidebar_responsable.dart';
import 'signalement_detail_screen.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/signalement_service.dart';

class AlertesScreen extends StatefulWidget {
  const AlertesScreen({super.key});

  @override
  State<AlertesScreen> createState() => _AlertesScreenState();
}

class _AlertesScreenState extends State<AlertesScreen> {
  // ============================================================
  // COULEURS
  // ============================================================

  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color warningColor = Color(0xFFF4A261);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  // ============================================================
  // ÉTAT
  // ============================================================

  int selectedTab = 0;

  List<Map<String, dynamic>> signalements = [];

  bool isLoading = true;
  String? errorMessage;
  DateTime? _lastRefreshed;

  final SignalementService _signalementService = SignalementService();

  Timer? _autoRefreshTimer;

  final List<String> statuses = ['Nouveau', 'En cours', 'Résolu'];

  // ============================================================
  // INIT / DISPOSE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadSignalements();

    // Rafraîchissement automatique silencieux — essentiel pour ne
    // pas rater une alerte SOS déclenchée par un chauffeur.
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      _loadSignalements(silent: true);
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // CHARGEMENT
  // ============================================================

  Future<void> _loadSignalements({bool silent = false}) async {
    // En mode silencieux, on ne montre le loader plein écran que si
    // on n'a encore aucune donnée à afficher.
    if (!silent || signalements.isEmpty) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        throw Exception('Utilisateur non authentifié.');
      }

      final data = await _signalementService.getSignalements(token);

      final converted = data.map((item) {
        final chauffeur = item['chauffeur'];
        final user = chauffeur?['user'];
        final camion = item['camion'];
        final mission = item['mission'];

        final date = item['date_signalement'];
        DateTime? dateTime;

        if (date != null) {
          dateTime = DateTime.tryParse(date.toString());
        }

        final type = (item['type'] ?? 'Autre').toString();

        // Associer chaque signalement à son chauffeur et à la mission
        // réellement référencés par l'API, avec des replis si les relations
        // Eloquent ne sont pas chargées.
        final chauffeurId = chauffeur?['id'] ?? item['chauffeur_id'];
        final missionId = mission?['id'] ?? item['mission_id'];
        final missionReference = (mission?['reference'] ??
            mission?['code'] ??
            item['mission_reference'] ??
            item['mission_code'])
            ?.toString();
        final missionLabel = missionReference != null && missionReference.trim().isNotEmpty
            ? missionReference.trim()
            : missionId != null
            ? 'MISSION-${missionId.toString()}'
            : 'Non associée';

        return {
          'id': item['id'],
          'chauffeurId': chauffeurId,
          'chauffeur': user?['name'] ??
              chauffeur?['nom'] ??
              item['chauffeur_nom'] ??
              item['chauffeur_name'] ??
              (chauffeurId != null ? 'Chauffeur #$chauffeurId' : 'Chauffeur non identifié'),
          'camion': camion?['immatriculation'] ?? camion?['numero'] ?? item['camion_immatriculation'] ?? 'Camion non associé',
          'missionId': missionId,
          'missionReference': missionReference,
          'mission': missionLabel,
          'type': type,
          'message': item['description'] ?? 'Aucune description.',
          'heure': dateTime != null
              ? '${dateTime.hour.toString().padLeft(2, '0')}:'
              '${dateTime.minute.toString().padLeft(2, '0')}'
              : '--:--',
          'date': dateTime != null
              ? '${dateTime.day.toString().padLeft(2, '0')}/'
              '${dateTime.month.toString().padLeft(2, '0')}/'
              '${dateTime.year}'
              : 'Date inconnue',
          'dateTime': dateTime,
          'statut': item['statut'] ?? 'Nouveau',
          'latitude': item['latitude'],
          'longitude': item['longitude'],
          'icon': _getSignalementIcon(type),
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        signalements = converted;
        isLoading = false;
        errorMessage = null;
        _lastRefreshed = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        // En rafraîchissement silencieux, on garde les données déjà
        // affichées plutôt que de casser l'écran sur une erreur
        // réseau passagère.
        if (!silent) {
          errorMessage = e.toString().replaceFirst('Exception: ', '');
        }
      });
    }
  }

  // ============================================================
  // ICÔNES / COULEURS PAR TYPE
  // ============================================================

  IconData _getSignalementIcon(String type) {
    switch (type) {
      case 'Accident':
        return Icons.car_crash;
      case 'Problème camion':
        return Icons.local_shipping;
      case 'Problème route':
        return Icons.warning_amber;
      case 'Panne':
        return Icons.build;
      case 'SOS':
        return Icons.sos;
      default:
        return Icons.report_problem;
    }
  }

  Color _getSignalementColor(String type) {
    switch (type) {
      case 'Accident':
        return dangerColor;
      case 'Problème camion':
        return Colors.orange;
      case 'Problème route':
        return Colors.deepOrange;
      case 'Panne':
        return Colors.blueGrey;
      case 'SOS':
        return dangerColor;
      default:
        return primaryColor;
    }
  }

  // ============================================================
  // FILTRAGE / DONNÉES DÉRIVÉES
  // ============================================================

  List<Map<String, dynamic>> get filteredSignalements {
    return signalements
        .where((signalement) => signalement['statut'] == statuses[selectedTab])
        .toList();
  }

  List<Map<String, dynamic>> get activeSosAlerts {
    return signalements
        .where((s) => s['type'] == 'SOS' && s['statut'] != 'Résolu')
        .toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return _buildMobileLayout();
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          body: Row(
            children: [
              const ResponsableSidebar(current: ResponsableMenuItem.alertes),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: RefreshIndicator(
                        color: primaryColor,
                        onRefresh: () => _loadSignalements(silent: true),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          child: _buildDesktopContent(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // LAYOUT MOBILE
  // ============================================================

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alertes & Signalements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Gestion des incidents de la flotte',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      drawer: const Drawer(
        child: ResponsableSidebar(current: ResponsableMenuItem.alertes),
      ),
      body: _buildMobileContent(),
    );
  }

  // ============================================================
  // CONTENU MOBILE
  // ============================================================

  Widget _buildMobileContent() {
    if (isLoading && signalements.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (errorMessage != null && signalements.isEmpty) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: () => _loadSignalements(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 20),
        children: [
          _buildLiveStatusBar(),
          const SizedBox(height: 14),
          if (activeSosAlerts.isNotEmpty) ...[
            _buildSosBanner(),
            const SizedBox(height: 15),
          ],
          _buildStatistics(),
          const SizedBox(height: 15),
          _buildTabs(),
          const SizedBox(height: 12),
          if (filteredSignalements.isEmpty)
            _buildEmptyState()
          else
            ...filteredSignalements.map(_buildSignalementCard),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: dangerColor),
            const SizedBox(height: 15),
            const Text(
              'Impossible de récupérer les signalements.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _loadSignalements(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BARRE "EN DIRECT"
  // ============================================================

  Widget _buildLiveStatusBar() {
    final label = _lastRefreshed != null
        ? 'Actualisé à ${_formatTime(_lastRefreshed!)}'
        : 'Synchronisation...';

    return Row(
      children: [
        _buildPulsingDot(color: accentColor),
        const SizedBox(width: 7),
        Text(
          'Suivi en direct',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '•  $label',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 10.5),
        ),
      ],
    );
  }

  Widget _buildPulsingDot({required Color color, double size = 8}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // ============================================================
  // BANNIÈRE SOS ACTIVE
  // ============================================================

  Widget _buildSosBanner() {
    final count = activeSosAlerts.length;
    final latest = activeSosAlerts.first;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SignalementDetailScreen(signalement: latest),
          ),
        );
        _loadSignalements(silent: true);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [dangerColor, Color(0xFFC1121F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: dangerColor.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sos, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count > 1
                        ? '$count alertes SOS actives'
                        : 'Alerte SOS active',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${latest['chauffeur']} • ${latest['camion']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CONTENU DESKTOP
  // ============================================================

  Widget _buildDesktopContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(),
        const SizedBox(height: 18),
        _buildLiveStatusBar(),
        const SizedBox(height: 20),
        if (activeSosAlerts.isNotEmpty) ...[
          _buildSosBanner(),
          const SizedBox(height: 20),
        ],
        _buildDesktopStatistics(),
        const SizedBox(height: 24),
        _buildDesktopTabs(),
        const SizedBox(height: 20),
        _buildDesktopSignalements(),
      ],
    );
  }

  // ============================================================
  // TOP BAR DESKTOP
  // ============================================================

  Widget _buildTopBar() {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          const Text(
            'Alertes & Signalements',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: dangerColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: dangerColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  '${_countStatus('Nouveau')} nouvelle(s)',
                  style: const TextStyle(
                    color: dangerColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

  Widget _buildPageHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alertes & Signalements',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Gérez les incidents et les signalements transmis par les chauffeurs.',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATISTIQUES MOBILE
  // ============================================================

  Widget _buildStatistics() {
    final nouveaux = _countStatus('Nouveau');
    final enCours = _countStatus('En cours');
    final resolus = _countStatus('Résolu');

    return Row(
      children: [
        Expanded(
          child: _buildStatisticCard('Nouveaux', nouveaux.toString(), dangerColor, Icons.notifications_active),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatisticCard('En cours', enCours.toString(), warningColor, Icons.pending_actions),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatisticCard('Résolus', resolus.toString(), accentColor, Icons.check_circle),
        ),
      ],
    );
  }

  // ============================================================
  // STATISTIQUES DESKTOP
  // ============================================================

  Widget _buildDesktopStatistics() {
    final nouveaux = _countStatus('Nouveau');
    final enCours = _countStatus('En cours');
    final resolus = _countStatus('Résolu');
    final total = signalements.length;

    final cards = [
      _AlertStatData(title: 'Total signalements', value: '$total', icon: Icons.notifications_outlined, color: primaryColor),
      _AlertStatData(title: 'Nouveaux', value: '$nouveaux', icon: Icons.notifications_active, color: dangerColor),
      _AlertStatData(title: 'En cours', value: '$enCours', icon: Icons.pending_actions, color: warningColor),
      _AlertStatData(title: 'Résolus', value: '$resolus', icon: Icons.check_circle, color: accentColor),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 700
            ? 2
            : 1;

        const spacing = 16.0;
        final width = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((card) {
            return SizedBox(width: width, child: _buildDesktopStatCard(card));
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatisticCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(height: 7),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDesktopStatCard(_AlertStatData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.color),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.title, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
              const SizedBox(height: 5),
              Text(
                data.value,
                style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ONGLETS
  // ============================================================

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          _buildTab(index: 0, title: 'Nouveaux'),
          _buildTab(index: 1, title: 'En cours'),
          _buildTab(index: 2, title: 'Résolus'),
        ],
      ),
    );
  }

  Widget _buildDesktopTabs() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          _buildDesktopTab(index: 0, title: 'Nouveaux', count: _countStatus('Nouveau')),
          _buildDesktopTab(index: 1, title: 'En cours', count: _countStatus('En cours')),
          _buildDesktopTab(index: 2, title: 'Résolus', count: _countStatus('Résolu')),
        ],
      ),
    );
  }

  Widget _buildTab({required int index, required String title}) {
    final selected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey.shade700,
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTab({required int index, required String title, required int count}) {
    final selected = selectedTab == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: selected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF374151),
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF6B7280),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LISTE DESKTOP
  // ============================================================

  Widget _buildDesktopSignalements() {
    if (filteredSignalements.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Liste des signalements',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                ),
                const Spacer(),
                Text(
                  '${filteredSignalements.length} signalement(s)',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: filteredSignalements.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _buildSignalementCard(filteredSignalements[index]),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARTE SIGNALEMENT
  // ============================================================

  Widget _buildSignalementCard(Map<String, dynamic> signalement) {
    final type = (signalement['type'] ?? 'Autre').toString();
    final statut = (signalement['statut'] ?? 'Nouveau').toString();
    final isSos = type == 'SOS';
    final color = _getSignalementColor(type);
    final signalementId = signalement['id']?.toString() ?? '—';
    final chauffeur = (signalement['chauffeur'] ?? 'Chauffeur non identifié').toString();
    final camion = (signalement['camion'] ?? 'Camion non associé').toString();
    final mission = (signalement['mission'] ?? 'Non associée').toString();
    final description = (signalement['message'] ?? 'Aucune description.').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSos ? dangerColor.withValues(alpha: 0.38) : const Color(0xFFE8ECF2),
          width: isSos ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isSos ? dangerColor : Colors.black).withValues(alpha: isSos ? 0.08 : 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SignalementDetailScreen(signalement: signalement),
            ),
          );
          if (mounted) _loadSignalements(silent: true);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(signalement['icon'] is IconData ? signalement['icon'] as IconData : Icons.report_problem, color: color, size: 23),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                type,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSos ? dangerColor : primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(statut),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Signalement #$signalementId  •  ${signalement['date'] ?? 'Date inconnue'} à ${signalement['heure'] ?? '--:--'}',
                          style: const TextStyle(color: Color(0xFF7B8494), fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEDF0F5)),
                ),
                child: Column(
                  children: [
                    _buildAssociationLine(
                      icon: Icons.person_outline_rounded,
                      label: 'Chauffeur concerné',
                      value: chauffeur,
                      valueColor: primaryColor,
                    ),
                    const SizedBox(height: 10),
                    _buildAssociationLine(
                      icon: Icons.local_shipping_outlined,
                      label: 'Camion',
                      value: camion,
                    ),
                    const SizedBox(height: 10),
                    _buildAssociationLine(
                      icon: Icons.route_outlined,
                      label: 'Référence de mission',
                      value: mission,
                      valueColor: mission == 'Non associée' ? dangerColor : accentColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 11),
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12, height: 1.45),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.open_in_new_rounded, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 5),
                  Text(
                    'Ouvrir la conversation et les détails',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssociationLine({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF7B8494)),
        const SizedBox(width: 9),
        SizedBox(
          width: 128,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF7B8494), fontSize: 11, height: 1.35),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF273449),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String statut) {
    Color color;

    switch (statut) {
      case 'Nouveau':
        color = dangerColor;
        break;
      case 'En cours':
        color = warningColor;
        break;
      default:
        color = accentColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statut,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ============================================================
  // ÉTAT VIDE
  // ============================================================

  Widget _buildEmptyState() {
    String message;

    switch (selectedTab) {
      case 0:
        message = 'Aucun nouveau signalement.';
        break;
      case 1:
        message = 'Aucun signalement en cours.';
        break;
      default:
        message = 'Aucun signalement résolu.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 65, color: Colors.grey.shade400),
          const SizedBox(height: 15),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================

  int _countStatus(String status) {
    return signalements.where((s) => s['statut'] == status).length;
  }
}

// ============================================================
// MODÈLE STATISTIQUE
// ============================================================

class _AlertStatData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AlertStatData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
