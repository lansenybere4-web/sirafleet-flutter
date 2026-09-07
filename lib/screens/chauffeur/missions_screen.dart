import 'package:flutter/material.dart';

import '../../models/mission.dart';
import '../../services/mission_service.dart';

import 'alertes_screen.dart';
import 'home_screen.dart';
import 'mission_detail_screen.dart';
import 'profil_screen.dart';
import 'suivi_gps_screen.dart';

class MissionsScreen extends StatefulWidget {
  final String token;

  const MissionsScreen({
    super.key,
    required this.token,
  });

  @override
  State<MissionsScreen> createState() =>
      _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  static const Color primaryColor =
  Color(0xFF1D3557);

  static const Color accentColor =
  Color(0xFF2A9D8F);

  static const Color backgroundColor =
  Color(0xFFF5F7FA);

  final MissionService _missionService =
  MissionService();

  int selectedTab = 0;

  bool isLoading = true;

  String? errorMessage;

  List<Mission> missions = [];

  static const List<String> statuses = [
    'Planifiée',
    'En cours',
    'Terminée',
  ];

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  // ============================================================
  // CHARGEMENT
  // ============================================================

  Future<void> _loadMissions() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result =
      await _missionService.getMissions(
        token: widget.token,
      );

      if (!mounted) return;

