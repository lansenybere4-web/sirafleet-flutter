/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../models/role_model.dart';
import '../../models/camion_model.dart';
import '../../models/equipement_model.dart';
import '../../models/alerte_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../services/camion_service.dart';
import '../../services/equipement_service.dart';
import '../../services/signalement_service.dart';
import '../../widgets/sidebar_admin.dart';
import 'utilisateurs_screen.dart';
import 'equipements_screen.dart';
import 'alertes_systeme_screen.dart';
import 'camions_admin_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color warningColor = Color(0xFFF4A261);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color borderColor = Color(0xFFE7ECF2);
  static const Color mutedColor = Color(0xFF748094);

  final UserService _userService = UserService();
  final CamionService _camionService = CamionService();
  final EquipementService _equipementService = EquipementService();
  final SignalementService _signalementService = SignalementService();

  List<UserModel> _users = [];
  List<RoleModel> _roles = [];
  List<Camion> _camions = [];
  List<EquipementModel> _equipements = [];
  List<AlerteModel> _alertes = [];

  bool _loadingDashboard = true;
  bool _dashboardLoadFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboard());
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;

    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      setState(() {
        _loadingDashboard = false;
        _dashboardLoadFailed = true;
      });
      return;
    }

    setState(() {
      _loadingDashboard = true;
      _dashboardLoadFailed = false;
    });

    try {
      final results = await Future.wait<dynamic>([
        _userService.getUsers(token),
        _userService.getRoles(token),
        _camionService.getCamions(token: token),
        _equipementService.getEquipements(token: token),
        _signalementService.getSignalements(token),
      ]);

      if (!mounted) return;

      final rawReports = results[4] as List<Map<String, dynamic>>;
      setState(() {
        _users = results[0] as List<UserModel>;
        _roles = results[1] as List<RoleModel>;
        _camions = results[2] as List<Camion>;
        _equipements = results[3] as List<EquipementModel>;
        _alertes = rawReports.map(AlerteModel.fromJson).toList();
        _loadingDashboard = false;
        _dashboardLoadFailed = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Erreur chargement dashboard admin : $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _loadingDashboard = false;
        _dashboardLoadFailed = true;
      });
    }
  }

  String _roleNameFromUser(UserModel user) {
    final directRole = user.role.trim();
    if (directRole.isNotEmpty) return directRole.toUpperCase();

    final match = _roles.where((role) => role.id == user.roleId);
    return match.isNotEmpty ? match.first.name.toUpperCase() : '';
  }

  @override
  Widget build(BuildContext context) {
    final totalUsers = _users.length;
    final usersActifs = _users.where((u) => u.statut.toLowerCase() == 'actif').length;
    final usersInactifs = _users.where((u) => u.statut.toLowerCase() == 'inactif').length;
    final responsables = _users.where((u) {
      final role = _roleNameFromUser(u);
      return role == 'RESPONSABLE' || role == 'RESPONSABLE DE FLOTTE';
    }).length;
    final chauffeurs = _users.where((u) => _roleNameFromUser(u) == 'CHAUFFEUR').length;

    final totalVehicules = _camions.length;
    final vehiculesEnCirculation = _camions.where((c) => c.statut == 'en_circulation').length;
    final vehiculesEnPanne = _camions.where((c) => c.statut == 'en_panne').length;
    final vehiculesMaintenance = _camions.where((c) => c.statut == 'maintenance').length;

    final totalEquipements = _equipements.length;
    final equipementsActifs = _equipements.where((e) => e.statut == 'actif').length;
    final equipementsEnPanne = _equipements.where((e) => e.statut == 'en_panne').length;
    final equipementsARemplacer = _equipements.where((e) => e.statut == 'a_remplacer').length;

    final totalAlertes = _alertes.length;
    final alertesNouvelles = _alertes.where((a) => a.statut == 'Nouveau').length;
    final alertesTraitees = _alertes.where((a) => a.statut == 'Résolu').length;
    final alertesCritiques = _alertes
        .where((a) => a.gravite == 'critique' && a.statut != 'Résolu')
        .length;

    final problemesTechniques =
        vehiculesEnPanne + equipementsEnPanne + equipementsARemplacer + alertesCritiques;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          const SidebarAdmin(selectedIndex: 0),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _loadingDashboard
                      ? const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  )
                      : RefreshIndicator(
                    onRefresh: _loadDashboard,
                    color: primaryColor,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(28, 26, 28, 32),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1500),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPageIntro(),
                              const SizedBox(height: 22),
                              if (_dashboardLoadFailed) ...[
                                _buildErrorBanner(),
                                const SizedBox(height: 18),
                              ],
                              _buildGlobalStatus(
                                totalUsers: totalUsers,
                                totalVehicules: totalVehicules,
                                totalEquipements: totalEquipements,
                                totalAlertes: totalAlertes,
                                problemesTechniques: problemesTechniques,
                              ),
                              const SizedBox(height: 22),
                              _buildSectionTitle(
                                'Vue d’ensemble',
                                subtitle: 'Les principaux indicateurs de votre flotte',
                              ),
                              const SizedBox(height: 14),

                              // ==================================================
                              // KPI (cartes compactes, hauteur fixe)
                              // ==================================================
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final columns = constraints.maxWidth >= 1150
                                      ? 4
                                      : constraints.maxWidth >= 650
                                      ? 2
                                      : 1;
                                  return GridView(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      mainAxisExtent: 92, // hauteur fixe
                                    ),
                                    children: [
                                      _buildKpi(
                                        icon: Icons.people_alt_outlined,
                                        title: 'Utilisateurs',
                                        value: '$totalUsers',
                                        subtitle: '$usersActifs actifs · $usersInactifs inactifs',
                                        color: primaryColor,
                                      ),
                                      _buildKpi(
                                        icon: Icons.local_shipping_outlined,
                                        title: 'Véhicules',
                                        value: '$totalVehicules',
                                        subtitle: '$vehiculesEnCirculation en circulation · $vehiculesEnPanne en panne',
                                        color: accentColor,
                                      ),
                                      _buildKpi(
                                        icon: Icons.memory_rounded,
                                        title: 'Équipements',
                                        value: '$totalEquipements',
                                        subtitle: '$equipementsActifs actifs · $equipementsEnPanne en panne',
                                        color: warningColor,
                                      ),
                                      _buildKpi(
                                        icon: Icons.notifications_active_outlined,
                                        title: 'Alertes non résolues',
                                        value: '$alertesNouvelles',
                                        subtitle: '$alertesCritiques critiques · $alertesTraitees résolues',
                                        color: dangerColor,
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 28),
                              _buildSectionTitle(
                                'Accès rapides',
                                subtitle: 'Accédez directement aux principales fonctions',
                              ),
                              const SizedBox(height: 14),
                              _buildQuickActions(context),
                              const SizedBox(height: 28),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final technical = _buildSystemStatus(
                                    vehiculesEnCirculation,
                                    vehiculesEnPanne,
                                    vehiculesMaintenance,
                                    equipementsActifs,
                                    equipementsEnPanne,
                                    equipementsARemplacer,
                                    alertesCritiques,
                                  );
                                  final accounts = _buildUserSummary(
                                    totalUsers,
                                    usersActifs,
                                    usersInactifs,
                                    responsables,
                                    chauffeurs,
                                  );
                                  if (constraints.maxWidth < 850) {
                                    return Column(
                                      children: [
                                        technical,
                                        const SizedBox(height: 18),
                                        accounts,
                                      ],
                                    );
                                  }
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: technical),
                                      const SizedBox(width: 18),
                                      Expanded(child: accounts),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildHeader() {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.space_dashboard_rounded, color: primaryColor),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Administration',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Supervision de la plateforme SiraFleet',
                  style: TextStyle(color: mutedColor, fontSize: 11),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Actualiser les données',
            child: Material(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _loadingDashboard ? null : _loadDashboard,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.refresh_rounded,
                    color: _loadingDashboard ? mutedColor : primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIntro() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour, Administrateur 👋',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: compact ? 23 : 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Voici un aperçu de l’activité et de l’état technique de SiraFleet.',
                    style: TextStyle(color: mutedColor, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: accentColor, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Espace sécurisé',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        border: Border.all(color: dangerColor.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: dangerColor),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Impossible de charger certaines données depuis le serveur. Vérifie la connexion puis réessaie.',
              style: TextStyle(color: dangerColor, fontSize: 12, height: 1.4),
            ),
          ),
          TextButton(
            onPressed: _loadDashboard,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalStatus({
    required int totalUsers,
    required int totalVehicules,
    required int totalEquipements,
    required int totalAlertes,
    required int problemesTechniques,
  }) {
    final ok = problemesTechniques == 0 && !_dashboardLoadFailed;
    final color = ok ? accentColor : dangerColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              ok ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ok ? 'État général de la plateforme' : 'Vérification nécessaire',
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _dashboardLoadFailed
                      ? 'Les données ne sont pas toutes disponibles. Vérifie la connexion à l’API.'
                      : ok
                      ? 'Aucune anomalie technique détectée selon les indicateurs disponibles.'
                      : '$problemesTechniques problème(s) technique(s) à vérifier.',
                  style: const TextStyle(color: mutedColor, fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 13),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSummaryChip(Icons.people_outline_rounded, '$totalUsers utilisateurs'),
                    _buildSummaryChip(Icons.local_shipping_outlined, '$totalVehicules véhicules'),
                    _buildSummaryChip(Icons.memory_rounded, '$totalEquipements équipements'),
                    _buildSummaryChip(Icons.notifications_none_rounded, '$totalAlertes alertes'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: primaryColor,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: mutedColor, fontSize: 12),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // KPI (compact : icône à gauche, texte à droite)
  // ============================================================

  Widget _buildKpi({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: mutedColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: mutedColor, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1050
              ? 3
              : constraints.maxWidth >= 600
              ? 2
              : 1;
          final itemWidth = (constraints.maxWidth - (columns - 1) * 13) / columns;
          return Wrap(
            spacing: 13,
            runSpacing: 13,
            children: [
              SizedBox(
                width: itemWidth,
                child: _buildAction(
                  icon: Icons.people_alt_outlined,
                  title: 'Utilisateurs',
                  subtitle: 'Créer, modifier ou désactiver les comptes',
                  color: primaryColor,
                  onTap: () => _openPage(context, const UtilisateursScreen()),
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildAction(
                  icon: Icons.local_shipping_outlined,
                  title: 'Véhicules',
                  subtitle: 'Gérer les camions et leurs informations',
                  color: accentColor,
                  onTap: () => _openPage(context, const CamionsAdminScreen()),
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildAction(
                  icon: Icons.memory_rounded,
                  title: 'Équipements',
                  subtitle: 'Consulter les équipements embarqués',
                  color: warningColor,
                  onTap: () => _openPage(context, const EquipementsScreen()),
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildAction(
                  icon: Icons.notifications_active_outlined,
                  title: 'Alertes système',
                  subtitle: 'Consulter les signalements et alertes',
                  color: dangerColor,
                  onTap: () => _openPage(context, const AlertesSystemeScreen()),
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildAction(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Rôles et permissions',
                  subtitle: 'Gestion à connecter à un écran dédié',
                  color: primaryColor,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('La gestion des rôles et permissions sera disponible prochainement.'),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openPage(BuildContext context, Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    if (mounted) await _loadDashboard();
  }

  Widget _buildAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFFBFCFE),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: mutedColor, fontSize: 10, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              const Icon(Icons.chevron_right_rounded, color: mutedColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemStatus(
      int vehiculesEnCirculation,
      int vehiculesEnPanne,
      int vehiculesMaintenance,
      int equipementsActifs,
      int equipementsEnPanne,
      int equipementsARemplacer,
      int alertesCritiques,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelHeading(Icons.monitor_heart_outlined, 'État technique', 'Indicateurs de fonctionnement'),
          const SizedBox(height: 20),
          _buildStatus('API Laravel', _dashboardLoadFailed ? 'À vérifier' : 'Connectée', _dashboardLoadFailed ? dangerColor : accentColor),
          _buildStatus('Véhicules en circulation', '$vehiculesEnCirculation', accentColor),
          _buildStatus('Véhicules en panne', '$vehiculesEnPanne', vehiculesEnPanne == 0 ? accentColor : dangerColor),
          _buildStatus('En maintenance', '$vehiculesMaintenance', vehiculesMaintenance == 0 ? accentColor : warningColor),
          _buildStatus('Équipements actifs', '$equipementsActifs', accentColor),
          _buildStatus('Équipements en panne', '$equipementsEnPanne', equipementsEnPanne == 0 ? accentColor : dangerColor),
          _buildStatus('À remplacer', '$equipementsARemplacer', equipementsARemplacer == 0 ? accentColor : warningColor),
          _buildStatus('Alertes critiques ouvertes', '$alertesCritiques', alertesCritiques == 0 ? accentColor : dangerColor),
        ],
      ),
    );
  }

  Widget _buildUserSummary(
      int total,
      int actifs,
      int inactifs,
      int responsables,
      int chauffeurs,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelHeading(Icons.groups_outlined, 'Comptes utilisateurs', 'Répartition des accès'),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_alt_rounded, color: primaryColor, size: 25),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Comptes enregistrés',
                    style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '$total',
                  style: const TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _buildStatus('Comptes actifs', '$actifs', accentColor),
          _buildStatus('Comptes inactifs', '$inactifs', inactifs == 0 ? accentColor : warningColor),
          _buildStatus('Responsables de flotte', '$responsables', primaryColor),
          _buildStatus('Chauffeurs', '$chauffeurs', primaryColor),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : (actifs / total).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: borderColor,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            total == 0 ? 'Aucun compte disponible' : '${((actifs / total) * 100).round()} % des comptes sont actifs',
            style: const TextStyle(color: mutedColor, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _panelHeading(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: primaryColor, size: 21),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: primaryColor, fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(color: mutedColor, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatus(String title, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              status,
              textAlign: TextAlign.right,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.025),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/admin_rapport_service.dart';
import '../../widgets/sidebar_admin.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color warningColor = Color(0xFFF4A261);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color borderColor = Color(0xFFE5E7EB);

  final List<String> _periodes = ['Journalier', 'Hebdomadaire', 'Mensuel', 'Annuel', 'Personnalisé'];
  String _periode = 'Hebdomadaire';
  DateTimeRange? _custom;

  Map<String, dynamic>? _stats;
  bool _loadingStats = true;
  String? _errorStats;

  AdminRapportService get _service =>
      AdminRapportService(token: context.read<AuthProvider>().token ?? '');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStats());
  }

  // ---------- Période ----------
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
      default:
        return DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today);
    }
  }

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
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
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

  // ---------- Helpers ----------
  String _two(int n) => n.toString().padLeft(2, '0');
  String _fmtDay(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';
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

  BoxDecoration _cardDecoration({double radius = 16}) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor),
    boxShadow: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
    ],
  );

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          const SidebarAdmin(selectedIndex: 0),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: RefreshIndicator(
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
                            const Padding(
                                padding: EdgeInsets.all(60),
                                child: Center(child: CircularProgressIndicator()))
                          else if (_errorStats != null)
                            _buildError(_errorStats!, _loadStats)
                          else if (_stats != null) ...[
                              _buildKpis(),
                              const SizedBox(height: 22),
                              _buildChartAndRoles(),
                              const SizedBox(height: 22),
                              _buildModules(),
                            ],
                          const SizedBox(height: 20),
                        ],
                      ),
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
          const Text('Tableau de bord',
              style: TextStyle(color: primaryColor, fontSize: 21, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loadingStats ? null : _loadStats,
            icon: const Icon(Icons.refresh_outlined, color: primaryColor),
          ),
        ],
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
                Text('Vue d’ensemble de la plateforme',
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

  // ---------- Graphique + rôles ----------
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
      if (raw.length == 7) return '${raw.substring(5)}/${raw.substring(2, 4)}';
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
                  Text('$v',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(height: 4),
                  Container(
                    height: h,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                      gradient: LinearGradient(
                        colors: [accentColor, Color(0xFF52C4B6)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(label('${j['jour']}'),
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
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
              Expanded(
                  child: Text(st.label,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
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

  // ---------- Modules ----------
  Widget _buildModules() {
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
                    value: maxV == 0 ? 0 : v / maxV,
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

  // ---------- Composants communs ----------
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

