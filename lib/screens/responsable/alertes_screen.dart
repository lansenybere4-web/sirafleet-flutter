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

  // ============================================================
  // DONNÉES DE DÉMONSTRATION
  // ============================================================

  List<Map<String, dynamic>> signalements = [];

  bool isLoading = true;
  String? errorMessage;

  final SignalementService _signalementService =
  SignalementService();

  @override
  void initState() {
    super.initState();
    _loadSignalements();
  }

  Future<void> _loadSignalements() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final authProvider =
      Provider.of<AuthProvider>(context, listen: false);

      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        throw Exception('Utilisateur non authentifié.');
      }

      final data =
      await _signalementService.getSignalements(token);

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

        return {
          'id': item['id'],
          'chauffeur': user?['name'] ??
              chauffeur?['nom'] ??
              'Chauffeur inconnu',
          'camion': camion?['immatriculation'] ??
              camion?['numero'] ??
              'Camion inconnu',
          'mission': mission?['reference'] ??
              mission?['code'] ??
              mission?['id']?.toString() ??
              'N/A',
          'type': item['type'] ?? 'Autre',
          'message': item['description'] ??
              'Aucune description.',
          'heure': dateTime != null
              ? '${dateTime.hour.toString().padLeft(2, '0')}:'
              '${dateTime.minute.toString().padLeft(2, '0')}'
              : '--:--',
          'date': dateTime != null
              ? '${dateTime.day.toString().padLeft(2, '0')}/'
              '${dateTime.month.toString().padLeft(2, '0')}/'
              '${dateTime.year}'
              : 'Date inconnue',
          'statut': item['statut'] ?? 'Nouveau',
          'latitude': item['latitude'],
          'longitude': item['longitude'],
          'icon': _getSignalementIcon(
            item['type'] ?? 'Autre',
          ),
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        signalements = converted;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }
  /*IconData _getSignalementIcon(String type) {
    switch (type) {
      case 'Accident':
        return Icons.car_crash;

      case 'Problème camion':
        return Icons.local_shipping;

      case 'Problème route':
        return Icons.warning_amber;

      case 'Panne':
        return Icons.build;

      default:
        return Icons.report_problem;
    }
  }*/

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
      case 'SOS':                 // AJOUTÉ
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
      case 'SOS':                 // AJOUTÉ
        return dangerColor;
      default:
        return primaryColor;
    }
  }

  final List<String> statuses = [
    'Nouveau',
    'En cours',
    'Résolu',
  ];

  // ============================================================
  // FILTRAGE
  // ============================================================

  List<Map<String, dynamic>> get filteredSignalements {
    return signalements
        .where(
          (signalement) =>
      signalement['statut'] == statuses[selectedTab],
    )
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
              const ResponsableSidebar(
                current: ResponsableMenuItem.alertes,
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _buildDesktopContent(),
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Gestion des incidents de la flotte',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      drawer: const Drawer(
        child: ResponsableSidebar(
          current: ResponsableMenuItem.alertes,
        ),
      ),
      body: _buildMobileContent(),
    );
  }

  // ============================================================
  // CONTENU MOBILE
  // ============================================================

  Widget _buildMobileContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    return Column(
      children: [
        const SizedBox(height: 15),

        _buildStatistics(),

        const SizedBox(height: 15),

        _buildTabs(),

        const SizedBox(height: 12),

        Expanded(
          child: filteredSignalements.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              20,
            ),
            itemCount: filteredSignalements.length,
            itemBuilder: (context, index) {
              return _buildSignalementCard(
                filteredSignalements[index],
              );
            },
          ),
        ),
      ],
    );
  }
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: dangerColor,
            ),
            const SizedBox(height: 15),
            const Text(
              'Impossible de récupérer les signalements.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadSignalements,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
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

        const SizedBox(height: 24),

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
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
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
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
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
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF374151),
            ),
          ),

          const SizedBox(width: 8),

          const CircleAvatar(
            radius: 20,
            backgroundColor: primaryColor,
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
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
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),

        ElevatedButton.icon(
          onPressed: () {
            setState(() {});
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Actualiser'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatisticCard(
              'Nouveaux',
              nouveaux.toString(),
              dangerColor,
              Icons.notifications_active,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatisticCard(
              'En cours',
              enCours.toString(),
              warningColor,
              Icons.pending_actions,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatisticCard(
              'Résolus',
              resolus.toString(),
              accentColor,
              Icons.check_circle,
            ),
          ),
        ],
      ),
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
      _AlertStatData(
        title: 'Total signalements',
        value: '$total',
        icon: Icons.notifications_outlined,
        color: primaryColor,
      ),
      _AlertStatData(
        title: 'Nouveaux',
        value: '$nouveaux',
        icon: Icons.notifications_active,
        color: dangerColor,
      ),
      _AlertStatData(
        title: 'En cours',
        value: '$enCours',
        icon: Icons.pending_actions,
        color: warningColor,
      ),
      _AlertStatData(
        title: 'Résolus',
        value: '$resolus',
        icon: Icons.check_circle,
        color: accentColor,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 700
            ? 2
            : 1;

        const spacing = 16.0;

        final width =
            (constraints.maxWidth -
                (spacing * (columns - 1))) /
                columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((card) {
            return SizedBox(
              width: width,
              child: _buildDesktopStatCard(card),
            );
          }).toList(),
        );
      },
    );
  }

  // ============================================================
  // STAT CARD MOBILE
  // ============================================================

  Widget _buildStatisticCard(
      String title,
      String value,
      Color color,
      IconData icon,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 23,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STAT CARD DESKTOP
  // ============================================================

  Widget _buildDesktopStatCard(
      _AlertStatData data,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
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
            child: Icon(
              data.icon,
              color: data.color,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                data.value,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ONGLETS MOBILE
  // ============================================================

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _buildTab(
              index: 0,
              title: 'Nouveaux',
            ),
            _buildTab(
              index: 1,
              title: 'En cours',
            ),
            _buildTab(
              index: 2,
              title: 'Résolus',
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ONGLETS DESKTOP
  // ============================================================

  Widget _buildDesktopTabs() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          _buildDesktopTab(
            index: 0,
            title: 'Nouveaux',
            count: _countStatus('Nouveau'),
          ),
          _buildDesktopTab(
            index: 1,
            title: 'En cours',
            count: _countStatus('En cours'),
          ),
          _buildDesktopTab(
            index: 2,
            title: 'Résolus',
            count: _countStatus('Résolu'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB MOBILE
  // ============================================================

  Widget _buildTab({
    required int index,
    required String title,
  }) {
    final selected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : Colors.grey.shade700,
              fontSize: 12,
              fontWeight: selected
                  ? FontWeight.bold
                  : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TAB DESKTOP
  // ============================================================

  Widget _buildDesktopTab({
    required int index,
    required String title,
    required int count,
  }) {
    final selected = selectedTab == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            selectedTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: selected
                ? primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : const Color(0xFF374151),
                  fontWeight: selected
                      ? FontWeight.bold
                      : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.18)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : const Color(0xFF6B7280),
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
  // LISTE DES SIGNALEMENTS DESKTOP
  // ============================================================

  Widget _buildDesktopSignalements() {
    if (filteredSignalements.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Liste des signalements',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const Spacer(),
                Text(
                  '${filteredSignalements.length} signalement(s)',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const Divider(
            height: 1,
            color: Color(0xFFE5E7EB),
          ),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: filteredSignalements.length,
            separatorBuilder: (_, __) =>
            const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _buildSignalementCard(
                filteredSignalements[index],
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARTE SIGNALEMENT
  // ============================================================

  Widget _buildSignalementCard(
      Map<String, dynamic> signalement,
      ) {
    final type = signalement['type'] as String;
    final statut = signalement['statut'] as String;

    final color = _getSignalementColor(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
            MaterialPageRoute(
              builder: (_) => SignalementDetailScreen(
                signalement: signalement,
              ),
            ),
          );
          _loadSignalements(); // NOUVEAU : re-fetch la liste au retour
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ICÔNE
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  signalement['icon'] as IconData,
                  color: color,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              // CONTENU
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            type,
                            style: const TextStyle(
                              color: primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          signalement['heure'],
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Text(
                      signalement['chauffeur'],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '${signalement['camion']} • Mission ${signalement['mission']}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      signalement['message'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 9),

                    Row(
                      children: [
                        _buildStatusBadge(statut),
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                          size: 20,
                        ),
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

  // ============================================================
  // BADGE STATUT
  // ============================================================

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
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statut,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // COULEUR DU TYPE
  // ============================================================

  /*Color _getSignalementColor(String type) {
    switch (type) {
      case 'Accident':
        return dangerColor;

      case 'Problème camion':
        return Colors.orange;

      case 'Problème route':
        return Colors.deepOrange;

      case 'Panne':
        return Colors.blueGrey;

      default:
        return primaryColor;
    }
  }*/

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Accident':
        return dangerColor;
      case 'Problème camion':
        return Colors.orange;
      case 'Problème route':
        return Colors.deepOrange;
      case 'Panne':
        return Colors.blueGrey;
      case 'SOS':                 // AJOUTÉ
        return dangerColor;
      default:
        return primaryColor;
    }
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
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 65,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 15),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMPTER LES STATUTS
  // ============================================================

  int _countStatus(String status) {
    return signalements
        .where(
          (signalement) =>
      signalement['statut'] == status,
    )
        .length;
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