      setState(() {
        missions = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e
            .toString()
            .replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  // ============================================================
  // MISSIONS FILTRÉES
  // ============================================================

  List<Mission> get filteredMissions {
    final status = statuses[selectedTab];

    return missions
        .where(
          (mission) => mission.statut == status,
    )
        .toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              'Mes missions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Missions qui vous sont attribuées',
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loadMissions,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: Column(
        children: [
          const SizedBox(height: 14),

          _buildTabs(),

          const SizedBox(height: 14),

          Expanded(
            child: _buildBody(),
          ),
        ],
      ),

      bottomNavigationBar:
      BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _handleNavigation,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Missions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: 'GPS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            activeIcon: Icon(Icons.notifications),
            label: 'Alertes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (filteredMissions.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadMissions,
      child: ListView.builder(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          14,
          0,
          14,
          20,
        ),
        itemCount: filteredMissions.length,
        itemBuilder: (context, index) {
          return _buildMissionCard(
            context,
            filteredMissions[index],
          );
        },
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs() {
    return Padding(
      padding:
      const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildTab(
              index: 0,
              title: 'À venir',
            ),
            _buildTab(
              index: 1,
              title: 'En cours',
            ),
            _buildTab(
              index: 2,
              title: 'Terminées',
            ),
          ],
        ),
      ),
    );
  }

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
          duration:
          const Duration(milliseconds: 200),
          padding:
          const EdgeInsets.symmetric(
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: selected
                ? primaryColor
                : Colors.transparent,
            borderRadius:
            BorderRadius.circular(10),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : Colors.grey.shade700,
              fontWeight: selected
                  ? FontWeight.bold
                  : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CARTE MISSION
  // ============================================================

  Widget _buildMissionCard(
      BuildContext context,
      Mission mission,
      ) {
    final status = mission.statut;
    final statusColor =
    _getStatusColor(status);
    final statusIcon =
    _getStatusIcon(status);

    return Container(
      margin:
      const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(18),
        onTap: () =>
            _openMissionDetails(
              context,
              mission,
            ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // --------------------------------------------------
              // STATUT + REFERENCE
              // --------------------------------------------------

              Row(
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor
                          .withValues(alpha: 0.12),
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 15,
                          color: statusColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  Flexible(
                    child: Text(
                      mission.reference
                          .isEmpty
                          ? 'Sans référence'
                          : mission.reference,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 14,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // --------------------------------------------------
              // ORIGINE
              // --------------------------------------------------

              _buildPlace(
                icon:
                Icons.radio_button_checked,
                color: accentColor,
                label: 'Départ',
                value: mission.origine,
              ),

              Padding(
                padding:
                const EdgeInsets.only(left: 10),
                child: Container(
                  height: 24,
                  width: 2,
                  color: Colors.grey.shade300,
                ),
              ),

              // --------------------------------------------------
              // DESTINATION
              // --------------------------------------------------

              _buildPlace(
                icon: Icons.location_on,
                color: Colors.red,
                label: 'Arrivée',
                value: mission.destination,
              ),

              const SizedBox(height: 18),

              // --------------------------------------------------
              // INFOS
              // --------------------------------------------------

              Container(
                padding:
                const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSmallInfo(
                        Icons.local_shipping,
                        mission.camion.isEmpty
                            ? 'Non affecté'
                            : mission.camion,
                      ),
                    ),
                    Expanded(
                      child: _buildSmallInfo(
                        Icons.access_time,
                        mission.heure.isEmpty
                            ? '--:--'
                            : mission.heure,
                      ),
                    ),
                    Expanded(
                      child: _buildSmallInfo(
                        Icons.route,
                        mission.distance.isEmpty
                            ? 'N/A'
                            : mission.distance,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // --------------------------------------------------
              // DATE
              // --------------------------------------------------

              if (mission.date.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      mission.date,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),
                  ],
                ),

              if (mission.type.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        mission.type,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                          Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight:
                          FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14),

              // --------------------------------------------------
              // CHAUFFEUR
              // --------------------------------------------------

              if (mission.chauffeur.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 17,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Chauffeur : ${mission.chauffeur}',
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                          Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 14),

              // --------------------------------------------------
              // ACTION
              // --------------------------------------------------

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _openMissionDetails(
                        context,
                        mission,
                      ),
                  icon: Icon(
                    status == 'En cours'
                        ? Icons.location_on
                        : status == 'Terminée'
                        ? Icons
                        .description_outlined
                        : Icons
                        .visibility_outlined,
                  ),
                  label: Text(
                    status == 'En cours'
                        ? 'Voir la mission'
                        : status == 'Terminée'
                        ? 'Voir le rapport'
                        : 'Voir les détails',
                    style: const TextStyle(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  style:
                  OutlinedButton.styleFrom(
                    foregroundColor:
                    primaryColor,
                    side: BorderSide(
                      color: primaryColor
                          .withValues(alpha: 0.35),
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
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
  // LIEU
  // ============================================================

  Widget _buildPlace({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 21,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty
                    ? 'Non défini'
                    : value,
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PETITE INFO
  // ============================================================

  Widget _buildSmallInfo(
      IconData icon,
      String value,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: Colors.grey.shade700,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // COULEUR STATUT
  // ============================================================

  Color _getStatusColor(String status) {
    switch (status) {
      case 'En cours':
        return Colors.orange;

      case 'Terminée':
        return accentColor;

      case 'Annulée':
        return Colors.red;

      case 'Planifiée':
        return primaryColor;

      default:
        return primaryColor;
    }
  }

  // ============================================================
  // ICÔNE STATUT
  // ============================================================

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'En cours':
        return Icons.directions_car;

      case 'Terminée':
        return Icons.check_circle;

      case 'Annulée':
        return Icons.cancel;

      case 'Planifiée':
        return Icons.schedule;

      default:
        return Icons.schedule;
    }
  }

  // ============================================================
  // DÉTAIL MISSION
  // ============================================================

  Future<void> _openMissionDetails(
      BuildContext context,
      Mission mission,
      ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MissionDetailScreen(
              mission: mission.toDetailMap(),
              token: widget.token,
            ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadMissions();
    }
  }

  // ============================================================
  // ÉTAT VIDE
  // ============================================================

  Widget _buildEmptyState() {
    String message;

    switch (selectedTab) {
      case 0:
        message = 'Aucune mission à venir';
        break;

      case 1:
        message = 'Aucune mission en cours';
        break;

      default:
        message = 'Aucune mission terminée';
    }

    return RefreshIndicator(
      onRefresh: _loadMissions,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height:
            MediaQuery.of(context)
                .size
                .height *
                0.25,
          ),
          Padding(
            padding:
            const EdgeInsets.all(30),
            child: Column(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 70,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 15),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 15,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Les missions vous sont attribuées par le responsable de flotte.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
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
  // ERREUR
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 65,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage ??
                  'Impossible de récupérer les missions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _loadMissions,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style:
              ElevatedButton.styleFrom(
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
  // NAVIGATION
  // ============================================================

  void _handleNavigation(int index) {
    if (index == 1) {
      return;
    }

    Widget? screen;

    switch (index) {
      case 0:
        screen = const ChauffeurHomeScreen();
        break;

      case 2:
        screen = const SuiviGpsScreen();
        break;

      case 3:
        screen = const AlertesScreen();
        break;

      case 4:
        screen = const ProfilScreen();
        break;
    }

    if (screen == null || !mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => screen!,
      ),
    );
  }
}