import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/equipement_model.dart';
import '../../models/camion_model.dart';
import '../../services/equipement_service.dart';
import '../../services/camion_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/sidebar_admin.dart';

class EquipementsScreen extends StatefulWidget {
  const EquipementsScreen({
    super.key,
  });

  @override
  State<EquipementsScreen> createState() => _EquipementsScreenState();
}

class _EquipementsScreenState extends State<EquipementsScreen> {
  final EquipementService _equipementService = EquipementService();
  final CamionService _camionService = CamionService();

  List<EquipementModel> _equipements = [];
  List<Camion> _camions = [];

  bool _isLoading = true;
  String? _error;

  String _recherche = '';
  String _statutFiltre = 'Tous';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chargerDonnees();
    });
  }

  // ============================================================
  // CHARGEMENT
  // ============================================================

  Future<void> _chargerDonnees() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();

      final token = auth.token;

      final results = await Future.wait([
        _equipementService.getEquipements(
          token: token,
        ),
        _camionService.getCamions(
          token: token,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _equipements = results[0] as List<EquipementModel>;
        _camions = results[1] as List<Camion>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  // ============================================================
  // FILTRAGE
  // ============================================================

  List<EquipementModel> get _equipementsFiltres {
    return _equipements.where((equipement) {
      final recherche = _recherche.toLowerCase().trim();

      final correspondRecherche =
          recherche.isEmpty ||
              equipement.type.toLowerCase().contains(recherche) ||
              equipement.numeroSerie.toLowerCase().contains(recherche) ||
              equipement.imei.toLowerCase().contains(recherche) ||
              equipement.camionMatricule
                  .toLowerCase()
                  .contains(recherche);

      final correspondStatut =
          _statutFiltre == 'Tous' ||
              equipement.statut == _statutFiltre;

      return correspondRecherche && correspondStatut;
    }).toList();
  }

  int _nombreParStatut(String statut) {
    return _equipements.where(
          (e) => e.statut == statut,
    ).length;
  }

  // ============================================================
  // SUPPRESSION
  // ============================================================

  Future<void> _supprimer(
      EquipementModel equipement,
      ) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Supprimer l’équipement',
          ),
          content: Text(
            'Voulez-vous vraiment supprimer '
                'l’équipement ${equipement.numeroSerie} ?',
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
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmation != true) {
      return;
    }

    try {
      final auth = context.read<AuthProvider>();

      await _equipementService.deleteEquipement(
        equipement.id,
        token: auth.token,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Équipement supprimé avec succès.',
          ),
        ),
      );

      await _chargerDonnees();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    }
  }

  // ============================================================
  // AJOUT
  // ============================================================

  Future<void> _ajouterEquipement() async {
    await _ouvrirFormulaire();
  }

  // ============================================================
  // MODIFICATION
  // ============================================================

  Future<void> _modifierEquipement(
      EquipementModel equipement,
      ) async {
    await _ouvrirFormulaire(
      equipement: equipement,
    );
  }

  // ============================================================
  // FORMULAIRE
  // ============================================================

  Future<void> _ouvrirFormulaire({
    EquipementModel? equipement,
  }) async {
    final bool isEdition = equipement != null;

    final formKey = GlobalKey<FormState>();

    final typeController = TextEditingController(
      text: equipement?.type ?? '',
    );

    final numeroSerieController = TextEditingController(
      text: equipement?.numeroSerie ?? '',
    );

    final imeiController = TextEditingController(
      text: equipement?.imei ?? '',
    );

    final fabricantController = TextEditingController(
      text: equipement?.fabricant ?? '',
    );

    final modeleController = TextEditingController(
      text: equipement?.modele ?? '',
    );

    final firmwareController = TextEditingController(
      text: equipement?.versionFirmware ?? '',
    );

    final dateInstallationController = TextEditingController(
      text: equipement?.dateInstallation ?? '',
    );

    final dateControleController = TextEditingController(
      text: equipement?.dateDernierControle ?? '',
    );

    final observationController = TextEditingController(
      text: equipement?.observation ?? '',
    );

    String statut = equipement?.statut ?? 'actif';

    int? camionId = equipement?.camionId;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (
              context,
              setDialogState,
              ) {
            Future<void> enregistrer() async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              setDialogState(() {
                isSaving = true;
              });

              try {
                final auth = this.context.read<AuthProvider>();

                if (isEdition) {
                  await _equipementService.updateEquipement(
                    id: equipement.id,
                    type: typeController.text.trim(),
                    numeroSerie: numeroSerieController.text.trim(),
                    imei: imeiController.text.trim(),
                    fabricant: fabricantController.text.trim(),
                    modele: modeleController.text.trim(),
                    versionFirmware: firmwareController.text.trim(),
                    camionId: camionId,
                    statut: statut,
                    dateInstallation:
                    dateInstallationController.text.trim(),
                    dateDernierControle:
                    dateControleController.text.trim(),
                    observation: observationController.text.trim(),
                    token: auth.token,
                  );
                } else {
                  await _equipementService.createEquipement(
                    type: typeController.text.trim(),
                    numeroSerie: numeroSerieController.text.trim(),
                    imei: imeiController.text.trim(),
                    fabricant: fabricantController.text.trim(),
                    modele: modeleController.text.trim(),
                    versionFirmware: firmwareController.text.trim(),
                    camionId: camionId,
                    statut: statut,
                    dateInstallation:
                    dateInstallationController.text.trim(),
                    dateDernierControle:
                    dateControleController.text.trim(),
                    observation: observationController.text.trim(),
                    token: auth.token,
                  );
                }

                if (!mounted) return;

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEdition
                          ? 'Équipement modifié avec succès.'
                          : 'Équipement ajouté avec succès.',
                    ),
                  ),
                );

                await _chargerDonnees();
              } catch (e) {
                setDialogState(() {
                  isSaving = false;
                });

                if (!mounted) return;

                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      e.toString().replaceFirst(
                        'Exception: ',
                        '',
                      ),
                    ),
                  ),
                );
              }
            }

            return AlertDialog(
              title: Text(
                isEdition
                    ? 'Modifier l’équipement'
                    : 'Ajouter un équipement',
              ),
              content: SizedBox(
                width: 650,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _champ(
                                controller: typeController,
                                label: 'Type',
                                icon: Icons.devices,
                                requiredField: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _champ(
                                controller: numeroSerieController,
                                label: 'Numéro de série',
                                icon: Icons.numbers,
                                requiredField: true,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _champ(
                                controller: imeiController,
                                label: 'IMEI',
                                icon: Icons.phone_android,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _champ(
                                controller: fabricantController,
                                label: 'Fabricant',
                                icon: Icons.business,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _champ(
                                controller: modeleController,
                                label: 'Modèle',
                                icon: Icons.category,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _champ(
                                controller: firmwareController,
                                label: 'Version firmware',
                                icon: Icons.system_update,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        DropdownButtonFormField<int?>(
                          initialValue: camionId,
                          decoration: const InputDecoration(
                            labelText: 'Camion affecté',
                            prefixIcon: Icon(
                              Icons.local_shipping,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Non affecté'),
                            ),
                            ..._camions.map(
                                  (camion) {
                                return DropdownMenuItem<int?>(
                                  value: camion.id,
                                  child: Text(
                                    '${camion.matricule}'
                                        '${camion.marque != null ? ' - ${camion.marque}' : ''}',
                                  ),
                                );
                              },
                            ),
                          ],
                          onChanged: isSaving
                              ? null
                              : (value) {
                            setDialogState(() {
                              camionId = value;
                            });
                          },
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child:
                              DropdownButtonFormField<String>(
                                initialValue: statut,
                                decoration: const InputDecoration(
                                  labelText: 'Statut',
                                  prefixIcon: Icon(
                                    Icons.verified,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'actif',
                                    child: Text('Actif'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'en_panne',
                                    child: Text('En panne'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'a_remplacer',
                                    child: Text('À remplacer'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'maintenance',
                                    child: Text('Maintenance'),
                                  ),
                                ],
                                onChanged: isSaving
                                    ? null
                                    : (value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      statut = value;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _champ(
                                controller:
                                dateInstallationController,
                                label: 'Date installation',
                                icon: Icons.calendar_today,
                                hint: 'YYYY-MM-DD',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _champ(
                          controller: dateControleController,
                          label: 'Date dernier contrôle',
                          icon: Icons.fact_check,
                          hint: 'YYYY-MM-DD',
                        ),

                        const SizedBox(height: 12),

                        _champ(
                          controller: observationController,
                          label: 'Observation',
                          icon: Icons.notes,
                          maxLines: 3,
                        ),
                      ],
                    ),
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
                  child: const Text('Fermer'),
                ),
                ElevatedButton.icon(
                  onPressed: isSaving ? null : enregistrer,
                  icon: isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.save),
                  label: Text(
                    isSaving
                        ? 'Enregistrement...'
                        : 'Enregistrer',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    typeController.dispose();
    numeroSerieController.dispose();
    imeiController.dispose();
    fabricantController.dispose();
    modeleController.dispose();
    firmwareController.dispose();
    dateInstallationController.dispose();
    dateControleController.dispose();
    observationController.dispose();
  }

  // ============================================================
  // CHAMP
  // ============================================================

  Widget _champ({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool requiredField = false,
    String? hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: requiredField
          ? (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label est obligatoire';
        }

        return null;
      }
          : null,
    );
  }

  // ============================================================
  // COULEUR STATUT
  // ============================================================

  Color _statutColor(String statut) {
    switch (statut) {
      case 'actif':
        return Colors.green;

      case 'en_panne':
        return Colors.red;

      case 'a_remplacer':
        return Colors.orange;

      case 'maintenance':
        return Colors.blue;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // LABEL STATUT
  // ============================================================

  String _statutLabel(String statut) {
    switch (statut) {
      case 'actif':
        return 'Actif';

      case 'en_panne':
        return 'En panne';

      case 'a_remplacer':
        return 'À remplacer';

      case 'maintenance':
        return 'Maintenance';

      default:
        return statut;
    }
  }

  // ============================================================
  // CARD EQUIPEMENT
  // ============================================================

  Widget _equipementCard(
      EquipementModel equipement,
      ) {
    final color = _statutColor(
      equipement.statut,
    );

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.devices,
                color: color,
                size: 28,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          equipement.type,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _statutBadge(
                        equipement.statut,
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'N° série : ${equipement.numeroSerie}',
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Camion : ${equipement.camionMatricule}',
                  ),

                  if (equipement.imei.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'IMEI : ${equipement.imei}',
                    ),
                  ],

                  if (equipement.fabricant.isNotEmpty ||
                      equipement.modele.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (equipement.fabricant.isNotEmpty)
                          equipement.fabricant,
                        if (equipement.modele.isNotEmpty)
                          equipement.modele,
                      ].join(' - '),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'modifier') {
                  _modifierEquipement(equipement);
                }

                if (value == 'supprimer') {
                  _supprimer(equipement);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'modifier',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'supprimer',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      SizedBox(width: 8),
                      Text('Supprimer'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BADGE
  // ============================================================

  Widget _statutBadge(String statut) {
    final color = _statutColor(statut);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statutLabel(statut),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // ============================================================
  // CARTE STATISTIQUE
  // ============================================================

  Widget _statCard({
    required String titre,
    required String valeur,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                ),
              ),

              const SizedBox(width: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    valeur,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONTENU PRINCIPAL
  // ============================================================

  Widget _buildContent() {
    final liste = _equipementsFiltres;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 50,
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _chargerDonnees,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _chargerDonnees,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ======================================================
          // TITRE
          // ======================================================

          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestion des équipements',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 6),

                    Text(
                      'Gérez les équipements installés sur les camions.',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              ElevatedButton.icon(
                onPressed: _ajouterEquipement,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ======================================================
          // STATISTIQUES
          // ======================================================

          Row(
            children: [
              _statCard(
                titre: 'Total',
                valeur: '${_equipements.length}',
                icon: Icons.devices,
                color: Colors.blue,
              ),

              const SizedBox(width: 12),

              _statCard(
                titre: 'Actifs',
                valeur: '${_nombreParStatut('actif')}',
                icon: Icons.check_circle,
                color: Colors.green,
              ),

              const SizedBox(width: 12),

              _statCard(
                titre: 'En panne',
                valeur: '${_nombreParStatut('en_panne')}',
                icon: Icons.error,
                color: Colors.red,
              ),

              const SizedBox(width: 12),

              _statCard(
                titre: 'À remplacer',
                valeur: '${_nombreParStatut('a_remplacer')}',
                icon: Icons.warning,
                color: Colors.orange,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ======================================================
          // FILTRES
          // ======================================================

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Rechercher',
                        hintText:
                        'N° série, type, IMEI, camion...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _recherche = value;
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 16),

                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      initialValue: _statutFiltre,
                      decoration: const InputDecoration(
                        labelText: 'Statut',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Tous',
                          child: Text('Tous'),
                        ),
                        DropdownMenuItem(
                          value: 'actif',
                          child: Text('Actif'),
                        ),
                        DropdownMenuItem(
                          value: 'en_panne',
                          child: Text('En panne'),
                        ),
                        DropdownMenuItem(
                          value: 'a_remplacer',
                          child: Text('À remplacer'),
                        ),
                        DropdownMenuItem(
                          value: 'maintenance',
                          child: Text('Maintenance'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          _statutFiltre = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ======================================================
          // LISTE
          // ======================================================

          if (liste.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.devices_other,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Aucun équipement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Aucun équipement ne correspond aux filtres.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...liste.map(_equipementCard),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ======================================================
          // SIDEBAR ADMIN
          // ======================================================

          const SidebarAdmin(
            selectedIndex: 4,
          ),

          // ======================================================
          // CONTENU
          // ======================================================

          Expanded(
            child: Scaffold(
              backgroundColor: const Color(0xFFF5F7FA),

              appBar: AppBar(
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1D3557),
                title: const Text(
                  'Équipements',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Actualiser',
                    onPressed:
                    _isLoading ? null : _chargerDonnees,
                    icon: const Icon(Icons.refresh),
                  ),

                  const SizedBox(width: 10),
                ],
              ),

              floatingActionButton:
              FloatingActionButton.extended(
                onPressed: _ajouterEquipement,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),

              body: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }
}