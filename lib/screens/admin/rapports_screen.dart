import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/sidebar_admin.dart';

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
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color warningColor = Color(0xFFF4A261);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  // ============================================================
  // PERIODE
  // ============================================================

  String periode = 'Hebdomadaire';

  final List<String> periodes = [
    'Journalier',
    'Hebdomadaire',
    'Mensuel',
    'Annuel',
  ];

  // ============================================================
  // SERVICES
  // ============================================================

  final UserService _userService = UserService();

  // ============================================================
  // ETAT
  // ============================================================

  int _totalUsers = 0;
  bool _loadingUsers = true;

  int _totalEquipements = 0;
  bool _loadingEquipements = false;

  // ============================================================
  // ALERTES TEMPORAIRES
  // ============================================================
  //
  // MockData.alertes n'existe pas dans ton projet actuel.
  // On utilise donc une liste locale temporaire.
  //
  // Plus tard, cette liste pourra être remplacée par :
  // AlerteService().getAlertes(token)
  // ============================================================

  final List<Map<String, String>> _alertes = [
    {
      'type': 'GPS',
      'statut': 'Traité',
    },
    {
      'type': 'Connexion',
      'statut': 'Traité',
    },
    {
      'type': 'Équipement',
      'statut': 'En attente',
    },
    {
      'type': 'Sécurité',
      'statut': 'Traité',
    },
    {
      'type': 'GPS',
      'statut': 'En attente',
    },
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  // ============================================================
  // CHARGEMENT DES DONNEES
  // ============================================================

  Future<void> _loadReportData() async {
    await _loadUsersCount();

    if (!mounted) return;

    _loadEquipementsCount();
  }

  // ============================================================
  // UTILISATEURS
  // ============================================================

  Future<void> _loadUsersCount() async {
    final token = context.read<AuthProvider>().token;

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      setState(() {
        _loadingUsers = false;
        _totalUsers = 0;
      });

      return;
    }

    if (mounted) {
      setState(() {
        _loadingUsers = true;
      });
    }

    try {
      final users = await _userService.getUsers(token);

      if (!mounted) return;

      setState(() {
        _totalUsers = users.length;
        _loadingUsers = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingUsers = false;
        _totalUsers = 0;
      });
    }
  }

  // ============================================================
  // EQUIPEMENTS
  // ============================================================

  void _loadEquipementsCount() {
    if (!mounted) return;

    setState(() {
      _loadingEquipements = true;
    });

    // Valeur temporaire.
    // Elle sera remplacée par EquipmentService lorsque
    // le module équipements sera connecté à Laravel.

    const int nombreEquipements = 0;

    if (!mounted) return;

    setState(() {
      _totalEquipements = nombreEquipements;
      _loadingEquipements = false;
    });
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    await _loadReportData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Rapport actualisé avec succès.',
        ),
        backgroundColor: accentColor,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final int totalUsers = _totalUsers;

    final int totalVehicules = MockData.trucks.length;

    final int totalEquipements = _totalEquipements;

    final int totalAlertes = _alertes.length;

    final int alertesTraitees = _alertes.where((alerte) {
      final String statut =
      (alerte['statut'] ?? '').toLowerCase().trim();

      return statut == 'traite' ||
          statut == 'traitée' ||
          statut == 'traitee';
    }).length;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          const SidebarAdmin(
            selectedIndex: 8,
          ),

          Expanded(
            child: Column(
              children: [
                _buildHeader(),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        _buildTitle(),

                        const SizedBox(height: 20),

                        _buildPeriodSelector(),

                        const SizedBox(height: 25),

                        _buildKpiSection(
                          totalUsers,
                          totalVehicules,
                          totalEquipements,
                          totalAlertes,
                        ),

                        const SizedBox(height: 25),

                        _buildTechnicalModules(
                          totalUsers: totalUsers,
                          totalVehicules: totalVehicules,
                          totalEquipements: totalEquipements,
                          totalAlertes: totalAlertes,
                        ),

                        const SizedBox(height: 25),

                        _buildAdminActivities(),

                        const SizedBox(height: 25),

                        _buildSystemStatus(
                          totalEquipements: totalEquipements,
                        ),

                        const SizedBox(height: 25),

                        _buildAlertProgress(
                          alertesTraitees,
                          totalAlertes,
                        ),

                        const SizedBox(height: 30),

                        _buildExportButtons(),

                        const SizedBox(height: 20),
                      ],
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
            'Rapports',
            style: TextStyle(
              color: primaryColor,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          IconButton(
            tooltip: 'Actualiser',
            onPressed: _refresh,
            icon: const Icon(
              Icons.refresh_outlined,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TITRE
  // ============================================================

  Widget _buildTitle() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'Rapport d’activité administrative',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 7),

              Text(
                'Synthèse des activités techniques et '
                    'administratives effectuées sur la '
                    'plateforme SiraFleet.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 15),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: accentColor.withValues(
              alpha: 0.10,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                color: accentColor,
                size: 18,
              ),

              SizedBox(width: 7),

              Text(
                'Administration',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
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
  // PERIODE
  // ============================================================

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Wrap(
        spacing: 5,
        children: periodes.map((p) {
          final bool selected = periode == p;

          return ChoiceChip(
            label: Text(p),
            selected: selected,
            onSelected: (selectedValue) {
              if (!selectedValue) return;

              setState(() {
                periode = p;
              });
            },
            selectedColor: primaryColor,
            backgroundColor: Colors.transparent,
            side: BorderSide.none,
            labelStyle: TextStyle(
              color: selected
                  ? Colors.white
                  : Colors.black87,
              fontSize: 12,
              fontWeight: selected
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // KPI
  // ============================================================

  Widget _buildKpiSection(
      int users,
      int vehicules,
      int equipements,
      int alertes,
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 4;

        if (constraints.maxWidth < 1100) {
          columns = 3;
        }

        if (constraints.maxWidth < 750) {
          columns = 2;
        }

        if (constraints.maxWidth < 500) {
          columns = 1;
        }

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics:
          const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 2.35,
          children: [
            _buildKpi(
              Icons.people_outline,
              'Utilisateurs',
              _loadingUsers ? '…' : '$users',
              primaryColor,
            ),

            _buildKpi(
              Icons.security_outlined,
              'Rôles & permissions',
              '7',
              Colors.indigo,
            ),

            _buildKpi(
              Icons.local_shipping_outlined,
              'Camions gérés',
              '$vehicules',
              accentColor,
            ),

            _buildKpi(
              Icons.memory_outlined,
              'Équipements',
              _loadingEquipements
                  ? '…'
                  : '$equipements',
              warningColor,
            ),

            _buildKpi(
              Icons.location_on_outlined,
              'GPS actifs',
              '16',
              Colors.blue,
            ),

            _buildKpi(
              Icons.warning_amber_outlined,
              'Alertes système',
              '$alertes',
              dangerColor,
            ),

            _buildKpi(
              Icons.login_outlined,
              'Connexions',
              '124',
              Colors.teal,
            ),

            _buildKpi(
              Icons.admin_panel_settings_outlined,
              'Actions admin',
              '86',
              primaryColor,
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // KPI CARD
  // ============================================================

  Widget _buildKpi(
      IconData icon,
      String title,
      String value,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.04,
            ),
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
              color: color.withValues(
                alpha: 0.10,
              ),
              borderRadius:
              BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: color,
              size: 26,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
  // MODULES TECHNIQUES
  // ============================================================

  Widget _buildTechnicalModules({
    required int totalUsers,
    required int totalVehicules,
    required int totalEquipements,
    required int totalAlertes,
  }) {
    final List<Map<String, dynamic>> modules = [
      {
        'name': 'Utilisateurs',
        'description': 'Gestion des comptes',
        'icon': Icons.people_outline,
        'count': totalUsers,
        'color': primaryColor,
      },
      {
        'name': 'Rôles & permissions',
        'description': 'Contrôle des accès',
        'icon': Icons.security_outlined,
        'count': 7,
        'color': Colors.indigo,
      },
      {
        'name': 'Camions',
        'description': 'Données techniques',
        'icon': Icons.local_shipping_outlined,
        'count': totalVehicules,
        'color': accentColor,
      },
      {
        'name': 'Équipements',
        'description': 'Configuration IoT',
        'icon': Icons.memory_outlined,
        'count': totalEquipements,
        'color': warningColor,
      },
      {
        'name': 'GPS',
        'description': 'État des dispositifs',
        'icon': Icons.location_on_outlined,
        'count': 16,
        'color': Colors.blue,
      },
      {
        'name': 'Sécurité',
        'description': 'Accès et connexions',
        'icon': Icons.lock_outline,
        'count': 14,
        'color': Colors.deepPurple,
      },
      {
        'name': 'Alertes système',
        'description': 'Incidents techniques',
        'icon': Icons.warning_amber_outlined,
        'count': totalAlertes,
        'color': dangerColor,
      },
      {
        'name': 'Configuration',
        'description': 'Paramètres plateforme',
        'icon': Icons.settings_outlined,
        'count': 6,
        'color': Colors.blueGrey,
      },
    ];

    return _sectionContainer(
      title: 'Activités par module technique',
      subtitle:
      'Actions administratives enregistrées '
          'pour chaque module.',
      child: GridView.builder(
        shrinkWrap: true,
        physics:
        const NeverScrollableScrollPhysics(),
        itemCount: modules.length,
        gridDelegate:
        const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.8,
        ),
        itemBuilder: (context, index) {
          final module = modules[index];

          final Color color =
          module['color'] as Color;

          final IconData icon =
          module['icon'] as IconData;

          final String name =
          module['name'] as String;

          final String description =
          module['description'] as String;

          final int count =
          module['count'] as int;

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        overflow:
                        TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        description,
                        overflow:
                        TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                          Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  '$count',
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // JOURNAL ADMIN
  // ============================================================

  Widget _buildAdminActivities() {
    final List<Map<String, String>> activities = [
      {
        'date': '20/08/2026 13:20',
        'user': 'Administrateur',
        'module': 'Utilisateurs',
        'action':
        'Création d’un compte utilisateur',
        'status': 'Succès',
      },
      {
        'date': '20/08/2026 12:55',
        'user': 'Administrateur',
        'module': 'Camions',
        'action':
        'Modification des données techniques',
        'status': 'Succès',
      },
      {
        'date': '20/08/2026 12:30',
        'user': 'Administrateur',
        'module': 'Équipements',
        'action':
        'Configuration d’un équipement GPS',
        'status': 'Succès',
      },
      {
        'date': '20/08/2026 11:45',
        'user': 'Administrateur',
        'module': 'Sécurité',
        'action':
        'Modification d’une permission',
        'status': 'Succès',
      },
      {
        'date': '20/08/2026 10:50',
        'user': 'Administrateur',
        'module': 'Alertes système',
        'action':
        'Traitement d’une alerte technique',
        'status': 'Traité',
      },
      {
        'date': '20/08/2026 09:35',
        'user': 'Administrateur',
        'module': 'Configuration',
        'action':
        'Mise à jour des paramètres système',
        'status': 'Succès',
      },
      {
        'date': '20/08/2026 09:10',
        'user': 'Administrateur',
        'module': 'GPS',
        'action':
        'Vérification de la connexion GPS',
        'status': 'Succès',
      },
    ];

    return _sectionContainer(
      title:
      'Journal des activités administratives',
      subtitle:
      'Historique des principales actions '
          'réalisées par l’administrateur.',
      child: Column(
        children: [
          _buildTableHeader(),

          const Divider(height: 1),

          ...activities.map(
                (activity) =>
                _buildActivityRow(activity),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABLE HEADER
  // ============================================================

  Widget _buildTableHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'DATE / HEURE',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              'ADMINISTRATEUR',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              'MODULE',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            flex: 3,
            child: Text(
              'ACTION',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: Text(
              'STATUT',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIVITY ROW
  // ============================================================

  Widget _buildActivityRow(
      Map<String, String> activity,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 14,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF0F0F0),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              activity['date'] ?? '',
              style: const TextStyle(
                fontSize: 11,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              activity['user'] ?? '',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              activity['module'] ?? '',
              style: const TextStyle(
                fontSize: 11,
              ),
            ),
          ),

          Expanded(
            flex: 3,
            child: Text(
              activity['action'] ?? '',
              style: const TextStyle(
                fontSize: 11,
              ),
            ),
          ),

          Expanded(
            child: _buildStatusBadge(
              activity['status'] ?? '',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(String status) {
    final bool success =
        status == 'Succès' ||
            status == 'Traité';

    final Color color =
    success ? accentColor : dangerColor;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: color.withValues(
            alpha: 0.10,
          ),
          borderRadius:
          BorderRadius.circular(20),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ETAT DU SYSTEME
  // ============================================================

  Widget _buildSystemStatus({
    required int totalEquipements,
  }) {
    final List<Map<String, dynamic>> systems = [
      {
        'title': 'API Laravel',
        'value': 'Opérationnelle',
        'icon': Icons.api_outlined,
        'color': accentColor,
      },
      {
        'title': 'Base de données',
        'value': 'Connectée',
        'icon': Icons.storage_outlined,
        'color': accentColor,
      },
      {
        'title': 'Service GPS',
        'value': 'Opérationnel',
        'icon': Icons.gps_fixed,
        'color': accentColor,
      },
      {
        'title': 'Équipements IoT',
        'value': '$totalEquipements actifs',
        'icon': Icons.memory_outlined,
        'color': accentColor,
      },
    ];

    return _sectionContainer(
      title: 'État technique de la plateforme',
      subtitle:
      'Vue synthétique des principaux services '
          'utilisés par SiraFleet.',
      child: GridView.builder(
        shrinkWrap: true,
        physics:
        const NeverScrollableScrollPhysics(),
        itemCount: systems.length,
        gridDelegate:
        const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 3.4,
        ),
        itemBuilder: (context, index) {
          final system = systems[index];

          final Color color =
          system['color'] as Color;

          final IconData icon =
          system['icon'] as IconData;

          final String title =
          system['title'] as String;

          final String value =
          system['value'] as String;

          return Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFE5E7EB),
              ),
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 22,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        overflow:
                        TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        value,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // TAUX ALERTES
  // ============================================================

  Widget _buildAlertProgress(
      int alertesTraitees,
      int alertesTotal,
      ) {
    final double taux = alertesTotal == 0
        ? 0.0
        : (alertesTraitees / alertesTotal)
        .clamp(0.0, 1.0)
        .toDouble();

    return _sectionContainer(
      title: 'Traitement des alertes système',
      subtitle:
      'Taux de traitement des alertes '
          'techniques et administratives.',
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${(taux * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: primaryColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(width: 10),

              Text(
                'des alertes traitées',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          ClipRRect(
            borderRadius:
            BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: taux,
              minHeight: 11,
              backgroundColor: backgroundColor,
              color: accentColor,
            ),
          ),

          const SizedBox(height: 9),

          Text(
            '$alertesTraitees alertes traitées '
                'sur $alertesTotal',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EXPORT
  // ============================================================

  Widget _buildExportButtons() {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            _exporter('PDF');
          },
          icon: const Icon(
            Icons.picture_as_pdf_outlined,
            size: 18,
          ),
          label: const Text(
            'Exporter PDF',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: dangerColor,
            side: const BorderSide(
              color: dangerColor,
            ),
            padding:
            const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
          ),
        ),

        const SizedBox(width: 10),

        ElevatedButton.icon(
          onPressed: () {
            _exporter('Excel');
          },
          icon: const Icon(
            Icons.table_chart_outlined,
            size: 18,
          ),
          label: const Text(
            'Exporter Excel',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding:
            const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION CONTAINER
  // ============================================================

  Widget _sectionContainer({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 18),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // EXPORT ACTION
  // ============================================================

  void _exporter(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Préparation du rapport $format — '
              'période $periode.',
        ),
        backgroundColor: accentColor,
      ),
    );
  }
}