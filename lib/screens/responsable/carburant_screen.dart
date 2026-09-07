import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/carburant_model.dart';
import '../../models/camion_model.dart';
import '../../models/equipement_model.dart'; // classe EquipementModel
import '../../services/carburant_service.dart';
import '../../services/camion_service.dart';
import '../../services/equipement_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/sidebar_responsable.dart';

class CarburantScreen extends StatefulWidget {
  const CarburantScreen({super.key});

  @override
  State<CarburantScreen> createState() => _CarburantScreenState();
}

class _CarburantScreenState extends State<CarburantScreen>
    with SingleTickerProviderStateMixin {
  final CarburantService _carburantService = CarburantService();
  final CamionService _camionService = CamionService();
  final EquipementService _equipementService = EquipementService();

  late TabController _tabController;

  List<CarburantModel> _mesures = [];
  List<CarburantModel> _ravitaillements = [];
  List<Camion> _camions = [];
  List<EquipementModel> _equipements = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ============================================================
  // CHARGEMENT
  // ============================================================

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(
        context,
        listen: false,
      );

      final token = auth.token;

      final results = await Future.wait([
        _carburantService.getMesures(token: token),
        _carburantService.getRavitaillements(token: token),
        _camionService.getCamions(token: token),
        _equipementService.getEquipements(token: token),
      ]);

      if (!mounted) return;

      setState(() {
        _mesures = results[0] as List<CarburantModel>;
        _ravitaillements = results[1] as List<CarburantModel>;
        _camions = results[2] as List<Camion>;
        _equipements = results[3] as List<EquipementModel>;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '');
  }

  /// Équipements appartenant à un camion donné.
  List<EquipementModel> _equipementsDuCamion(int? camionId) {
    if (camionId == null) return [];
    return _equipements
        .where((e) => e.camionId == camionId)
        .toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          const ResponsableSidebar(
            current: ResponsableMenuItem.carburant,
          ),

          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildContent(),
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
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 28),
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
          const Icon(
            Icons.local_gas_station_outlined,
            color: Color(0xFF1D3557),
            size: 28,
          ),

          const SizedBox(width: 14),

          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestion du carburant',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D3557),
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Suivi des niveaux et ravitaillements',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          const Spacer(),

          IconButton(
            tooltip: 'Actualiser',
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(
              Icons.refresh,
              color: Color(0xFF1D3557),
            ),
          ),

          const SizedBox(width: 8),

          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF1D3557),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1D3557),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildKpis(),

          const SizedBox(height: 24),

          _buildTabs(),

          const SizedBox(height: 20),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMesuresTab(),
                _buildRavitaillementsTab(),
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

  Widget _buildKpis() {
    final totalMesures = _mesures.length;
    final totalRavitaillements = _ravitaillements.length;

    final niveaux = _mesures
        .where((e) => e.niveauPourcentage != null)
        .map((e) => e.niveauPourcentage!)
        .toList();

    double moyenne = 0;

    if (niveaux.isNotEmpty) {
      moyenne =
          niveaux.reduce((a, b) => a + b) / niveaux.length;
    }

    final alertes = _mesures.where((e) {
      final niveau = e.niveauPourcentage;
      return niveau != null && niveau <= 20;
    }).length;

    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            title: 'Mesures',
            value: totalMesures.toString(),
            icon: Icons.analytics_outlined,
            subtitle: 'Mesures enregistrées',
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: _buildKpiCard(
            title: 'Ravitaillements',
            value: totalRavitaillements.toString(),
            icon: Icons.local_gas_station,
            subtitle: 'Opérations enregistrées',
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: _buildKpiCard(
            title: 'Niveau moyen',
            value: '${moyenne.toStringAsFixed(1)} %',
            icon: Icons.water_drop_outlined,
            subtitle: 'Sur les mesures disponibles',
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: _buildKpiCard(
            title: 'Alertes',
            value: alertes.toString(),
            icon: Icons.warning_amber_rounded,
            subtitle: 'Niveau inférieur ou égal à 20 %',
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFF1D3557).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1D3557),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D3557),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.grey,
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
  // TABS
  // ============================================================

  Widget _buildTabs() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF1D3557),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF2A9D8F),
        indicatorWeight: 3,
        tabs: [
          Tab(
            icon: const Icon(Icons.analytics_outlined),
            text: 'Mesures (${_mesures.length})',
          ),
          Tab(
            icon: const Icon(Icons.local_gas_station_outlined),
            text: 'Ravitaillements (${_ravitaillements.length})',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESURES
  // ============================================================

  Widget _buildMesuresTab() {
    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Mesures de carburant',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D3557),
              ),
            ),

            const Spacer(),

            ElevatedButton.icon(
              onPressed: () => _showMesureDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle mesure'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D3557),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Expanded(
          child: _mesures.isEmpty
              ? _buildEmptyState(
            icon: Icons.analytics_outlined,
            title: 'Aucune mesure',
            message:
            'Aucune mesure de carburant n\'a encore été enregistrée.',
          )
              : _buildMesuresTable(),
        ),
      ],
    );
  }

  Widget _buildMesuresTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              const Color(0xFFF8FAFC),
            ),
            columns: const [
              DataColumn(label: Text('Camion')),
              DataColumn(label: Text('Équipement')),
              DataColumn(label: Text('Niveau')),
              DataColumn(label: Text('%')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Actions')),
            ],
            rows: _mesures.map((mesure) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      mesure.camionMatricule ??
                          'Camion #${mesure.camionId}',
                    ),
                  ),

                  DataCell(
                    Text(
                      mesure.equipementNom ??
                          (mesure.equipementId != null
                              ? 'Équipement #${mesure.equipementId}'
                              : '-'),
                    ),
                  ),

                  DataCell(
                    Text(
                      mesure.niveauLitres != null
                          ? '${mesure.niveauLitres!.toStringAsFixed(2)} L'
                          : '-',
                    ),
                  ),

                  DataCell(
                    _buildPercentageBadge(
                      mesure.niveauPourcentage,
                    ),
                  ),

                  DataCell(
                    Text(
                      _formatDateTime(mesure.mesureAt),
                    ),
                  ),

                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Modifier',
                          onPressed: () {
                            _showMesureDialog(
                              mesure: mesure,
                            );
                          },
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 19,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Supprimer',
                          onPressed: () {
                            _confirmDeleteMesure(mesure);
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 19,
                            color: Colors.red,
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
      ),
    );
  }

  Widget _buildPercentageBadge(double? percentage) {
    if (percentage == null) {
      return const Text('-');
    }

    final color = percentage <= 20
        ? Colors.red
        : percentage <= 40
        ? Colors.orange
        : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${percentage.toStringAsFixed(1)} %',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // ============================================================
  // RAVITAILLEMENTS
  // ============================================================

  Widget _buildRavitaillementsTab() {
    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Ravitaillements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D3557),
              ),
            ),

            const Spacer(),

            ElevatedButton.icon(
              onPressed: () => _showRavitaillementDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Nouveau ravitaillement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A9D8F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Expanded(
          child: _ravitaillements.isEmpty
              ? _buildEmptyState(
            icon: Icons.local_gas_station_outlined,
            title: 'Aucun ravitaillement',
            message:
            'Aucun ravitaillement n\'a encore été enregistré.',
          )
              : _buildRavitaillementsTable(),
        ),
      ],
    );
  }

  Widget _buildRavitaillementsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              const Color(0xFFF8FAFC),
            ),
            columns: const [
              DataColumn(label: Text('Camion')),
              DataColumn(label: Text('Quantité')),
              DataColumn(label: Text('Coût')),
              DataColumn(label: Text('Station')),
              DataColumn(label: Text('Utilisateur')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Actions')),
            ],
            rows: _ravitaillements.map((ravitaillement) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      ravitaillement.camionMatricule ??
                          'Camion #${ravitaillement.camionId}',
                    ),
                  ),

                  DataCell(
                    Text(
                      ravitaillement.quantiteLitres != null
                          ? '${ravitaillement.quantiteLitres!.toStringAsFixed(2)} L'
                          : '-',
                    ),
                  ),

                  DataCell(
                    Text(
                      ravitaillement.cout != null
                          ? '${ravitaillement.cout!.toStringAsFixed(2)} FCFA'
                          : '-',
                    ),
                  ),

                  DataCell(
                    Text(
                      ravitaillement.station ?? '-',
                    ),
                  ),

                  DataCell(
                    Text(
                      ravitaillement.utilisateurNom ??
                          (ravitaillement.userId != null
                              ? 'Utilisateur #${ravitaillement.userId}'
                              : '-'),
                    ),
                  ),

                  DataCell(
                    Text(
                      _formatDateTime(
                        ravitaillement.ravitaillementAt,
                      ),
                    ),
                  ),

                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Modifier',
                          onPressed: () {
                            _showRavitaillementDialog(
                              ravitaillement: ravitaillement,
                            );
                          },
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 19,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Supprimer',
                          onPressed: () {
                            _confirmDeleteRavitaillement(
                              ravitaillement,
                            );
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 19,
                            color: Colors.red,
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
      ),
    );
  }

  // ============================================================
  // DIALOG MESURE
  // ============================================================

  Future<void> _showMesureDialog({
    CarburantModel? mesure,
  }) async {
    final isEditing = mesure != null;

    final litresController = TextEditingController(
      text: mesure?.niveauLitres?.toString() ?? '',
    );

    final percentageController = TextEditingController(
      text: mesure?.niveauPourcentage?.toString() ?? '',
    );

    int? camionId = mesure?.camionId;
    int? equipementId = mesure?.equipementId;

    DateTime mesureAt = mesure?.mesureAt ?? DateTime.now();

    String? error;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing
                    ? 'Modifier la mesure'
                    : 'Nouvelle mesure',
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (error != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(
                            bottom: 15,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius:
                            BorderRadius.circular(8),
                          ),
                          child: Text(
                            error!,
                            style: const TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),

                      // ------------------------------------
                      // CAMION
                      // ------------------------------------
                      DropdownButtonFormField<int>(
                        initialValue: camionId,
                        decoration: const InputDecoration(
                          labelText: 'Camion',
                          prefixIcon:
                          Icon(Icons.local_shipping_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: _camions.map((camion) {
                          return DropdownMenuItem<int>(
                            value: camion.id,
                            child: Text(
                              camion.matricule,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            camionId = value;
                            // On réinitialise l'équipement si le
                            // camion change, car la liste dépend
                            // du camion sélectionné.
                            final dispo =
                            _equipementsDuCamion(camionId);
                            if (equipementId == null ||
                                !dispo.any(
                                      (e) =>
                                  int.parse(e.id) ==
                                      equipementId,
                                )) {
                              equipementId = null;
                            }
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      // ------------------------------------
                      // ÉQUIPEMENT (le champ manquant)
                      // ------------------------------------
                      DropdownButtonFormField<int>(
                        initialValue: equipementId,
                        decoration: InputDecoration(
                          labelText: 'Équipement',
                          prefixIcon:
                          const Icon(Icons.memory_outlined),
                          border: const OutlineInputBorder(),
                          helperText: camionId == null
                              ? 'Sélectionnez d\'abord un camion'
                              : null,
                        ),
                        items: _equipementsDuCamion(camionId)
                            .map((equipement) {
                          return DropdownMenuItem<int>(
                            // EquipementModel.id est un String,
                            // le dropdown attend un int.
                            value: int.parse(equipement.id),
                            child: Text(
                              equipement.numeroSerie.isNotEmpty
                                  ? '${equipement.type} — ${equipement.numeroSerie}'
                                  : equipement.type,
                            ),
                          );
                        }).toList(),
                        onChanged: camionId == null
                            ? null
                            : (value) {
                          setDialogState(() {
                            equipementId = value;
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: litresController,
                        keyboardType:
                        const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Niveau en litres',
                          prefixIcon:
                          Icon(Icons.water_drop_outlined),
                          suffixText: 'L',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: percentageController,
                        keyboardType:
                        const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Niveau en pourcentage',
                          prefixIcon:
                          Icon(Icons.percent),
                          suffixText: '%',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.calendar_today_outlined,
                        ),
                        title: const Text(
                          'Date de mesure',
                        ),
                        subtitle: Text(
                          _formatDateTime(mesureAt),
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            final date =
                            await showDatePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              initialDate: mesureAt,
                            );

                            if (date == null) return;

                            setDialogState(() {
                              mesureAt = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                mesureAt.hour,
                                mesureAt.minute,
                              );
                            });
                          },
                          child: const Text('Modifier'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final litres = double.tryParse(
                      litresController.text.trim(),
                    );

                    final percentage = double.tryParse(
                      percentageController.text.trim(),
                    );

                    if (camionId == null) {
                      setDialogState(() {
                        error =
                        'Veuillez sélectionner un camion.';
                      });
                      return;
                    }

                    if (litres == null || litres < 0) {
                      setDialogState(() {
                        error =
                        'Le niveau en litres est invalide.';
                      });
                      return;
                    }

                    if (percentage == null ||
                        percentage < 0 ||
                        percentage > 100) {
                      setDialogState(() {
                        error =
                        'Le pourcentage doit être compris entre 0 et 100.';
                      });
                      return;
                    }

                    if (equipementId == null) {
                      setDialogState(() {
                        error =
                        'Veuillez sélectionner un équipement. '
                            'L\'équipement doit appartenir au camion.';
                      });
                      return;
                    }

                    try {
                      final auth =
                      Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );

                      if (isEditing) {
                        await _carburantService.updateMesure(
                          id: mesure.id,
                          camionId: camionId,
                          equipementId: equipementId,
                          niveauLitres: litres,
                          niveauPourcentage: percentage,
                          mesureAt: mesureAt,
                          token: auth.token,
                        );
                      } else {
                        await _carburantService.createMesure(
                          camionId: camionId!,
                          equipementId: equipementId!,
                          niveauLitres: litres,
                          niveauPourcentage: percentage,
                          mesureAt: mesureAt,
                          token: auth.token,
                        );
                      }

                      if (!dialogContext.mounted) return;

                      Navigator.pop(dialogContext);

                      await _loadData();

                      if (!mounted) return;

                      _showSnackBar(
                        isEditing
                            ? 'Mesure modifiée avec succès.'
                            : 'Mesure enregistrée avec succès.',
                      );
                    } catch (e) {
                      setDialogState(() {
                        error = _cleanError(e);
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF1D3557),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    isEditing
                        ? 'Modifier'
                        : 'Enregistrer',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    litresController.dispose();
    percentageController.dispose();
  }

  // ============================================================
  // DIALOG RAVITAILLEMENT
  // ============================================================

  Future<void> _showRavitaillementDialog({
    CarburantModel? ravitaillement,
  }) async {
    final isEditing = ravitaillement != null;

    final quantiteController = TextEditingController(
      text: ravitaillement?.quantiteLitres?.toString() ?? '',
    );

    final coutController = TextEditingController(
      text: ravitaillement?.cout?.toString() ?? '',
    );

    final stationController = TextEditingController(
      text: ravitaillement?.station ?? '',
    );

    int? camionId = ravitaillement?.camionId;
    DateTime ravitaillementAt =
        ravitaillement?.ravitaillementAt ??
            DateTime.now();

    String? error;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing
                    ? 'Modifier le ravitaillement'
                    : 'Nouveau ravitaillement',
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (error != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(
                            bottom: 15,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius:
                            BorderRadius.circular(8),
                          ),
                          child: Text(
                            error!,
                            style: const TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),

                      DropdownButtonFormField<int>(
                        initialValue: camionId,
                        decoration: const InputDecoration(
                          labelText: 'Camion',
                          prefixIcon:
                          Icon(Icons.local_shipping_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: _camions.map((camion) {
                          return DropdownMenuItem<int>(
                            value: camion.id,
                            child: Text(
                              camion.matricule,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            camionId = value;
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: quantiteController,
                        keyboardType:
                        const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Quantité',
                          prefixIcon:
                          Icon(Icons.local_gas_station),
                          suffixText: 'L',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: coutController,
                        keyboardType:
                        const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Coût',
                          prefixIcon:
                          Icon(Icons.payments_outlined),
                          suffixText: 'FCFA',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: stationController,
                        decoration: const InputDecoration(
                          labelText: 'Station',
                          prefixIcon:
                          Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.calendar_today_outlined,
                        ),
                        title: const Text(
                          'Date du ravitaillement',
                        ),
                        subtitle: Text(
                          _formatDateTime(
                            ravitaillementAt,
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            final date =
                            await showDatePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              initialDate:
                              ravitaillementAt,
                            );

                            if (date == null) return;

                            setDialogState(() {
                              ravitaillementAt = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                ravitaillementAt.hour,
                                ravitaillementAt.minute,
                              );
                            });
                          },
                          child: const Text('Modifier'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final quantite = double.tryParse(
                      quantiteController.text.trim(),
                    );

                    final cout = double.tryParse(
                      coutController.text.trim(),
                    );

                    if (camionId == null) {
                      setDialogState(() {
                        error =
                        'Veuillez sélectionner un camion.';
                      });
                      return;
                    }

                    if (quantite == null ||
                        quantite <= 0) {
                      setDialogState(() {
                        error =
                        'La quantité doit être supérieure à 0.';
                      });
                      return;
                    }

                    if (coutController.text.trim().isNotEmpty &&
                        (cout == null || cout < 0)) {
                      setDialogState(() {
                        error = 'Le coût est invalide.';
                      });
                      return;
                    }

                    try {
                      final auth =
                      Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );

                      // Utilisateur connecté, associé
                      // automatiquement au ravitaillement.
                      // Adapte le nom du champ si besoin
                      // (ex: auth.currentUser?.id).
                      final userId = int.tryParse(
                        auth.user?.id.toString() ?? '',
                      );

                      if (isEditing) {
                        await _carburantService
                            .updateRavitaillement(
                          id: ravitaillement.id,
                          camionId: camionId,
                          userId: userId,
                          quantiteLitres: quantite,
                          cout: cout,
                          station:
                          stationController.text.trim(),
                          ravitaillementAt:
                          ravitaillementAt,
                          token: auth.token,
                        );
                      } else {
                        await _carburantService
                            .createRavitaillement(
                          camionId: camionId!,
                          userId: userId,
                          quantiteLitres: quantite,
                          cout: cout,
                          station:
                          stationController.text.trim(),
                          ravitaillementAt:
                          ravitaillementAt,
                          token: auth.token,
                        );
                      }

                      if (!dialogContext.mounted) return;

                      Navigator.pop(dialogContext);

                      await _loadData();

                      if (!mounted) return;

                      _showSnackBar(
                        isEditing
                            ? 'Ravitaillement modifié avec succès.'
                            : 'Ravitaillement enregistré avec succès.',
                      );
                    } catch (e) {
                      setDialogState(() {
                        error = _cleanError(e);
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF2A9D8F),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    isEditing
                        ? 'Modifier'
                        : 'Enregistrer',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    quantiteController.dispose();
    coutController.dispose();
    stationController.dispose();
  }

  // ============================================================
  // SUPPRESSION MESURE
  // ============================================================

  Future<void> _confirmDeleteMesure(
      CarburantModel mesure,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer la mesure'),
          content: const Text(
            'Voulez-vous vraiment supprimer cette mesure de carburant ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final auth = Provider.of<AuthProvider>(
        context,
        listen: false,
      );

      await _carburantService.deleteMesure(
        mesure.id,
        token: auth.token,
      );

      await _loadData();

      if (!mounted) return;

      _showSnackBar(
        'Mesure supprimée avec succès.',
      );
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        _cleanError(e),
        isError: true,
      );
    }
  }

  // ============================================================
  // SUPPRESSION RAVITAILLEMENT
  // ============================================================

  Future<void> _confirmDeleteRavitaillement(
      CarburantModel ravitaillement,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Supprimer le ravitaillement',
          ),
          content: const Text(
            'Voulez-vous vraiment supprimer ce ravitaillement ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final auth = Provider.of<AuthProvider>(
        context,
        listen: false,
      );

      await _carburantService.deleteRavitaillement(
        ravitaillement.id,
        token: auth.token,
      );

      await _loadData();

      if (!mounted) return;

      _showSnackBar(
        'Ravitaillement supprimé avec succès.',
      );
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        _cleanError(e),
        isError: true,
      );
    }
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 55,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D3557),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 500,
        ),
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 15),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Une erreur est survenue.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D3557),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================

  String _formatDateTime(DateTime? date) {
    if (date == null) return '-';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year à $hour:$minute';
  }

  void _showSnackBar(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        isError ? Colors.red : const Color(0xFF2A9D8F),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
