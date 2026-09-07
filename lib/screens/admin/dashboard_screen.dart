import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../models/user_model.dart';
import '../../models/role_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/sidebar_admin.dart';
import 'utilisateurs_screen.dart';
import 'equipements_screen.dart';
import 'alertes_systeme_screen.dart';
import 'camions_admin_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // ============================================================
  // COULEURS
  // ============================================================

  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color warningColor = Color(0xFFF4A261);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  // ============================================================
  // SERVICES
  // ============================================================

  final UserService _userService = UserService();

  // ============================================================
  // UTILISATEURS
  // ============================================================

  List<UserModel> _users = [];
  List<RoleModel> _roles = [];

  bool _loadingUsers = true;
  bool _usersLoadFailed = false;

  // ============================================================
  // ÉQUIPEMENTS TEMPORAIRES
  // ============================================================
  //
  // Pour le moment, les équipements ne sont pas encore récupérés
  // depuis Laravel.
  //
  // Quand l'API Equipements sera prête, cette liste sera remplacée
  // par UserService/EquipementService.
  // ============================================================

  final List<Map<String, dynamic>> _equipements = [
    {
      'id': 1,
      'nom': 'GPS NEO-6M',
      'statut': 'actif',
    },
    {
      'id': 2,
      'nom': 'Sonde carburant',
      'statut': 'actif',
    },
    {
      'id': 3,
      'nom': 'Caméra IA',
      'statut': 'en_panne',
    },
    {
      'id': 4,
      'nom': 'Lecteur RFID',
      'statut': 'actif',
    },
  ];

  // ============================================================
  // ALERTES TEMPORAIRES
  // ============================================================

  final List<Map<String, dynamic>> _alertes = [
    {
      'id': 1,
      'statut': 'nouvelle',
      'gravite': 'critique',
    },
    {
      'id': 2,
      'statut': 'nouvelle',
      'gravite': 'normale',
    },
    {
      'id': 3,
      'statut': 'traitee',
      'gravite': 'normale',
    },
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }

  // ============================================================
  // CHARGEMENT DES UTILISATEURS
  // ============================================================

  Future<void> _loadUsers() async {
    if (!mounted) return;

    final token = context.read<AuthProvider>().token;

    if (token == null || token.isEmpty) {
      setState(() {
        _loadingUsers = false;
        _usersLoadFailed = true;
      });

      return;
    }

    setState(() {
      _loadingUsers = true;
      _usersLoadFailed = false;
    });

    try {
      final users = await _userService.getUsers(token);
      final roles = await _userService.getRoles(token);

      if (!mounted) return;

      setState(() {
        _users = users;
        _roles = roles;
        _loadingUsers = false;
        _usersLoadFailed = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement dashboard utilisateurs : $e');

      if (!mounted) return;

      setState(() {
        _loadingUsers = false;
        _usersLoadFailed = true;
      });
    }
  }

  // ============================================================
  // NOM DU RÔLE
  // ============================================================

  String _roleNameFromUser(UserModel user) {
    // Ton API Laravel renvoie directement :
    //
    // "role": "CHAUFFEUR"
    //
    // Si UserModel possède role, on l'utilise en priorité.

    final directRole = user.role.trim();

    if (directRole.isNotEmpty) {
      return directRole.toUpperCase();
    }

    // Fallback avec roleId
    final match = _roles.where(
          (role) => role.id == user.roleId,
    );

    if (match.isNotEmpty) {
      return match.first.name.toUpperCase();
    }

    return '';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // UTILISATEURS
    // ============================================================

    final totalUsers = _users.length;

    final usersActifs = _users
        .where(
          (u) => u.statut.toLowerCase() == 'actif',
    )
        .length;

    final usersInactifs = _users
        .where(
          (u) => u.statut.toLowerCase() == 'inactif',
    )
        .length;

    final responsables = _users
        .where(
          (u) {
        final role = _roleNameFromUser(u);

        return role == 'RESPONSABLE' ||
            role == 'RESPONSABLE DE FLOTTE';
      },
    )
        .length;

    final chauffeurs = _users
        .where(
          (u) => _roleNameFromUser(u) == 'CHAUFFEUR',
    )
        .length;

    // ============================================================
    // VÉHICULES
    // ============================================================

    final totalVehicules = MockData.trucks.length;

    final vehiculesEnCirculation = MockData.trucks
        .where(
          (t) => t.statut == 'en_circulation',
    )
        .length;

    final vehiculesEnPanne = MockData.trucks
        .where(
          (t) => t.statut == 'en_panne',
    )
        .length;

    final vehiculesMaintenance = MockData.trucks
        .where(
          (t) => t.statut == 'maintenance',
    )
        .length;

    // ============================================================
    // ÉQUIPEMENTS
    // ============================================================

    final totalEquipements = _equipements.length;

    final equipementsActifs = _equipements
        .where(
          (e) => e['statut'] == 'actif',
    )
        .length;

    final equipementsEnPanne = _equipements
        .where(
          (e) => e['statut'] == 'en_panne',
    )
        .length;

    final equipementsARemplacer = _equipements
        .where(
          (e) => e['statut'] == 'a_remplacer',
    )
        .length;

    // ============================================================
    // ALERTES
    // ============================================================

    final totalAlertes = _alertes.length;

    final alertesNouvelles = _alertes
        .where(
          (a) => a['statut'] == 'nouvelle',
    )
        .length;

    final alertesTraitees = _alertes
        .where(
          (a) => a['statut'] == 'traitee',
    )
        .length;

    final alertesCritiques = _alertes
        .where(
          (a) =>
      a['gravite'] == 'critique' &&
          a['statut'] == 'nouvelle',
    )
        .length;

    // ============================================================
    // PROBLÈMES TECHNIQUES
    // ============================================================

    final problemesTechniques =
        vehiculesEnPanne +
            equipementsEnPanne +
            equipementsARemplacer +
            alertesCritiques;

    // ============================================================
    // INTERFACE
    // ============================================================

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          // ========================================================
          // SIDEBAR
          // ========================================================

          const SidebarAdmin(
            selectedIndex: 0,
          ),

          // ========================================================
          // CONTENU
          // ========================================================

          Expanded(
            child: Container(
              color: backgroundColor,
              child: Column(
                children: [
                  _buildHeader(),

                  Expanded(
                    child: _loadingUsers
                        ? const Center(
                      child: CircularProgressIndicator(),
                    )
                        : SingleChildScrollView(
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          // ==================================================
                          // TITRE
                          // ==================================================

                          const Text(
                            'Bienvenue, Administrateur',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Supervision technique et administrative '
                                'de la plateforme SiraFleet.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 25),

                          // ==================================================
                          // ERREUR API
                          // ==================================================

                          if (_usersLoadFailed)
                            _buildErrorBanner(),

                          // ==================================================
                          // ÉTAT GLOBAL
                          // ==================================================

                          _buildGlobalStatus(
                            totalUsers: totalUsers,
                            totalVehicules: totalVehicules,
                            totalEquipements:
                            totalEquipements,
                            totalAlertes: totalAlertes,
                            problemesTechniques:
                            problemesTechniques,
                          ),

                          const SizedBox(height: 20),

                          // ==================================================
                          // KPI
                          // ==================================================

                          LayoutBuilder(
                            builder:
                                (context, constraints) {
                              int columns = 4;

                              if (constraints.maxWidth <
                                  1000) {
                                columns = 2;
                              }

                              if (constraints.maxWidth <
                                  600) {
                                columns = 1;
                              }

                              final double ratio =
                              columns == 4
                                  ? 2.35
                                  : columns == 2
                                  ? 2.7
                                  : 3.2;

                              return GridView.count(
                                crossAxisCount: columns,
                                shrinkWrap: true,
                                physics:
                                const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                                childAspectRatio: ratio,
                                children: [
                                  // UTILISATEURS

                                  _buildKpi(
                                    icon: Icons
                                        .people_outline,
                                    title: 'Utilisateurs',
                                    value: '$totalUsers',
                                    subtitle:
                                    '$usersActifs actifs · '
                                        '$usersInactifs inactifs',
                                    color: primaryColor,
                                  ),

                                  // VÉHICULES

                                  _buildKpi(
                                    icon: Icons
                                        .local_shipping_outlined,
                                    title: 'Véhicules',
                                    value:
                                    '$totalVehicules',
                                    subtitle:
                                    '$vehiculesEnCirculation '
                                        'en circulation · '
                                        '$vehiculesEnPanne en panne',
                                    color: accentColor,
                                  ),

                                  // ÉQUIPEMENTS

                                  _buildKpi(
                                    icon: Icons
                                        .memory_outlined,
                                    title: 'Équipements',
                                    value:
                                    '$totalEquipements',
                                    subtitle:
                                    '$equipementsActifs actifs · '
                                        '$equipementsEnPanne en panne',
                                    color: warningColor,
                                  ),

                                  // ALERTES

                                  _buildKpi(
                                    icon: Icons
                                        .notifications_active_outlined,
                                    title:
                                    'Alertes système',
                                    value:
                                    '$alertesNouvelles',
                                    subtitle:
                                    '$alertesCritiques critique(s) · '
                                        '$alertesTraitees traitée(s)',
                                    color: dangerColor,
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 25),

                          // ==================================================
                          // ACTIONS RAPIDES
                          // ==================================================

                          _buildQuickActions(context),

                          const SizedBox(height: 25),

                          // ==================================================
                          // SECTIONS
                          // ==================================================

                          LayoutBuilder(
                            builder:
                                (context, constraints) {
                              if (constraints.maxWidth <
                                  800) {
                                return Column(
                                  children: [
                                    _buildSystemStatus(
                                      vehiculesEnCirculation,
                                      vehiculesEnPanne,
                                      vehiculesMaintenance,
                                      equipementsActifs,
                                      equipementsEnPanne,
                                      equipementsARemplacer,
                                      alertesCritiques,
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    _buildUserSummary(
                                      totalUsers,
                                      usersActifs,
                                      usersInactifs,
                                      responsables,
                                      chauffeurs,
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child:
                                    _buildSystemStatus(
                                      vehiculesEnCirculation,
                                      vehiculesEnPanne,
                                      vehiculesMaintenance,
                                      equipementsActifs,
                                      equipementsEnPanne,
                                      equipementsARemplacer,
                                      alertesCritiques,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  Expanded(
                                    child:
                                    _buildUserSummary(
                                      totalUsers,
                                      usersActifs,
                                      usersInactifs,
                                      responsables,
                                      chauffeurs,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 25),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERREUR API
  // ============================================================

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: dangerColor,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Impossible de charger les utilisateurs depuis le serveur.',
              style: TextStyle(
                color: dangerColor,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: _loadUsers,
            child: const Text('Réessayer'),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 25,
      ),
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
            'Tableau de bord',
            style: TextStyle(
              color: primaryColor,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loadUsers,
            icon: const Icon(
              Icons.refresh,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ÉTAT GLOBAL
  // ============================================================

  Widget _buildGlobalStatus({
    required int totalUsers,
    required int totalVehicules,
    required int totalEquipements,
    required int totalAlertes,
    required int problemesTechniques,
  }) {
    final plateformeOK = problemesTechniques == 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: plateformeOK
              ? accentColor.withValues(alpha: 0.25)
              : dangerColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (plateformeOK
                  ? accentColor
                  : dangerColor)
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              plateformeOK
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_rounded,
              color: plateformeOK
                  ? accentColor
                  : dangerColor,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  plateformeOK
                      ? 'Plateforme opérationnelle'
                      : 'Attention : anomalies détectées',
                  style: TextStyle(
                    color: plateformeOK
                        ? accentColor
                        : dangerColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalUsers utilisateurs · '
                      '$totalVehicules véhicules · '
                      '$totalEquipements équipements · '
                      '$totalAlertes alertes',
                  style: TextStyle(
                    color: Colors.grey.shade600,
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
  // KPI
  // ============================================================

  Widget _buildKpi({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: color,
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions rapides',
            style: TextStyle(
              color: primaryColor,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          LayoutBuilder(
            builder: (context, constraints) {
              late double itemWidth;

              if (constraints.maxWidth >= 1100) {
                itemWidth =
                    (constraints.maxWidth - 48) / 4;
              } else if (constraints.maxWidth >= 700) {
                itemWidth =
                    (constraints.maxWidth - 16) / 2;
              } else {
                itemWidth = constraints.maxWidth;
              }

              return Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _buildAction(
                      context,
                      icon: Icons.people_outline,
                      title: 'Gérer les utilisateurs',
                      subtitle:
                      'Créer, modifier ou désactiver un compte',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const UtilisateursScreen(),
                          ),
                        );

                        if (mounted) {
                          _loadUsers();
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildAction(
                      context,
                      icon:
                      Icons.local_shipping_outlined,
                      title: 'Gérer les véhicules',
                      subtitle:
                      'Ajouter ou modifier les informations techniques',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const CamionsAdminScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildAction(
                      context,
                      icon: Icons.memory_outlined,
                      title: 'Gérer les équipements',
                      subtitle:
                      'Contrôler GPS, capteurs et équipements embarqués',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const EquipementsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildAction(
                      context,
                      icon: Icons
                          .admin_panel_settings_outlined,
                      title: 'Rôles et permissions',
                      subtitle:
                      'Configurer les accès des utilisateurs',
                      onTap: () {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Gestion des rôles disponible prochainement.',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildAction(
                      context,
                      icon: Icons
                          .notifications_active_outlined,
                      title: 'Alertes système',
                      subtitle:
                      'Consulter et traiter les alertes techniques',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const AlertesSystemeScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION ITEM
  // ============================================================

  Widget _buildAction(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 7,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius:
                BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                    ),
                    maxLines: 2,
                    overflow:
                    TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ÉTAT TECHNIQUE
  // ============================================================

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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'État technique',
            style: TextStyle(
              color: primaryColor,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          _buildStatus(
            'API Laravel',
            _usersLoadFailed
                ? 'Erreur de connexion'
                : 'Connectée',
            _usersLoadFailed
                ? dangerColor
                : accentColor,
          ),
          const SizedBox(height: 13),
          _buildStatus(
            'Utilisateurs',
            _usersLoadFailed
                ? 'Non chargés'
                : 'Synchronisés',
            _usersLoadFailed
                ? dangerColor
                : accentColor,
          ),
          const SizedBox(height: 13),
          _buildStatus(
            'Véhicules',
            '$vehiculesEnCirculation opérationnel(s)',
            vehiculesEnPanne == 0
                ? accentColor
                : dangerColor,
          ),
          const SizedBox(height: 13),
          _buildStatus(
            'Maintenance véhicules',
            '$vehiculesMaintenance véhicule(s)',
            vehiculesMaintenance == 0
                ? accentColor
                : warningColor,
          ),
          const SizedBox(height: 13),
          _buildStatus(
            'Équipements',
            '$equipementsActifs actif(s)',
            equipementsEnPanne == 0 &&
                equipementsARemplacer == 0
                ? accentColor
                : warningColor,
          ),
          const SizedBox(height: 13),
          _buildStatus(
            'Alertes critiques',
            alertesCritiques == 0
                ? 'Aucune'
                : '$alertesCritiques alerte(s)',
            alertesCritiques == 0
                ? accentColor
                : dangerColor,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RÉSUMÉ UTILISATEURS
  // ============================================================

  Widget _buildUserSummary(
      int total,
      int actifs,
      int inactifs,
      int responsables,
      int chauffeurs,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Comptes utilisateurs',
            style: TextStyle(
              color: primaryColor,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          _buildStatus(
            'Total',
            '$total compte(s)',
            primaryColor,
          ),
          const SizedBox(height: 13),
          _buildStatus(
            'Actifs',
            '$actifs compte(s)',
            accentColor,
          ),
          const SizedBox(height: 13),
          _buildStatus(
            'Inactifs',
            '$inactifs compte(s)',
            inactifs == 0
                ? accentColor
                : warningColor,
          ),
          const SizedBox(height: 13),
          _buildStatus(
            'Responsables',
            '$responsables',
            primaryColor,
          ),
          const SizedBox(height: 13),
          _buildStatus(
            'Chauffeurs',
            '$chauffeurs',
            primaryColor,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS ITEM
  // ============================================================

  Widget _buildStatus(
      String title,
      String status,
      Color color,
      ) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Flexible(
          child: Text(
            status,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}