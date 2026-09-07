import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/mission.dart';
import '../../providers/auth_provider.dart';
import '../../services/mission_service.dart';
import '../../widgets/sidebar_responsable.dart';
import 'nouvelle_mission_screen.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  static const Color primaryColor = Color(0xFF1D3557);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  final MissionService _missionService = MissionService();
  final TextEditingController _searchController = TextEditingController();

  List<Mission> _missions = [];
  String _selectedStatus = 'Toutes';
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasRetriedWithToken = false;

  String? get _token => context.read<AuthProvider>().token;

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMissions() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final token = _token;

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Session expirée. Veuillez vous reconnecter.';
      });

      return;
    }

    try {
      final missions = await _missionService.getMissions(token: token);

      if (!mounted) return;

      setState(() {
        _missions = missions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanException(e);
      });
    }
  }

  List<Mission> get _filteredMissions {
    final search = _searchController.text.trim().toLowerCase();

    return _missions.where((mission) {
      final matchesSearch = search.isEmpty ||
          mission.reference.toLowerCase().contains(search) ||
          mission.origine.toLowerCase().contains(search) ||
          mission.destination.toLowerCase().contains(search) ||
          mission.camion.toLowerCase().contains(search) ||
          mission.chauffeur.toLowerCase().contains(search) ||
          mission.objet.toLowerCase().contains(search);

      final matchesStatus =
          _selectedStatus == 'Toutes' || mission.statut == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentToken = context.watch<AuthProvider>().token;

    if (!_hasRetriedWithToken &&
        currentToken != null &&
        currentToken.isNotEmpty &&
        _errorMessage != null) {
      _hasRetriedWithToken = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadMissions();
      });
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: MediaQuery.of(context).size.width < 900
          ? const Drawer(
        child: ResponsableSidebar(
          current: ResponsableMenuItem.missions,
        ),
      )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          if (isDesktop) {
            return Row(
              children: [
                const ResponsableSidebar(
                  current: ResponsableMenuItem.missions,
                ),
                Expanded(
                  child: Column(
                    children: [
                      _buildTopBar(true),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadMissions,
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
            );
          }

          return Column(
            children: [
              _buildTopBar(false),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadMissions,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: _buildContent(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(bool isDesktop) {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            Builder(
              builder: (context) {
                return IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.menu_rounded, color: primaryColor),
                );
              },
            ),
          if (!isDesktop) const SizedBox(width: 8),
          const Icon(Icons.assignment_rounded, color: primaryColor, size: 23),
          const SizedBox(width: 10),
          const Text(
            'Gestion des missions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _loadMissions,
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF374151)),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            tooltip: 'Notifications',
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(width: 10),
          const CircleAvatar(
            radius: 20,
            backgroundColor: primaryColor,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const SizedBox(
        height: 500,
        child: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildSummaryCards(),
        const SizedBox(height: 24),
        _buildFilters(),
        const SizedBox(height: 20),
        _buildMissionTable(),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 55,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(height: 15),
          const Text(
            'Impossible de charger les missions',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadMissions,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Missions',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Planifiez, affectez et suivez les missions de votre flotte.',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _createMission,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nouvelle mission'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Missions',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Planifiez, affectez et suivez les missions de votre flotte.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _createMission,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nouvelle mission'),
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
      },
    );
  }

  Widget _buildSummaryCards() {
    final total = _missions.length;
    final enCours = _missions.where((m) => m.statut == 'En cours').length;
    final planifiees =
        _missions.where((m) => m.statut == 'Planifiée').length;
    final terminees = _missions.where((m) => m.statut == 'Terminée').length;

    final cards = <_SummaryData>[
      _SummaryData(
        title: 'Total missions',
        value: '$total',
        icon: Icons.assignment_rounded,
        color: primaryColor,
      ),
      _SummaryData(
        title: 'En cours',
        value: '$enCours',
        icon: Icons.route_rounded,
        color: const Color(0xFF2563EB),
      ),
      _SummaryData(
        title: 'Planifiées',
        value: '$planifiees',
        icon: Icons.event_available_rounded,
        color: const Color(0xFFD97706),
      ),
      _SummaryData(
        title: 'Terminées',
        value: '$terminees',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF059669),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns;
        if (constraints.maxWidth >= 1000) {
          columns = 4;
        } else if (constraints.maxWidth >= 650) {
          columns = 2;
        } else {
          columns = 1;
        }

        const double spacing = 16.0;
        final double width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((card) {
            return SizedBox(
              width: width,
              child: _buildSummaryCard(card),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSummaryCard(_SummaryData data) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 700) {
            return Column(
              children: [
                _buildSearchField(),
                const SizedBox(height: 12),
                _buildStatusDropdown(),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: _buildSearchField()),
              const SizedBox(width: 15),
              SizedBox(width: 220, child: _buildStatusDropdown()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Rechercher une mission, camion, chauffeur...',
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6B7280)),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
          onPressed: () {
            _searchController.clear();
            setState(() {});
          },
          icon: const Icon(Icons.clear_rounded),
        )
            : null,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedStatus,
      decoration: InputDecoration(
        labelText: 'Statut',
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'Toutes', child: Text('Toutes les missions')),
        DropdownMenuItem(value: 'Planifiée', child: Text('Planifiées')),
        DropdownMenuItem(value: 'En cours', child: Text('En cours')),
        DropdownMenuItem(value: 'Terminée', child: Text('Terminées')),
        DropdownMenuItem(value: 'Annulée', child: Text('Annulées')),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedStatus = value;
        });
      },
    );
  }

  Widget _buildMissionTable() {
    final missions = _filteredMissions;

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
                  'Liste des missions',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const Spacer(),
                Text(
                  '${missions.length} mission(s)',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          if (missions.isEmpty)
            _buildEmptyState()
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF9FAFB),
                ),
                columnSpacing: 32,
                horizontalMargin: 20,
                columns: const [
                  DataColumn(label: Text('RÉFÉRENCE')),
                  DataColumn(label: Text('ITINÉRAIRE')),
                  DataColumn(label: Text('CAMION')),
                  DataColumn(label: Text('CHAUFFEUR')),
                  DataColumn(label: Text('DATE')),
                  DataColumn(label: Text('STATUT')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: missions.map((mission) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          mission.reference,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 230,
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  mission.origine,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 7),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  mission.destination,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          mission.camion.isEmpty
                              ? 'Non affecté'
                              : mission.camion,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(
                        Text(
                          mission.chauffeur.isEmpty
                              ? 'Non affecté'
                              : mission.chauffeur,
                        ),
                      ),
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mission.date),
                            Text(
                              mission.heure,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(_buildStatusBadge(mission.statut)),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Voir',
                              onPressed: () => _viewMission(mission),
                              icon: const Icon(
                                Icons.visibility_outlined,
                                size: 20,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Modifier',
                              onPressed: () => _editMission(mission),
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 20,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Supprimer',
                              onPressed: () => _deleteMission(mission),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;

    switch (status) {
      case 'Planifiée':
        color = const Color(0xFFD97706);
        break;
      case 'En cours':
        color = const Color(0xFF2563EB);
        break;
      case 'Terminée':
        color = const Color(0xFF059669);
        break;
      case 'Annulée':
        color = const Color(0xFFDC2626);
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(50),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 50,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 12),
          Text(
            'Aucune mission trouvée',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          SizedBox(height: 5),
          Text(
            'Modifiez votre recherche ou vos filtres.',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Future<void> _createMission() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const NouvelleMissionScreen()),
    );

    if (result is! Mission) return;

    if (!mounted) return;

    setState(() {
      _missions = [result, ..._missions];
    });
  }

  void _viewMission(Mission mission) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.assignment_rounded, color: primaryColor),
              const SizedBox(width: 10),
              Expanded(child: Text(mission.reference)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detail('Objet', mission.objet),
                _detail('Type', mission.type),
                _detail('Priorité', mission.priorite),
                _detail('Origine', mission.origine),
                _detail('Destination', mission.destination),
                _detail(
                  'Camion',
                  mission.camion.isEmpty ? 'Non affecté' : mission.camion,
                ),
                _detail(
                  'Chauffeur',
                  mission.chauffeur.isEmpty
                      ? 'Non affecté'
                      : mission.chauffeur,
                ),
                _detail('Date', mission.date),
                _detail('Heure', mission.heure),
                _detail('Distance', mission.distance),
                _detail('Statut', mission.statut),
                if (mission.description.isNotEmpty)
                  _detail('Description', mission.description),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fermer'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _editMission(mission);
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Modifier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label :',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // ============================================================
  // MODIFIER UNE MISSION
  // ------------------------------------------------------------
  // On passe la mission existante à NouvelleMissionScreen (mode
  // édition) : c'est cet écran qui pré-remplit le formulaire ET
  // décide d'appeler updateMission au lieu de createMission. On
  // ne refait donc PAS d'appel API ici, seulement une mise à jour
  // locale de la liste avec le résultat renvoyé.
  // ============================================================

  Future<void> _editMission(Mission mission) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NouvelleMissionScreen(missionToEdit: mission),
      ),
    );

    if (result is! Mission) return;

    if (!mounted) return;

    setState(() {
      final index = _missions.indexWhere((item) => item.id == result.id);

      if (index != -1) {
        final copy = List<Mission>.from(_missions);
        copy[index] = result;
        _missions = copy;
      }
    });
  }

  Future<void> _deleteMission(Mission mission) async {
    if (mission.id == null) {
      _showError('Cette mission ne possède pas d\'identifiant.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer la mission'),
          content: Text(
            'Voulez-vous vraiment supprimer la mission ${mission.reference} ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final token = _token;

    try {
      _showLoadingSnackBar('Suppression de la mission...');

      await _missionService.deleteMission(mission.id!, token: token);

      if (!mounted) return;

      setState(() {
        _missions.removeWhere((item) => item.id == mission.id);
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSuccess('Mission ${mission.reference} supprimée.');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showError(_cleanException(e));
    }
  }

  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF059669),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
  }

  String _cleanException(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

class _SummaryData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
