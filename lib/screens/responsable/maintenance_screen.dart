import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/camion_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/camion_service.dart';
import '../../services/maintenance_service.dart';
import '../../widgets/sidebar_responsable.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final MaintenanceService _maintenanceService = MaintenanceService();
  final CamionService _camionService = CamionService();

  List<dynamic> _maintenances = [];
  List<Camion> _camions = [];

  bool _isLoading = true;
  String? _errorMessage;

  String _search = '';
  String _statutFilter = 'Tous';
  String _prioriteFilter = 'Toutes';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // CHARGEMENT
  // ============================================================

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null || token.trim().isEmpty) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }

      final camions = await _camionService.getCamions(token: token);
      final maintenances = await _maintenanceService.getMaintenances(token: token);

      if (!mounted) return;

      setState(() {
        _camions = camions;
        _maintenances = maintenances;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // FILTRAGE
  // ============================================================

  List<dynamic> get _filteredMaintenances {
    return _maintenances.where((maintenance) {
      final statut = _getValue(maintenance, 'statut').toLowerCase();
      final priorite = _getValue(maintenance, 'priorite').toLowerCase();

      final camionMatricule =
      _getValue(maintenance, 'matricule').toLowerCase();

      final description =
      _getValue(maintenance, 'description').toLowerCase();

      final searchMatch =
          _search.isEmpty ||
              camionMatricule.contains(_search.toLowerCase()) ||
              description.contains(_search.toLowerCase());

      final statutMatch =
          _statutFilter == 'Tous' ||
              statut == _statutFilter.toLowerCase();

      final prioriteMatch =
          _prioriteFilter == 'Toutes' ||
              priorite == _prioriteFilter.toLowerCase();

      return searchMatch && statutMatch && prioriteMatch;
    }).toList();
  }

  String _getValue(dynamic object, String key) {
    if (object is Map<String, dynamic>) {
      return object[key]?.toString() ?? '';
    }

    return '';
  }

  // ============================================================
  // AJOUT MAINTENANCE
  // ============================================================

  Future<void> _showAddMaintenanceDialog() async {
    if (_camions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aucun camion disponible pour planifier une maintenance.',
          ),
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();

    Camion? selectedCamion = _camions.first;

    final descriptionController = TextEditingController();
    final coutController = TextEditingController();

    String statut = 'programmée';
    String priorite = 'normale';

    DateTime? dateMaintenance = DateTime.now();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Nouvelle maintenance',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // CAMION
                        DropdownButtonFormField<Camion>(
                          initialValue: selectedCamion,
                          decoration: const InputDecoration(
                            labelText: 'Camion',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.local_shipping_outlined),
                          ),
                          items: _camions.map((camion) {
                            return DropdownMenuItem<Camion>(
                              value: camion,
                              child: Text(
                                camion.matricule,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedCamion = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Sélectionnez un camion';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // DESCRIPTION
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Décrivez l’intervention',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.build_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'La description est obligatoire';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // STATUT
                        DropdownButtonFormField<String>(
                          initialValue: statut,
                          decoration: const InputDecoration(
                            labelText: 'Statut',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'programmée',
                              child: Text('Programmée'),
                            ),
                            DropdownMenuItem(
                              value: 'en_cours', // corrigé (était 'cours')
                              child: Text('En cours'),
                            ),
                            DropdownMenuItem(
                              value: 'terminée',
                              child: Text('Terminée'),
                            ),
                            DropdownMenuItem(
                              value: 'annulée',
                              child: Text('Annulée'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                statut = value;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        // PRIORITE
                        // PRIORITE
                        DropdownButtonFormField<String>(
                          initialValue: priorite, // doit valoir 'normale' par défaut
                          decoration: const InputDecoration(
                            labelText: 'Priorité',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.priority_high_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Toutes', child: Text('Toutes')),
                            DropdownMenuItem(value: 'normale', child: Text('Normale')),
                            DropdownMenuItem(value: 'haute', child: Text('Haute')),
                            DropdownMenuItem(value: 'urgente', child: Text('Urgente')),
                            DropdownMenuItem(value: 'critique', child: Text('Critique')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                priorite = value;
                              });
                            }
                          },
                        ),

                        // DATE
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate:
                              dateMaintenance ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );

                            if (date != null) {
                              setDialogState(() {
                                dateMaintenance = date;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date prévue',
                              border: OutlineInputBorder(),
                              prefixIcon:
                              Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(
                              _formatDate(dateMaintenance),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // COUT
                        TextFormField(
                          controller: coutController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Coût estimé',
                            suffixText: 'FCFA',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Le coût estimé est obligatoire';
                            }

                            final cout = double.tryParse(
                              value.replaceAll(',', '.'),
                            );

                            if (cout == null || cout < 0) {
                              return 'Le coût doit être un nombre valide';
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
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
                ElevatedButton.icon(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    if (selectedCamion == null) {
                      return;
                    }

                    try {
                      final auth = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );

                      final data = {
                        'reference': 'MNT-${DateTime.now().millisecondsSinceEpoch}', // ou un champ dédié dans le formulaire
                        'camion_id': selectedCamion!.id,
                        'type': 'préventive', // ajoute un DropdownButtonFormField pour le type dans le dialog
                        'description': descriptionController.text.trim(),
                        'statut': statut,
                        'priorite': priorite,
                        'date_planifiee': _formatDateForApi(dateMaintenance),
                        'cout_estime': double.parse(coutController.text.replaceAll(',', '.')),
                      };

                      await _maintenanceService.createMaintenance(
                        data,
                        token: auth.token,
                      );
                      if (!mounted) return;

                      Navigator.pop(dialogContext);

                      await _loadData();

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Maintenance créée avec succès.',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Erreur : $e',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    descriptionController.dispose();
    coutController.dispose();
  }

  // ============================================================
  // MODIFICATION
  // ============================================================

  Future<void> _showEditMaintenanceDialog(dynamic maintenance) async {
    final id = _getValue(maintenance, 'id');

    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maintenance introuvable.'),
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();

    final descriptionController = TextEditingController(
      text: _getValue(maintenance, 'description'),
    );

    final coutController = TextEditingController(
      text: _getValue(maintenance, 'cout_estime'),
    );

    String statut =
    _getValue(maintenance, 'statut').isEmpty
        ? 'programmée'
        : _getValue(maintenance, 'statut');

    String priorite =
    _getValue(maintenance, 'priorite').isEmpty
        ? 'prévue'
        : _getValue(maintenance, 'priorite');

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Modifier la maintenance',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.build_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'La description est obligatoire';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          initialValue: statut,
                          decoration: const InputDecoration(
                            labelText: 'Statut',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'programmée',
                              child: Text('Programmée'),
                            ),
                            DropdownMenuItem(
                              value: 'cours',
                              child: Text('En cours'),
                            ),
                            DropdownMenuItem(
                              value: 'terminée',
                              child: Text('Terminée'),
                            ),
                            DropdownMenuItem(
                              value: 'annulée',
                              child: Text('Annulée'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                statut = value;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          initialValue: priorite,
                          decoration: const InputDecoration(
                            labelText: 'Priorité',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'prévue',
                              child: Text('Prévue'),
                            ),
                            DropdownMenuItem(
                              value: 'urgente',
                              child: Text('Urgente'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                priorite = value;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: coutController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Coût estimé',
                            suffixText: 'FCFA',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Le coût est obligatoire';
                            }

                            final cout = double.tryParse(
                              value.replaceAll(',', '.'),
                            );

                            if (cout == null || cout < 0) {
                              return 'Valeur invalide';
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
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
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    try {
                      final data = {
                        'description':
                        descriptionController.text.trim(),
                        'statut': statut,
                        'priorite': priorite,
                        'cout_estime': double.parse(
                          coutController.text
                              .replaceAll(',', '.'),
                        ),
                      };

                      await _maintenanceService.updateMaintenance(
                        int.parse(id),
                        data,
                      );

                      if (!mounted) return;

                      Navigator.pop(dialogContext);

                      await _loadData();

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Maintenance modifiée avec succès.',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Erreur : $e',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    descriptionController.dispose();
    coutController.dispose();
  }

  Future<void> _loadMaintenances() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider =
      Provider.of<AuthProvider>(
        context,
        listen: false,
      );

      final token = authProvider.token;

      debugPrint(
        '========================================',
      );

      debugPrint(
        'Token maintenance : $token',
      );

      if (token == null ||
          token.trim().isEmpty) {
        throw Exception(
          'Session expirée. Veuillez vous reconnecter.',
        );
      }

      final data =
      await _maintenanceService.getMaintenances(
        token: token,
      );

      setState(() {
        _maintenances = data;
        _isLoading = false;
      });

      debugPrint(
        'Maintenances chargées : ${data.length}',
      );

      debugPrint(
        '========================================',
      );
    } catch (e) {
      debugPrint(
        'Erreur chargement maintenances : $e',
      );

      setState(() {
        _errorMessage =
            e.toString().replaceFirst(
              'Exception: ',
              '',
            );

        _isLoading = false;
      });
    }
  }

  // ============================================================
  // SUPPRESSION
  // ============================================================

  Future<void> _deleteMaintenance(dynamic maintenance) async {
    final id = _getValue(maintenance, 'id');

    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maintenance introuvable.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer'),
          content: const Text(
            'Voulez-vous vraiment supprimer cette maintenance ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _maintenanceService.deleteMaintenance(
        int.parse(id),
      );

      if (!mounted) return;

      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Maintenance supprimée avec succès.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur : $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Sélectionner une date';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _formatDateForApi(DateTime? date) {
    if (date == null) {
      return DateTime.now().toIso8601String().split('T').first;
    }

    return date.toIso8601String().split('T').first;
  }

  Color _statusColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'programmée':
      case 'programmee':
        return Colors.orange;

      case 'cours':
      case 'en cours':
        return Colors.blue;

      case 'terminée':
      case 'terminee':
        return Colors.green;

      case 'annulée':
      case 'annulee':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  Color _priorityColor(String priorite) {
    switch (priorite.toLowerCase()) {
      case 'urgente':
        return Colors.red;

      case 'prévue':
      case 'prevue':
        return Colors.orange;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const ResponsableSidebar(
            current: ResponsableMenuItem.maintenance,
          ),

          Expanded(
            child: Container(
              color: const Color(0xFFF5F7FA),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _buildContent(),
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
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final auth = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    final user = auth.user;

    final nomUtilisateur = user == null
        ? 'Responsable'
        : '${user.prenom} ${user.nom}'.trim();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 18,
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maintenance',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D3557),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Planifiez et suivez les opérations de maintenance',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          CircleAvatar(
            backgroundColor: const Color(0xFF1D3557),
            child: Text(
              nomUtilisateur.isNotEmpty
                  ? nomUtilisateur[0].toUpperCase()
                  : 'R',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Text(
            nomUtilisateur.isEmpty
                ? 'Responsable'
                : nomUtilisateur,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENU
  // ============================================================

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.red,
            ),
            const SizedBox(height: 15),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          _buildKpis(),

          const SizedBox(height: 25),

          _buildFilters(),

          const SizedBox(height: 20),

          _buildMaintenanceList(),
        ],
      ),
    );
  }

  // ============================================================
  // KPI
  // ============================================================

  Widget _buildKpis() {
    final total = _maintenances.length;

    final programmees = _maintenances.where((m) {
      final statut = _getValue(m, 'statut').toLowerCase();

      return statut == 'programmée' ||
          statut == 'programmee';
    }).length;

    final enCours = _maintenances.where((m) {
      final statut = _getValue(m, 'statut').toLowerCase();

      return statut == 'cours' ||
          statut == 'en cours';
    }).length;

    final urgentes = _maintenances.where((m) {
      return _getValue(m, 'priorite').toLowerCase() ==
          'urgente';
    }).length;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _kpiCard(
          'Total',
          total.toString(),
          Icons.build_outlined,
          const Color(0xFF1D3557),
        ),
        _kpiCard(
          'Programmées',
          programmees.toString(),
          Icons.calendar_month_outlined,
          Colors.orange,
        ),
        _kpiCard(
          'En cours',
          enCours.toString(),
          Icons.engineering_outlined,
          Colors.blue,
        ),
        _kpiCard(
          'Urgentes',
          urgentes.toString(),
          Icons.warning_amber_rounded,
          Colors.red,
        ),
      ],
    );
  }

  Widget _kpiCard(
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FILTRES',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D3557),
            ),
          ),

          const SizedBox(height: 15),

          Wrap(
            spacing: 15,
            runSpacing: 15,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _search = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                  initialValue: _statutFilter,
                  decoration: InputDecoration(
                    labelText: 'Statut',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Tous',
                      child: Text('Tous'),
                    ),
                    DropdownMenuItem(
                      value: 'programmée',
                      child: Text('Programmée'),
                    ),
                    DropdownMenuItem(
                      value: 'cours',
                      child: Text('En cours'),
                    ),
                    DropdownMenuItem(
                      value: 'terminée',
                      child: Text('Terminée'),
                    ),
                    DropdownMenuItem(
                      value: 'annulée',
                      child: Text('Annulée'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _statutFilter = value;
                      });
                    }
                  },
                ),
              ),

              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                  initialValue: _prioriteFilter,
                  decoration: InputDecoration(
                    labelText: 'Priorité',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Toutes',
                      child: Text('Toutes'),
                    ),
                    DropdownMenuItem(
                      value: 'prévue',
                      child: Text('Prévue'),
                    ),
                    DropdownMenuItem(
                      value: 'urgente',
                      child: Text('Urgente'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _prioriteFilter = value;
                      });
                    }
                  },
                ),
              ),

              ElevatedButton.icon(
                onPressed: _showAddMaintenanceDialog,
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle maintenance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D3557),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 17,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LISTE
  // ============================================================

  Widget _buildMaintenanceList() {
    final maintenances = _filteredMaintenances;

    if (maintenances.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(50),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.build_circle_outlined,
              size: 55,
              color: Colors.grey,
            ),
            SizedBox(height: 15),
            Text(
              'Aucune maintenance trouvée',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Aucune maintenance ne correspond aux critères sélectionnés.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Maintenance planifiée',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D3557),
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          ...maintenances.map(
                (maintenance) => _buildMaintenanceItem(
              maintenance,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceItem(dynamic maintenance) {
    final id = _getValue(maintenance, 'id');
    final description = _getValue(maintenance, 'description');

    final statut = _getValue(
      maintenance,
      'statut',
    );

    final priorite = _getValue(
      maintenance,
      'priorite',
    );

    final cout = _getValue(
      maintenance,
      'cout_estime',
    );

    final matricule = _getValue(
      maintenance,
      'matricule',
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      leading: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: const Color(0xFF1D3557).withValues(
            alpha: 0.08,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.build_outlined,
          color: Color(0xFF1D3557),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              description.isEmpty
                  ? 'Maintenance #$id'
                  : description,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _badge(
            statut.isEmpty ? 'Inconnu' : statut,
            _statusColor(statut),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(
          spacing: 18,
          runSpacing: 5,
          children: [
            if (matricule.isNotEmpty)
              Text(
                'Camion : $matricule',
              ),
            if (priorite.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.priority_high,
                    size: 16,
                    color: _priorityColor(priorite),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    priorite,
                    style: TextStyle(
                      color: _priorityColor(priorite),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            if (cout.isNotEmpty)
              Text(
                'Coût : $cout FCFA',
              ),
          ],
        ),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') {
            _showEditMaintenanceDialog(
              maintenance,
            );
          }

          if (value == 'delete') {
            _deleteMaintenance(
              maintenance,
            );
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined),
                SizedBox(width: 8),
                Text('Modifier'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                SizedBox(width: 8),
                Text('Supprimer'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(
      String text,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}