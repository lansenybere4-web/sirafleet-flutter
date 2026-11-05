import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/camion_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/camion_service.dart';
import '../../widgets/camion_statut_badge.dart';
import '../../widgets/sidebar_responsable.dart';
import 'camion_detail_screen.dart';

class CamionsScreen extends StatefulWidget {
  const CamionsScreen({super.key});

  @override
  State<CamionsScreen> createState() => _CamionsScreenState();
}

class _CamionsScreenState extends State<CamionsScreen> {
  // ============================================================
  // COULEURS
  // ============================================================

  static const Color primaryColor = Color(0xFF1D3557);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  static const Color successColor = Color(0xFF059669);
  static const Color infoColor = Color(0xFF2563EB);
  static const Color dangerColor = Color(0xFFDC2626);
  static const Color warningColor = Color(0xFFD97706);

  // ============================================================
  // SERVICE
  // ============================================================

  final CamionService _camionService = CamionService();

  // ============================================================
  // CONTROLES
  // ============================================================

  final TextEditingController _searchController = TextEditingController();

  /// 'Tous' | 'disponible' | 'en_mission' | 'maintenance' | 'en_panne'
  /// (valeurs de Camion.statutAffiche)
  String _selectedStatus = 'Tous';

  // ============================================================
  // DONNÉES API
  // ============================================================

  List<Camion> _camions = [];

  bool _isLoading = true;
  String? _errorMessage;

  Timer? _refreshTimer;

  // ============================================================
  // INIT / DISPOSE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadCamions();

