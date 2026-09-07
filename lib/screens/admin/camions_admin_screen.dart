import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/camion_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/camion_service.dart';
import '../../widgets/sidebar_admin.dart';

const Map<String, String> _statutLabels = {
  'disponible': 'Disponible',
  'en_circulation': 'En circulation',
  'en_panne': 'En panne',
  'maintenance': 'Maintenance',
};

class CamionsAdminScreen extends StatefulWidget {
  const CamionsAdminScreen({super.key});

  @override
  State<CamionsAdminScreen> createState() => _CamionsAdminScreenState();
}

class _CamionsAdminScreenState extends State<CamionsAdminScreen> {
  // ============================================================
  // COULEURS
  // ============================================================

  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  // ============================================================
  // SERVICE
  // ============================================================

  final CamionService _camionService = CamionService();

  // ============================================================
  // DONNEES
  // ============================================================

  List<Camion> _camions = [];

  bool _isLoading = true;
  String? _errorMessage;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCamions();
    });
  }

  // ============================================================
  // CHARGEMENT
  // ============================================================

  Future<void> _loadCamions() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      if (token == null || token.trim().isEmpty) {
        throw Exception(
          'Session expirée. Veuillez vous reconnecter.',
        );
      }

      final camions = await _camionService.getCamions(
        token: token,
      );

      if (!mounted) return;

      setState(() {
        _camions = camions;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  // ============================================================
  // NETTOYAGE ERREUR
  // ============================================================

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .trim();
  }

  // ============================================================
  // DETAILS
  // ============================================================

  void _showTruckDetails(Camion camion) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  camion.matricule,
                  style: const TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _detailRow(
                    Icons.badge_outlined,
                    'Identifiant',
                    camion.id.toString(),
                  ),
                  _detailRow(
                    Icons.confirmation_number_outlined,
                    'Matricule',
                    camion.matricule,
                  ),
                  _detailRow(
                    Icons.business_outlined,
                    'Marque',
                    camion.marque ?? '-',
                  ),
                  _detailRow(
                    Icons.directions_car_outlined,
                    'Modèle',
                    camion.modele ?? '-',
                  ),
                  _detailRow(
                    Icons.calendar_today_outlined,
                    'Année',
                    camion.annee?.toString() ?? '-',
                  ),
                  _detailRow(
                    Icons.speed_outlined,
                    'Kilométrage',
                    '${_formatNumber(camion.kilometrage)} km',
                  ),
                  _detailRow(
                    Icons.info_outline,
                    'Statut',
                    _statutLabels[camion.statut] ?? camion.statut,
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
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORMULAIRE
  // ============================================================

  void _showTruckForm({
    Camion? camion,
  }) {
    final bool isEdit = camion != null;

    final matriculeCtrl = TextEditingController(
      text: camion?.matricule ?? '',
    );

    final marqueCtrl = TextEditingController(
      text: camion?.marque ?? '',
    );

    final modeleCtrl = TextEditingController(
      text: camion?.modele ?? '',
    );

    final anneeCtrl = TextEditingController(
      text: camion?.annee?.toString() ?? '',
    );

    final kilometrageCtrl = TextEditingController(
      text: camion != null
          ? camion.kilometrage.toString()
          : '0',
    );

    String statut = camion?.statut ?? 'disponible';
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
              dialogBuildContext,
              setDialogState,
              ) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEdit
                          ? 'Modifier le véhicule'
                          : 'Ajouter un véhicule',
                      style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informations générales',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // MATRICULE
                      TextField(
                        controller: matriculeCtrl,
                        textCapitalization:
                        TextCapitalization.characters,
                        enabled: !isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Matricule *',
                          hintText: 'Ex : TR-120',
                          prefixIcon: Icon(
                            Icons.confirmation_number_outlined,
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // MARQUE + MODELE
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: marqueCtrl,
                              enabled: !isSaving,
                              decoration: const InputDecoration(
                                labelText: 'Marque',
                                hintText: 'Ex : Volvo',
                                prefixIcon: Icon(
                                  Icons.business_outlined,
                                ),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: modeleCtrl,
                              enabled: !isSaving,
                              decoration: const InputDecoration(
                                labelText: 'Modèle',
                                hintText: 'Ex : FH16',
                                prefixIcon: Icon(
                                  Icons.local_shipping_outlined,
                                ),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ANNEE + KILOMETRAGE
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: anneeCtrl,
                              enabled: !isSaving,
                              keyboardType:
                              TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Année',
                                hintText: 'Ex : 2024',
                                prefixIcon: Icon(
                                  Icons.calendar_today_outlined,
                                ),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: kilometrageCtrl,
                              enabled: !isSaving,
                              keyboardType:
                              const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Kilométrage',
                                hintText: 'Ex : 125000',
                                suffixText: 'km',
                                prefixIcon: Icon(
                                  Icons.speed_outlined,
                                ),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // STATUT
                      DropdownButtonFormField<String>(
                        initialValue: statut,
                        decoration: const InputDecoration(
                          labelText: 'Statut',
                          prefixIcon: Icon(
                            Icons.settings_outlined,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        items: _statutLabels.entries
                            .map(
                              (entry) =>
                              DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                        )
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (value) {
                          if (value == null) return;

                          setDialogState(() {
                            statut = value;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      // INFORMATION
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius:
                          BorderRadius.circular(10),
                        ),
                        child: const Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: accentColor,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'L’affectation du chauffeur et la '
                                    'gestion des missions sont effectuées '
                                    'par le Responsable de flotte.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Annuler'),
                ),

                ElevatedButton.icon(
                  onPressed: isSaving
                      ? null
                      : () async {
                    // -------------------------------
                    // VALIDATION MATRICULE
                    // -------------------------------

                    final matricule =
                    matriculeCtrl.text.trim();

                    if (matricule.isEmpty) {
                      ScaffoldMessenger.of(
                        dialogBuildContext,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Le matricule du véhicule '
                                'est obligatoire.',
                          ),
                          backgroundColor: dangerColor,
                        ),
                      );
                      return;
                    }

                    // -------------------------------
                    // VALIDATION ANNEE
                    // -------------------------------

                    final anneeText =
                    anneeCtrl.text.trim();

                    int? annee;

                    if (anneeText.isNotEmpty) {
                      annee = int.tryParse(anneeText);

                      if (annee == null) {
                        ScaffoldMessenger.of(
                          dialogBuildContext,
                        ).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'L’année doit être un nombre valide.',
                            ),
                            backgroundColor:
                            dangerColor,
                          ),
                        );
                        return;
                      }
                    }

                    // -------------------------------
                    // VALIDATION KILOMETRAGE
                    // -------------------------------

                    final kilometrageText =
                    kilometrageCtrl.text
                        .trim()
                        .replaceAll(',', '.');

                    final kilometrage =
                    double.tryParse(
                      kilometrageText,
                    );

                    if (kilometrage == null ||
                        kilometrage < 0) {
                      ScaffoldMessenger.of(
                        dialogBuildContext,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Le kilométrage doit être '
                                'un nombre positif.',
                          ),
                          backgroundColor: dangerColor,
                        ),
                      );
                      return;
                    }

                    // -------------------------------
                    // TOKEN
                    // -------------------------------

                    final authProvider =
                    context.read<AuthProvider>();

                    final token =
                        authProvider.token;

                    if (token == null ||
                        token.trim().isEmpty) {
                      ScaffoldMessenger.of(
                        dialogBuildContext,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Session expirée. '
                                'Veuillez vous reconnecter.',
                          ),
                          backgroundColor:
                          dangerColor,
                        ),
                      );
                      return;
                    }

                    // -------------------------------
                    // LOADING
                    // -------------------------------

                    setDialogState(() {
                      isSaving = true;
                    });

                    try {
                      // -----------------------------
                      // MODIFICATION
                      // -----------------------------

                      if (isEdit) {
                        await _camionService
                            .updateCamion(
                          id: camion.id,
                          matricule: matricule,
                          marque:
                          marqueCtrl.text.trim(),
                          modele:
                          modeleCtrl.text.trim(),
                          annee: annee,
                          kilometrage:
                          kilometrage,
                          statut: statut,
                          token: token,
                        );
                      }

                      // -----------------------------
                      // CREATION
                      // -----------------------------

                      else {
                        await _camionService
                            .createCamion(
                          matricule: matricule,
                          marque:
                          marqueCtrl.text.trim(),
                          modele:
                          modeleCtrl.text.trim(),
                          annee: annee,
                          kilometrage:
                          kilometrage,
                          statut: statut,
                          token: token,
                        );
                      }

                      if (!mounted) return;

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEdit
                                ? 'Véhicule $matricule '
                                'modifié avec succès.'
                                : 'Véhicule $matricule '
                                'ajouté avec succès.',
                          ),
                          backgroundColor:
                          accentColor,
                        ),
                      );

                      await _loadCamions();
                    } catch (e) {
                      if (!mounted) return;

                      setDialogState(() {
                        isSaving = false;
                      });

                      ScaffoldMessenger.of(
                        dialogBuildContext,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            _cleanError(e),
                          ),
                          backgroundColor:
                          dangerColor,
                        ),
                      );
                    }
                  },

                  icon: isSaving
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(
                    Icons.save_outlined,
                  ),

                  label: Text(
                    isEdit
                        ? 'Enregistrer'
                        : 'Ajouter',
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      matriculeCtrl.dispose();
      marqueCtrl.dispose();
      modeleCtrl.dispose();
      anneeCtrl.dispose();
      kilometrageCtrl.dispose();
    });
  }

  // ============================================================
  // SUPPRESSION
  // ============================================================

  Future<void> _confirmDelete(
      Camion camion,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: dangerColor,
              ),
              SizedBox(width: 10),
              Text('Supprimer le véhicule ?'),
            ],
          ),
          content: Text(
            'Voulez-vous vraiment supprimer le véhicule '
                '${camion.matricule} ?\n\n'
                'Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerColor,
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
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      if (token == null || token.trim().isEmpty) {
        throw Exception(
          'Session expirée. Veuillez vous reconnecter.',
        );
      }

      await _camionService.deleteCamion(
        camion.id,
        token: token,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Véhicule ${camion.matricule} supprimé avec succès.',
          ),
          backgroundColor: accentColor,
        ),
      );

      await _loadCamions();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _cleanError(e),
          ),
          backgroundColor: dangerColor,
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          const SidebarAdmin(
            selectedIndex: 2,
          ),

          Expanded(
            child: Column(
              children: [
                _buildHeader(),

                Expanded(
                  child: _buildBody(),
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
            'Véhicules',
            style: TextStyle(
              color: primaryColor,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          IconButton(
            tooltip: 'Actualiser',
            onPressed: _isLoading
                ? null
                : _loadCamions,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    return RefreshIndicator(
      onRefresh: _loadCamions,
      child: SingleChildScrollView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(25),
        child: _buildContent(),
      ),
    );
  }

  // ============================================================
  // ERREUR
  // ============================================================

  Widget _buildError() {
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
              'Impossible de charger les véhicules',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _errorMessage ??
                  'Erreur inconnue.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _loadCamions,
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
  // CONTENU
  // ============================================================

  Widget _buildContent() {
    final total = _camions.length;

    final disponibles = _camions
        .where(
          (c) => c.statut == 'disponible',
    )
        .length;

    final enCirculation = _camions
        .where(
          (c) => c.statut == 'en_circulation',
    )
        .length;

    final incidents = _camions
        .where(
          (c) =>
      c.statut == 'en_panne' ||
          c.statut == 'maintenance',
    )
        .length;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'Supervision technique des véhicules',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Consultez l’état technique des véhicules '
              'et leur connexion au système SiraFleet.',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 25),

        // ======================================================
        // STATISTIQUES
        // ======================================================

        LayoutBuilder(
          builder: (
              context,
              constraints,
              ) {
            final width =
                constraints.maxWidth;

            int columns = 4;

            if (width < 1000) {
              columns = 2;
            }

            if (width < 600) {
              columns = 1;
            }

            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics:
              const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 2.5,
              children: [
                _buildStatCard(
                  Icons.local_shipping_outlined,
                  'Total véhicules',
                  '$total',
                  primaryColor,
                ),
                _buildStatCard(
                  Icons.check_circle_outline,
                  'Disponibles',
                  '$disponibles',
                  accentColor,
                ),
                _buildStatCard(
                  Icons.route_outlined,
                  'En circulation',
                  '$enCirculation',
                  Colors.blue,
                ),
                _buildStatCard(
                  Icons.warning_amber_outlined,
                  'Incidents',
                  '$incidents',
                  dangerColor,
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 25),

        // ======================================================
        // TABLEAU
        // ======================================================

        Container(
          width: double.infinity,
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
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Parc des véhicules',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  ElevatedButton.icon(
                    onPressed: () {
                      _showTruckForm();
                    },
                    icon: const Icon(
                      Icons.add,
                      size: 18,
                    ),
                    label: const Text(
                      'Ajouter un véhicule',
                    ),
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      primaryColor,
                      foregroundColor:
                      Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (_camions.isEmpty)
                _buildEmpty()
              else
                SingleChildScrollView(
                  scrollDirection:
                  Axis.horizontal,
                  child: DataTable(
                    headingRowColor:
                    WidgetStateProperty.all(
                      backgroundColor,
                    ),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Matricule',
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Marque / Modèle',
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Année',
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Statut',
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Kilométrage',
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Actions',
                        ),
                      ),
                    ],
                    rows: _camions.map(
                          (camion) {
                        final vehicleParts = [
                          camion.marque,
                          camion.modele,
                        ].where(
                              (value) =>
                          value != null &&
                              value.trim().isNotEmpty,
                        );

                        final vehicleName =
                        vehicleParts.join(' ');

                        return DataRow(
                          cells: [
                            // MATRICULE
                            DataCell(
                              Text(
                                camion.matricule,
                                style:
                                const TextStyle(
                                  fontWeight:
                                  FontWeight.bold,
                                  color:
                                  primaryColor,
                                ),
                              ),
                            ),

                            // MARQUE MODELE
                            DataCell(
                              Text(
                                vehicleName.isEmpty
                                    ? '-'
                                    : vehicleName,
                              ),
                            ),

                            // ANNEE
                            DataCell(
                              Text(
                                camion.annee
                                    ?.toString() ??
                                    '-',
                              ),
                            ),

                            // STATUT
                            DataCell(
                              _buildStatusBadge(
                                camion.statut,
                              ),
                            ),

                            // KILOMETRAGE
                            DataCell(
                              Text(
                                '${_formatNumber(camion.kilometrage)} km',
                              ),
                            ),

                            // ACTIONS
                            DataCell(
                              Row(
                                mainAxisSize:
                                MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip:
                                    'Voir les détails',
                                    icon: const Icon(
                                      Icons
                                          .visibility_outlined,
                                      size: 19,
                                    ),
                                    color:
                                    primaryColor,
                                    onPressed: () {
                                      _showTruckDetails(
                                        camion,
                                      );
                                    },
                                  ),

                                  IconButton(
                                    tooltip:
                                    'Modifier',
                                    icon: const Icon(
                                      Icons
                                          .edit_outlined,
                                      size: 19,
                                    ),
                                    color:
                                    accentColor,
                                    onPressed: () {
                                      _showTruckForm(
                                        camion: camion,
                                      );
                                    },
                                  ),

                                  IconButton(
                                    tooltip:
                                    'Supprimer',
                                    icon: const Icon(
                                      Icons
                                          .delete_outline,
                                      size: 19,
                                    ),
                                    color:
                                    dangerColor,
                                    onPressed: () {
                                      _confirmDelete(
                                        camion,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            size: 50,
            color: Color(0xFF9CA3AF),
          ),

          const SizedBox(height: 12),

          const Text(
            'Aucun véhicule trouvé',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Ajoutez un véhicule pour commencer.',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BADGE STATUT
  // ============================================================

  Widget _buildStatusBadge(
      String statut,
      ) {
    Color color;

    switch (statut) {
      case 'disponible':
        color = accentColor;
        break;

      case 'en_circulation':
        color = Colors.blue;
        break;

      case 'en_panne':
        color = dangerColor;
        break;

      case 'maintenance':
        color = Colors.orange;
        break;

      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
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
        _statutLabels[statut] ?? statut,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _buildStatCard(
      IconData icon,
      String title,
      String value,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(15),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.10,
              ),
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color:
                    Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 21,
                    fontWeight:
                    FontWeight.bold,
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
  // FORMAT NOMBRE
  // ============================================================

  String _formatNumber(
      double value,
      ) {
    return value
        .toStringAsFixed(2)
        .replaceAll('.', ',');
  }
}