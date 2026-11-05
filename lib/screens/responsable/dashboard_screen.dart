import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/sidebar_responsable.dart';
import '../auth/login_screen.dart';

class ResponsableDashboardScreen extends StatefulWidget {
  const ResponsableDashboardScreen({super.key});

  static const Color primaryColor = Color(0xFF1D3557);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  @override
  State<ResponsableDashboardScreen> createState() =>
      _ResponsableDashboardScreenState();
}

class _ResponsableDashboardScreenState
    extends State<ResponsableDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _dashboard = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboard());
  }

  // ============================================================
  // CHARGEMENT
  // ============================================================

  Future<void> _loadDashboard() async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;

    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await DashboardService.getResponsableDashboard(token);
      if (!mounted) return;
      setState(() {
        _dashboard = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final error = e.toString();

      if (error.contains('SESSION_EXPIREE')) {
        _redirectToLogin();
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.replaceFirst('Exception: ', '');
      });
    }
  }

  void _redirectToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  // ============================================================
  // HELPERS DE LECTURE
  // ============================================================

  int _int(String key) {
    final value = _dashboard[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<dynamic> _list(String key) {
    final value = _dashboard[key];
    return value is List ? value : [];
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final userName = context.select<AuthProvider, String>(
          (auth) => auth.user?.nom ?? 'Responsable',
    );

    return Scaffold(
      backgroundColor: ResponsableDashboardScreen.backgroundColor,
      body: Row(
        children: [
          const ResponsableSidebar(current: ResponsableMenuItem.dashboard),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, userName),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? _buildError()
                      : RefreshIndicator(
                    onRefresh: _loadDashboard,
                    child: SingleChildScrollView(
                      physics:
                      const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      child: _buildDashboardContent(userName),
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

  // ============================================================
  // TOP BAR (inchangée, juste le bouton actualiser en plus)
  // ============================================================

  Widget _buildTopBar(BuildContext context, String userName) {
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
            'Tableau de bord',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _isLoading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF374151)),
          ),

          const SizedBox(width: 18),
          CircleAvatar(
            radius: 20,
            backgroundColor: ResponsableDashboardScreen.primaryColor,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'R',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            userName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENU
  // ============================================================

  Widget _buildDashboardContent(String userName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bonjour $userName 👋',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Voici un aperçu de votre flotte aujourd’hui.',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        ),
        const SizedBox(height: 25),
        _buildKpiGrid(),
        const SizedBox(height: 25),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 850) {
              return Column(
                children: [
                  _buildRecentActivities(),
                  const SizedBox(height: 20),
                  _buildAlerts(),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildRecentActivities()),
                const SizedBox(width: 20),
                Expanded(child: _buildAlerts()),
              ],
            );
          },
        ),
        const SizedBox(height: 25),
        _buildFleetStatus(),
      ],
    );
  }

  // ============================================================
  // KPI (vraies données)
  // ============================================================

  Widget _buildKpiGrid() {
    final totalCamions = _int('total_camions');
    final enMission = _int('camions_en_mission');
    final enPanne = _int('camions_en_panne');
    final chauffeursActifs = _int('chauffeurs_actifs');

    final kpis = [
      _KpiData(
        title: 'Total camions',
        value: '$totalCamions',
        subtitle: 'Flotte complète',
        icon: Icons.local_shipping_rounded,
        color: ResponsableDashboardScreen.primaryColor,
      ),
      _KpiData(
        title: 'En mission',
        value: '$enMission',
        subtitle: 'Actuellement sur route',
        icon: Icons.route_rounded,
        color: const Color(0xFF2563EB),
      ),
      _KpiData(
        title: 'En panne',
        value: enPanne.toString().padLeft(2, '0'),
        subtitle: 'Nécessite une intervention',
        icon: Icons.build_circle_rounded,
        color: const Color(0xFFDC2626),
      ),
      _KpiData(
        title: 'Chauffeurs actifs',
        value: '$chauffeursActifs',
        subtitle: 'Disponibles aujourd’hui',
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF059669),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 18.0;
        final columns = constraints.maxWidth < 700
            ? 2
            : constraints.maxWidth < 1000
            ? 3
            : 4;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: kpis.map((kpi) {
            return SizedBox(
              width: cardWidth,
              child: KpiCard(
                title: kpi.title,
                value: kpi.value,
                subtitle: kpi.subtitle,
                icon: kpi.icon,
                color: kpi.color,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ============================================================
  // ACTIVITÉS RÉCENTES (vraies données)
  // ============================================================

  Widget _buildRecentActivities() {
    final activities = _list('activites_recentes');

    return _buildSectionCard(
      title: 'Activités récentes',
      icon: Icons.history_rounded,
      child: activities.isEmpty
          ? _buildEmptyState(
        icon: Icons.history_toggle_off_rounded,
        text: 'Aucune activité récente.',
      )
          : Column(
        children: activities
            .map((a) => _buildActivity(Map<String, dynamic>.from(a)))
            .toList(),
      ),
    );
  }

  Widget _buildActivity(Map<String, dynamic> activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ResponsableDashboardScreen.primaryColor.withValues(
                alpha: 0.08,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bolt_rounded,
              size: 19,
              color: ResponsableDashboardScreen.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (activity['title'] ?? '').toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  (activity['description'] ?? '').toString(),
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            (activity['date'] ?? '').toString(),
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ALERTES (vraies données)
  // ============================================================

  Widget _buildAlerts() {
    final alerts = _list('alertes_recentes');

    return _buildSectionCard(
      title: 'Alertes',
      icon: Icons.warning_amber_rounded,
      child: alerts.isEmpty
          ? _buildEmptyState(
        icon: Icons.check_circle_outline_rounded,
        text: 'Aucune alerte actuellement.',
      )
          : Column(
        children: alerts
            .map((a) => _buildAlert(Map<String, dynamic>.from(a)))
            .toList(),
      ),
    );
  }

  Widget _buildAlert(Map<String, dynamic> alert) {
    final niveau = (alert['niveau'] ?? 'info').toString();
    final color = switch (niveau) {
      'danger' => Colors.red,
      'warning' => Colors.orange,
      _ => Colors.blueGrey,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning_amber_rounded, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (alert['title'] ?? '').toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  (alert['subtitle'] ?? '').toString(),
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
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
  // ÉTAT DE LA FLOTTE (vraies données)
  // ============================================================

  Widget _buildFleetStatus() {
    final total = _int('total_camions');
    final disponibles = _int('camions_disponibles');
    final enMission = _int('camions_en_mission');
    final enPanne = _int('camions_en_panne');

    String pct(int value) =>
        total > 0 ? '${((value / total) * 100).round()}%' : '0%';

    return _buildSectionCard(
      title: 'État de la flotte',
      icon: Icons.donut_large_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final items = [
            _buildFleetItem(
              title: 'Disponibles',
              value: '$disponibles',
              percentage: pct(disponibles),
              color: Colors.green,
            ),
            _buildFleetItem(
              title: 'En mission',
              value: '$enMission',
              percentage: pct(enMission),
              color: Colors.blue,
            ),
            _buildFleetItem(
              title: 'En panne',
              value: '$enPanne',
              percentage: pct(enPanne),
              color: Colors.red,
            ),
          ];

          if (constraints.maxWidth < 600) {
            return Column(
              children: [
                for (final item in items) ...[item, const SizedBox(height: 10)],
              ],
            );
          }

          return Row(
            children: items.map((w) => Expanded(child: w)).toList(),
          );
        },
      ),
    );
  }

  Widget _buildFleetItem({
    required String title,
    required String value,
    required String percentage,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          const SizedBox(height: 5),
          Text(
            percentage,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION CARD / EMPTY STATE / ERREUR
  // ============================================================

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: ResponsableDashboardScreen.primaryColor, size: 20),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(color: Color(0xFFE5E7EB)),
          const SizedBox(height: 5),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF9CA3AF), size: 38),
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 430),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFC62828),
              size: 52,
            ),
            const SizedBox(height: 16),
            const Text(
              'Impossible de charger le dashboard',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Une erreur est survenue.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ResponsableDashboardScreen.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