    // Rafraîchissement silencieux : l'état des camions (mission,
    // maintenance, panne) reste à jour sans action manuelle.
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && !_isLoading) {
        _loadCamions(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // CHARGEMENT API
  // ============================================================

  Future<void> _loadCamions({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final authProvider = context.read<AuthProvider>();

      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }

      final camions = await _camionService.getCamions(token: token);

      if (!mounted) return;

      setState(() {
        _camions = camions;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      if (silent) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  // ============================================================
  // CAMIONS FILTRÉS
  // ============================================================

  List<Camion> get _filteredCamions {
    final search = _searchController.text.toLowerCase().trim();

    return _camions.where((camion) {
      final matricule = camion.matricule.toLowerCase();
      final marque = (camion.marque ?? '').toLowerCase();
      final modele = (camion.modele ?? '').toLowerCase();

      final matchesSearch = matricule.contains(search) ||
          marque.contains(search) ||
          modele.contains(search);

      final matchesStatus =
          _selectedStatus == 'Tous' || camion.statutAffiche == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
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

        return _buildDesktopLayout();
      },
    );
  }

  // ============================================================
  // DESKTOP
  // ============================================================

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          const ResponsableSidebar(
            current: ResponsableMenuItem.camions,
          ),

          Expanded(
            child: Column(
              children: [
                _buildTopBar(),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _loadCamions(),
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
  }

  // ============================================================
  // MOBILE
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
              'Gestion des camions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Suivi opérationnel de la flotte',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: const [
          SizedBox(width: 4),
        ],
      ),
      drawer: const Drawer(
        child: ResponsableSidebar(
          current: ResponsableMenuItem.camions,
        ),
      ),
      body: _buildMobileContent(),
    );
  }

  // ============================================================
  // DESKTOP CONTENT
  // ============================================================

  Widget _buildDesktopContent() {
    if (_isLoading) {
      return _buildLoadingState();
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

        const SizedBox(height: 24),

        _buildCamionsTable(),
      ],
    );
  }

  // ============================================================
  // MOBILE CONTENT
  // ============================================================

  Widget _buildMobileContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final camions = _filteredCamions;

    return RefreshIndicator(
      onRefresh: () => _loadCamions(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),

            const SizedBox(height: 20),

            _buildSummaryCards(),

            const SizedBox(height: 20),

            _buildFilters(),

            const SizedBox(height: 20),

            if (camions.isEmpty)
              _buildEmptyState()
            else
              Column(
                children: camions.map(_buildMobileCamionCard).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Gestion des camions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),

          const Spacer(),

          IconButton(
            tooltip: 'Actualiser',
            onPressed: () => _loadCamions(),
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

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Camions',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Suivez l’état et l’activité des véhicules de votre flotte.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATISTIQUES
  // ============================================================

  Widget _buildSummaryCards() {
    final total = _camions.length;

    final disponibles =
        _camions.where((c) => c.statutAffiche == 'disponible').length;

    final enMission =
        _camions.where((c) => c.statutAffiche == 'en_mission').length;

    final enMaintenance =
        _camions.where((c) => c.statutAffiche == 'maintenance').length;

    final enPanne =
        _camions.where((c) => c.statutAffiche == 'en_panne').length;

    final cards = [
      _SummaryData(
        title: 'Total camions',
        value: '$total',
        icon: Icons.local_shipping_rounded,
        color: primaryColor,
      ),
      _SummaryData(
        title: 'Disponibles',
        value: '$disponibles',
        icon: Icons.check_circle_rounded,
        color: successColor,
      ),
      _SummaryData(
        title: 'En mission',
        value: '$enMission',
        icon: Icons.route_rounded,
        color: infoColor,
      ),
      _SummaryData(
        title: 'En maintenance',
        value: '$enMaintenance',
        icon: Icons.build_circle_rounded,
        color: warningColor,
      ),
      _SummaryData(
        title: 'En panne',
        value: '$enPanne',
        icon: Icons.warning_amber_rounded,
        color: dangerColor,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1250
            ? 5
            : constraints.maxWidth >= 800
            ? 3
            : constraints.maxWidth >= 500
            ? 2
            : 1;

        const spacing = 16.0;

        final width =
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
            child: Icon(
              data.icon,
              color: data.color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

  // ============================================================
  // FILTRES
  // ============================================================

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
          if (constraints.maxWidth < 650) {
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
              SizedBox(width: 210, child: _buildStatusDropdown()),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) {
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: 'Rechercher par matricule, marque ou modèle...',
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Color(0xFF6B7280),
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
          onPressed: () {
            _searchController.clear();
            setState(() {});
          },
          icon: const Icon(Icons.clear),
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

  // ============================================================
  // STATUS
  // ============================================================

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
        DropdownMenuItem(
          value: 'Tous',
          child: Text('Tous les statuts'),
        ),
        DropdownMenuItem(
          value: 'disponible',
          child: Text('Disponible'),
        ),
        DropdownMenuItem(
          value: 'en_mission',
          child: Text('En mission'),
        ),
        DropdownMenuItem(
          value: 'maintenance',
          child: Text('En maintenance'),
        ),
        DropdownMenuItem(
          value: 'en_panne',
          child: Text('En panne'),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _selectedStatus = value;
        });
      },
    );
  }

  // ============================================================
  // TABLEAU
  // ============================================================

  Widget _buildCamionsTable() {
    final camions = _filteredCamions;

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
                const Expanded(
                  child: Text(
                    'État opérationnel des camions',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                Text(
                  '${camions.length} camion(s)',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          if (camions.isEmpty)
            _buildEmptyState()
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF9FAFB),
                ),
                columnSpacing: 30,
                horizontalMargin: 20,
                dataRowMinHeight: 56,
                dataRowMaxHeight: 76,
                columns: const [
                  DataColumn(label: Text('CAMION')),
                  DataColumn(label: Text('MARQUE')),
                  DataColumn(label: Text('MODÈLE')),
                  DataColumn(label: Text('ANNÉE')),
                  DataColumn(label: Text('STATUT')),
                  DataColumn(label: Text('KILOMÉTRAGE')),
                  DataColumn(label: Text('MISSIONS')),
                  DataColumn(label: Text('MAINTENANCES')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: camions.map((camion) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.local_shipping_rounded,
                                color: primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              camion.matricule,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text(camion.marque ?? '-')),
                      DataCell(Text(camion.modele ?? '-')),
                      DataCell(Text(camion.annee?.toString() ?? '-')),
                      DataCell(CamionStatutBadge(camion: camion)),
                      DataCell(
                        Text('${_formatNumber(camion.kilometrage)} km'),
                      ),
                      DataCell(
                        Text(
                          '${camion.missionsCount} '
                              '(${camion.missionsTerminees} term.)',
                        ),
                      ),
                      DataCell(Text('${camion.maintenancesCount}')),
                      DataCell(
                        IconButton(
                          tooltip: 'Voir',
                          onPressed: () => _viewCamion(camion),
                          icon: const Icon(
                            Icons.visibility_outlined,
                            size: 20,
                          ),
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

  // ============================================================
  // MOBILE CARD
  // ============================================================

  Widget _buildMobileCamionCard(Camion camion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      camion.matricule,
                      style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${camion.marque ?? ''} ${camion.modele ?? ''}'.trim(),
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              CamionStatutBadge(camion: camion),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          _buildMobileDetail(
            Icons.business_outlined,
            'Marque',
            camion.marque ?? '-',
          ),
          const SizedBox(height: 10),
          _buildMobileDetail(
            Icons.directions_car_outlined,
            'Modèle',
            camion.modele ?? '-',
          ),
          const SizedBox(height: 10),
          _buildMobileDetail(
            Icons.calendar_today_outlined,
            'Année',
            camion.annee?.toString() ?? '-',
          ),
          const SizedBox(height: 10),
          _buildMobileDetail(
            Icons.speed_outlined,
            'Kilométrage',
            '${_formatNumber(camion.kilometrage)} km',
          ),
          const SizedBox(height: 10),
          _buildMobileDetail(
            Icons.route_outlined,
            'Missions',
            '${camion.missionsCount} (${camion.missionsTerminees} terminées)',
          ),
          const SizedBox(height: 10),
          _buildMobileDetail(
            Icons.build_outlined,
            'Maintenances',
            '${camion.maintenancesCount}',
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _viewCamion(camion),
              icon: const Icon(
                Icons.visibility_outlined,
                size: 18,
              ),
              label: const Text('Voir les détails'),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE DETAIL
  // ============================================================

  Widget _buildMobileDetail(
      IconData icon,
      String label,
      String value,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF6B7280),
        ),
        const SizedBox(width: 10),
        Text(
          '$label :',
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(50),
      child: Column(
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 50,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 12),
          Text(
            'Aucun camion trouvé',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Modifiez votre recherche ou vos filtres.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(50),
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 55,
              color: dangerColor,
            ),
            const SizedBox(height: 15),
            const Text(
              'Impossible de charger les camions',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Erreur inconnue.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _loadCamions(),
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
  // DÉTAIL CAMION
  // ============================================================

  void _viewCamion(Camion camion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CamionDetailScreen(
          camionId: camion.id,
          matricule: camion.matricule,
        ),
      ),
    ).then((_) {
      // Au retour, on rafraîchit la liste (le statut a pu changer).
      if (mounted) _loadCamions(silent: true);
    });
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatNumber(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }
}

// ============================================================
// SUMMARY MODEL
// ============================================================

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
