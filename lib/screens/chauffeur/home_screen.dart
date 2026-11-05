import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/chauffeur_service.dart';

import 'package:geolocator/geolocator.dart';
import '../../services/signalement_service.dart';

import '../auth/login_screen.dart';
import 'alertes_screen.dart';
import 'missions_screen.dart';
import 'profil_screen.dart';
import 'suivi_gps_screen.dart';

class ChauffeurHomeScreen extends StatefulWidget {
  const ChauffeurHomeScreen({super.key});

  @override
  State<ChauffeurHomeScreen> createState() => _ChauffeurHomeScreenState();
}

class _ChauffeurHomeScreenState extends State<ChauffeurHomeScreen> {
  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  final ChauffeurService _chauffeurService = ChauffeurService();
  final SignalementService _signalementService = SignalementService();

  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _chauffeur;
  Map<String, dynamic>? _mission;
  Map<String, dynamic>? _camion;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  // ============================================================
  // CHARGEMENT DES DONNÉES
  // ============================================================

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Session utilisateur introuvable.';
      });

      return;
    }

    try {
      final response = await _chauffeurService.getMyChauffeur(token);

      if (!mounted) return;

      final rawData = response['data'];

      final data = rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : <String, dynamic>{};

      final rawChauffeur = data['chauffeur'];
      final rawMission = data['mission'];
      final rawCamion = data['camion'];

      setState(() {
        _chauffeur = rawChauffeur is Map
            ? Map<String, dynamic>.from(rawChauffeur)
            : null;

        _mission = rawMission is Map
            ? Map<String, dynamic>.from(rawMission)
            : null;

        _camion = rawCamion is Map
            ? Map<String, dynamic>.from(rawCamion)
            : null;

        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final user = authProvider.user;

    final userName = user != null && user.fullName.isNotEmpty
        ? user.fullName
        : 'Chauffeur';

    final token = authProvider.token;

    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: screenWidth < 360 ? 58 : 64,
        titleSpacing: screenWidth < 360 ? 12 : 16,

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SiraFleet',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: screenWidth < 360 ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Mon espace',
              style: TextStyle(
                fontSize: screenWidth < 360 ? 10 : 12,
              ),
            ),
          ],
        ),

        actions: [
          // ======================================================
          // NOTIFICATIONS
          // =====================================================

          // ======================================================
          // DÉCONNEXION
          // ======================================================

          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();

              if (!context.mounted) return;

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                    (route) => false,
              );
            },
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: _buildBody(
          userName,
          screenWidth,
          token,
        ),
      ),

      // ========================================================
      // NAVIGATION
      // ========================================================

      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: 0,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,

          selectedFontSize:
          screenWidth < 360 ? 10 : 12,

          unselectedFontSize:
          screenWidth < 360 ? 9 : 11,

          iconSize:
          screenWidth < 360 ? 21 : 24,

          elevation: 8,

          onTap: (index) {
            if (token == null || token.isEmpty) {
              _showMessage(
                context,
                'Session expirée.',
                dangerColor,
              );
              return;
            }

            switch (index) {
              case 1:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MissionsScreen(
                      token: token,
                    ),
                  ),
                );
                break;

              case 2:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SuiviGpsScreen(),
                  ),
                );
                break;

              case 3:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AlertesScreen(),
                  ),
                );
                break;

              case 4:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfilScreen(),
                  ),
                );
                break;
            }
          },

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
              icon: Icon(Icons.warning_amber_rounded),
              activeIcon: Icon(Icons.warning_amber_rounded),
              label: 'Alertes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody(
      String userName,
      double screenWidth,
      String? token,
      ) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 100),

            const Icon(
              Icons.error_outline,
              color: dangerColor,
              size: 60,
            ),

            const SizedBox(height: 16),

            const Text(
              'Impossible de charger vos informations',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('RÉESSAYER'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          screenWidth < 360 ? 12 : 16,
          16,
          screenWidth < 360 ? 12 : 16,
          25,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcome(
              userName,
              screenWidth,
            ),

            const SizedBox(height: 18),

            _buildStatusCard(
              screenWidth,
            ),

            const SizedBox(height: 22),

            _buildSectionTitle(
              'Ma mission',
              Icons.assignment_outlined,
              screenWidth,
            ),

            const SizedBox(height: 10),

            _buildMissionCard(
              context,
              screenWidth,
              token,
            ),

            const SizedBox(height: 22),

            _buildSectionTitle(
              'Mon camion',
              Icons.local_shipping_outlined,
              screenWidth,
            ),

            const SizedBox(height: 10),

            _buildTruckCard(
              screenWidth,
            ),

            const SizedBox(height: 22),

            _buildSectionTitle(
              'Que voulez-vous faire ?',
              Icons.touch_app_outlined,
              screenWidth,
            ),

            const SizedBox(height: 10),

            _buildQuickActions(
              context,
              screenWidth,
              token,
            ),

            const SizedBox(height: 22),

            _buildSOSButton(
              context,
              screenWidth,
            ),

            const SizedBox(height: 10),

            Text(
              'Utilisez SOS seulement en cas d’urgence.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: screenWidth < 360 ? 10 : 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BIENVENUE
  // ============================================================

  Widget _buildWelcome(
      String name,
      double width,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bonjour $name 👋',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: primaryColor,
            fontSize: width < 360 ? 20 : 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Voici votre journée.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUT
  // ============================================================

  Widget _buildStatusCard(
      double width,
      ) {
    final statut =
        _chauffeur?['statut']?.toString() ?? 'inactif';

    final actif = statut.toLowerCase() == 'actif';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        width < 360 ? 13 : 16,
      ),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: width < 360 ? 46 : 52,
            height: width < 360 ? 46 : 52,
            decoration: BoxDecoration(
              color: (actif ? accentColor : Colors.grey)
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              actif
                  ? Icons.check_circle
                  : Icons.pause_circle,
              color: actif ? accentColor : Colors.grey,
              size: width < 360 ? 27 : 30,
            ),
          ),

          SizedBox(
            width: width < 360 ? 10 : 13,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mon statut',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  actif ? 'En service' : 'Inactif',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: (actif ? accentColor : Colors.grey)
                  .withValues(alpha: 0.12),
              borderRadius:
              BorderRadius.circular(20),
            ),
            child: Text(
              actif ? 'ACTIF' : 'INACTIF',
              style: TextStyle(
                color: actif ? accentColor : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TITRE
  // ============================================================

  Widget _buildSectionTitle(
      String title,
      IconData icon,
      double width,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          color: primaryColor,
          size: width < 360 ? 20 : 21,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: primaryColor,
              fontSize: width < 360 ? 16 : 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MISSION
  // ============================================================

  Widget _buildMissionCard(
      BuildContext context,
      double width,
      String? token,
      ) {
    if (_mission == null) {
      return _buildEmptyCard(
        icon: Icons.assignment_outlined,
        title: 'Aucune mission',
        message:
        'Vous n’avez actuellement aucune mission affectée.',
      );
    }

    final reference =
        _mission!['reference']?.toString() ?? 'Mission';

    final statut =
        _mission!['statut']?.toString() ?? 'inconnu';

    final origine =
        _mission!['origine']?.toString() ??
            'Non renseigné';

    final destination =
        _mission!['destination']?.toString() ??
            'Non renseignée';

    final dateDepart =
    _formatDate(_mission!['date_depart']);

    final distance =
    _mission!['distance']?.toString();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        width < 360 ? 13 : 16,
      ),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mission #$reference',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(statut)
                      .withValues(alpha: 0.12),
                  borderRadius:
                  BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(statut),
                  style: TextStyle(
                    color: _statusColor(statut),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _buildRouteRow(
            icon: Icons.radio_button_checked,
            iconColor: accentColor,
            title: 'Départ',
            value: origine,
            screenWidth: width,
          ),

          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Container(
              height: 22,
              width: 2,
              color: Colors.grey.shade300,
            ),
          ),

          _buildRouteRow(
            icon: Icons.location_on,
            iconColor: dangerColor,
            title: 'Arrivée',
            value: destination,
            screenWidth: width,
          ),

          const SizedBox(height: 17),

          if (dateDepart != null || distance != null)
            Row(
              children: [
                if (dateDepart != null)
                  Expanded(
                    child: _buildMissionInfo(
                      Icons.access_time,
                      'Départ',
                      dateDepart,
                    ),
                  ),

                if (dateDepart != null &&
                    distance != null)
                  const SizedBox(width: 8),

                if (distance != null)
                  Expanded(
                    child: _buildMissionInfo(
                      Icons.route,
                      'Distance',
                      '$distance km',
                    ),
                  ),
              ],
            ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: token == null || token.isEmpty
                  ? null
                  : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MissionsScreen(
                      token: token,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.assignment,
                size: 20,
              ),
              label: const Text(
                'VOIR MA MISSION',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TRAJET
  // ============================================================

  Widget _buildRouteRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required double screenWidth,
  }) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: iconColor,
          size: screenWidth < 360 ? 20 : 22,
        ),

        SizedBox(
          width: screenWidth < 360 ? 9 : 12,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize:
                  screenWidth < 360 ? 10 : 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize:
                  screenWidth < 360 ? 14 : 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INFOS MISSION
  // ============================================================

  Widget _buildMissionInfo(
      IconData icon,
      String title,
      String value,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey.shade700,
          size: 20,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CAMION
  // ============================================================

  Widget _buildTruckCard(
      double width,
      ) {
    if (_camion == null) {
      return _buildEmptyCard(
        icon: Icons.local_shipping_outlined,
        title: 'Aucun camion',
        message:
        'Aucun camion n’est actuellement affecté à votre mission.',
      );
    }

    final immatriculation =
        _camion!['immatriculation']?.toString() ??
            _camion!['matricule']?.toString() ??
            'Non renseigné';

    final type =
        _camion!['type']?.toString() ?? 'Camion';

    final marque =
        _camion!['marque']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        width < 360 ? 13 : 16,
      ),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: width < 360 ? 48 : 55,
            height: width < 360 ? 48 : 55,
            decoration: BoxDecoration(
              color:
              primaryColor.withValues(alpha: 0.10),
              borderRadius:
              BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.local_shipping,
              color: primaryColor,
              size: width < 360 ? 27 : 30,
            ),
          ),

          SizedBox(
            width: width < 360 ? 11 : 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mon camion',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  immatriculation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  [
                    marque,
                    type,
                  ].where((element) => element.isNotEmpty).join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
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
  // ACTIONS RAPIDES
  // ============================================================

  Widget _buildQuickActions(
      BuildContext context,
      double width,
      String? token,
      ) {
    final actions = [
      _QuickActionData(
        icon: Icons.assignment,
        title: 'Missions',
        onTap: token == null || token.isEmpty
            ? () {}
            : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MissionsScreen(
                token: token,
              ),
            ),
          );
        },
      ),

      _QuickActionData(
        icon: Icons.location_on,
        title: 'GPS',
        onTap: token == null || token.isEmpty
            ? () {}
            : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SuiviGpsScreen(),
            ),
          );
        },
      ),

      _QuickActionData(
        icon: Icons.notifications,
        title: 'Alertes',
        onTap: token == null || token.isEmpty
            ? () {}
            : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AlertesScreen(),
            ),
          );
        },
      ),
    ];

    return Row(
      children: actions
          .map(
            (action) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right:
              action == actions.last ? 0 : 10,
            ),
            child: _buildActionCard(
              icon: action.icon,
              title: action.title,
              onTap: action.onTap,
              screenWidth: width,
            ),
          ),
        ),
      )
          .toList(),
    );
  }

  // ============================================================
  // ACTION CARD
  // ============================================================

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required double screenWidth,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 88,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color:
                Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: primaryColor,
                size: screenWidth < 380 ? 24 : 27,
              ),

              const SizedBox(height: 7),

              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: primaryColor,
                  fontSize:
                  screenWidth < 380 ? 11 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SOS
  // ============================================================

  Widget _buildSOSButton(
      BuildContext context,
      double width,
      ) {
    return SizedBox(
      width: double.infinity,
      height: width < 360 ? 56 : 60,
      child: ElevatedButton.icon(
        onPressed: () {
          _showSOSConfirmation(context);
        },
        icon: Icon(
          Icons.warning_rounded,
          size: width < 360 ? 25 : 29,
        ),
        label: Text(
          'SOS — URGENCE',
          style: TextStyle(
            fontSize: width < 360 ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: dangerColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONFIRMATION SOS
  // ============================================================

  void _showSOSConfirmation(
      BuildContext context,
      ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: dangerColor,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'SOS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Êtes-vous en situation d’urgence ?\n\n'
                'Votre position GPS sera envoyée au responsable.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('NON'),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await _sendSOS(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('OUI, SOS'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ENVOI SOS
  // ============================================================

 /* Future<void> _sendSOS(
      BuildContext context,
      ) async {
    final authProvider =
    context.read<AuthProvider>();

    final token = authProvider.token;

    if (token == null || token.isEmpty) {
      _showMessage(
        context,
        'Session expirée.',
        dangerColor,
      );
      return;
    }

    try {
      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!context.mounted) return;

      _showMessage(
        context,
        'SOS préparé. La position GPS sera envoyée.',
        dangerColor,
      );
    } catch (e) {
      if (!context.mounted) return;

      _showMessage(
        context,
        'Erreur lors de l’envoi du SOS.',
        dangerColor,
      );
    }
  }*/

  Future<void> _sendSOS(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;

    if (token == null || token.isEmpty) {
      _showMessage(context, 'Session expirée.', dangerColor);
      return;
    }

    final missionId = int.tryParse(_mission?['id']?.toString() ?? '');
    final camionId = int.tryParse(
      (_camion?['id'] ?? _mission?['camion_id'])?.toString() ?? '',
    );

    if (missionId == null || camionId == null) {
      _showMessage(context, 'Aucune mission active pour envoyer un SOS.', dangerColor);
      return;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Le GPS du téléphone est désactivé.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Permission de localisation refusée.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      await _signalementService.sendSos(
        token,
        missionId: missionId,
        camionId: camionId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!context.mounted) return;

      _showMessage(context, '🚨 SOS envoyé au responsable de flotte.', dangerColor);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AlertesScreen()),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showMessage(
        context,
        'Erreur lors de l\u2019envoi du SOS : ${e.toString().replaceFirst('Exception: ', '')}',
        dangerColor,
      );
    }
  }

  // ============================================================
  // EMPTY CARD
  // ============================================================

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(
            icon,
            size: 42,
            color: Colors.grey,
          ),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUT MISSION
  // ============================================================

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en_cours':
      case 'en cours':
        return Colors.orange;

      case 'terminee':
      case 'terminée':
      case 'completee':
      case 'complétée':
        return accentColor;

      case 'annulee':
      case 'annulée':
        return dangerColor;

      case 'planifiee':
      case 'planifiée':
        return Colors.blue;

      default:
        return Colors.blueGrey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'en_cours':
      case 'en cours':
        return 'EN COURS';

      case 'terminee':
      case 'terminée':
      case 'completee':
      case 'complétée':
        return 'TERMINÉE';

      case 'annulee':
      case 'annulée':
        return 'ANNULÉE';

      case 'planifiee':
      case 'planifiée':
        return 'PLANIFIÉE';

      default:
        return status.toUpperCase();
    }
  }

  // ============================================================
  // DATE
  // ============================================================

  String? _formatDate(dynamic value) {
    if (value == null) return null;

    try {
      final date =
      DateTime.parse(value.toString());

      final hour =
      date.hour.toString().padLeft(2, '0');

      final minute =
      date.minute.toString().padLeft(2, '0');

      return '$hour:$minute';
    } catch (_) {
      return value.toString();
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
      BuildContext context,
      String message,
      Color color,
      ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
  }

  // ============================================================
  // DÉCORATION
  // ============================================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 9,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

// ============================================================
// MODÈLE ACTION RAPIDE
// ============================================================

class _QuickActionData {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}