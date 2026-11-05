import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/camion_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/camion_service.dart';
import '../../services/maintenance_service.dart';
import '../../widgets/sidebar_responsable.dart';

const Color _navy = Color(0xFF1D3557);
const Color _teal = Color(0xFF2A9D8F);
const Color _background = Color(0xFFF5F7FA);
const Color _border = Color(0xFFE6EAF0);
const Color _muted = Color(0xFF64748B);

const List<String> _statuses = [
  'programmée',
  'en_cours',
  'terminée',
  'annulée',
];

const List<String> _priorities = [
  'normale',
  'haute',
  'urgente',
  'critique',
];

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final MaintenanceService _maintenanceService = MaintenanceService();
  final CamionService _camionService = CamionService();

  final TextEditingController _searchController = TextEditingController();

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // DONNÉES
  // ============================================================

  Future<String> _getToken() async {
    final auth = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    final token = auth.token;

    if (token == null || token.trim().isEmpty) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    }

    return token;
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _getToken();

      final results = await Future.wait([
        _camionService.getCamions(token: token),
        _maintenanceService.getMaintenances(token: token),
      ]);

      if (!mounted) return;

      setState(() {
        _camions = results[0] as List<Camion>;
        _maintenances = results[1] as List<dynamic>;
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
    return error.toString().replaceFirst('Exception: ', '');
  }

  String _value(dynamic object, String key) {
    if (object is Map) {
      return object[key]?.toString() ?? '';
    }
    return '';
  }

  /// Le matricule est dans l'objet imbriqué `camion` (API: with('camion')).
  String _truckMatricule(dynamic maintenance) {
    if (maintenance is Map) {
      final camion = maintenance['camion'];
      if (camion is Map) {
        return camion['matricule']?.toString() ?? '';
      }
      return maintenance['matricule']?.toString() ?? '';
    }
    return '';
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('û', 'u');
  }

  String _canonicalStatus(String value) {
    switch (_normalize(value)) {
      case 'programmee':
      case 'programme':
        return 'programmée';
      case 'en cours':
      case 'cours':
      case 'en_cours':
        return 'en_cours';
      case 'terminee':
      case 'termine':
        return 'terminée';
      case 'annulee':
      case 'annule':
        return 'annulée';
      default:
        return _statuses.contains(value) ? value : 'programmée';
    }
  }

  String _canonicalPriority(String value) {
    final normalized = _normalize(value);

    if (_priorities.contains(normalized)) return normalized;

    switch (normalized) {
      case 'prévue':
      case 'prevue':
      case 'normale':
        return 'normale';
      case 'haute':
        return 'haute';
      case 'urgente':
        return 'urgente';
      case 'critique':
        return 'critique';
      default:
        return 'normale';
    }
  }

  String _statusLabel(String status) {
    switch (_canonicalStatus(status)) {
      case 'programmée':
        return 'Programmée';
      case 'en_cours':
        return 'En cours';
      case 'terminée':
        return 'Terminée';
      case 'annulée':
        return 'Annulée';
      default:
        return 'Programmée';
    }
  }

  String _priorityLabel(String priority) {
    switch (_canonicalPriority(priority)) {
      case 'normale':
        return 'Normale';
      case 'haute':
        return 'Haute';
      case 'urgente':
        return 'Urgente';
      case 'critique':
        return 'Critique';
      default:
        return 'Normale';
    }
  }

  Color _statusColor(String status) {
    switch (_canonicalStatus(status)) {
      case 'programmée':
        return const Color(0xFFB7791F);
      case 'en_cours':
        return const Color(0xFF2563EB);
      case 'terminée':
        return const Color(0xFF16845B);
      case 'annulée':
        return const Color(0xFFDC2626);
      default:
        return _muted;
    }
  }

  Color _priorityColor(String priority) {
    switch (_canonicalPriority(priority)) {
      case 'normale':
        return _teal;
      case 'haute':
        return const Color(0xFFD97706);
      case 'urgente':
        return const Color(0xFFEA580C);
      case 'critique':
        return const Color(0xFFDC2626);
      default:
        return _muted;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Choisir une date';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatDateForApi(DateTime? date) {
    final value = date ?? DateTime.now();

    return '${value.year}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  String _formatAmount(String value) {
    final number = double.tryParse(value.replaceAll(',', '.'));

    if (number == null) return value;

    return number.toStringAsFixed(
      number == number.roundToDouble() ? 0 : 2,
    );
  }

  DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;

    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  List<dynamic> get _filteredMaintenances {
    return _maintenances.where((maintenance) {
      final status = _canonicalStatus(
        _value(maintenance, 'statut'),
      );

      final priority = _canonicalPriority(
        _value(maintenance, 'priorite'),
      );

      final truck = _truckMatricule(maintenance);
      final description = _value(maintenance, 'description');
      final reference = _value(maintenance, 'reference');

      final query = _normalize(_search);

      final matchesSearch = query.isEmpty ||
          _normalize(truck).contains(query) ||
          _normalize(description).contains(query) ||
          _normalize(reference).contains(query);

      final matchesStatus = _statutFilter == 'Tous' ||
          status == _canonicalStatus(_statutFilter);

      final matchesPriority = _prioriteFilter == 'Toutes' ||
          priority == _canonicalPriority(_prioriteFilter);

      return matchesSearch && matchesStatus && matchesPriority;
    }).toList();
  }

  // ============================================================
  // CRÉATION
  // ============================================================

  Future<void> _showAddMaintenanceDialog() async {
    if (_camions.isEmpty) {
      _showMessage(
        'Aucun camion disponible pour planifier une maintenance.',
        isError: true,
      );
      return;
    }

    final formKey = GlobalKey<FormState>();

    final descriptionController = TextEditingController();
    final costController = TextEditingController();

    Camion? selectedTruck = _camions.first;
    String type = 'préventive';
    String status = 'programmée';
    String priority = 'normale';
    DateTime? plannedDate = DateTime.now();

    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            _iconBox(
                              Icons.build_circle_outlined,
                              _teal,
                              size: 52,
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nouvelle maintenance',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: _navy,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Planifiez une intervention sur un camion.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Fermer',
                              onPressed: saving
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        _sectionTitle('Informations générales'),
                        const SizedBox(height: 14),
                        _fieldLabel('Camion concerné *'),
                        DropdownButtonFormField<Camion>(
                          value: selectedTruck,
                          isExpanded: true,
                          decoration: _inputDecoration(
                            hint: 'Sélectionner un camion',
                            icon: Icons.local_shipping_outlined,
                          ),
                          items: _camions.map((truck) {
                            return DropdownMenuItem<Camion>(
                              value: truck,
                              child: Text(
                                truck.matricule,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: saving
                              ? null
                              : (value) {
                            setDialogState(() {
                              selectedTruck = value;
                            });
                          },
                          validator: (value) =>
                          value == null ? 'Sélectionnez un camion.' : null,
                        ),
                        const SizedBox(height: 16),
                        _fieldLabel('Type de maintenance *'),
                        DropdownButtonFormField<String>(
                          value: type,
                          decoration: _inputDecoration(
                            hint: 'Type',
                            icon: Icons.handyman_outlined,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'préventive',
                              child: Text('Préventive'),
                            ),
                            DropdownMenuItem(
                              value: 'corrective',
                              child: Text('Corrective'),
                            ),
                          ],
                          onChanged: saving
                              ? null
                              : (value) {
                            if (value != null) {
                              setDialogState(() => type = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        _fieldLabel('Description de l’intervention *'),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          enabled: !saving,
                          decoration: _inputDecoration(
                            hint: 'Ex. : vidange, contrôle des freins...',
                            icon: Icons.description_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'La description est obligatoire.';
                            }
                            if (value.trim().length < 5) {
                              return 'Saisissez au moins 5 caractères.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        _sectionTitle('Planification et budget'),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final stacked = constraints.maxWidth < 450;

                            final dateField = Expanded(
                              flex: stacked ? 0 : 1,
                              child: InkWell(
                                onTap: saving
                                    ? null
                                    : () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate:
                                    plannedDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme:
                                          const ColorScheme.light(
                                            primary: _navy,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );

                                  if (date != null) {
                                    setDialogState(() {
                                      plannedDate = date;
                                    });
                                  }
                                },
                                child: InputDecorator(
                                  decoration: _inputDecoration(
                                    hint: 'Date prévue',
                                    icon: Icons.calendar_month_outlined,
                                  ),
                                  child: Text(
                                    _formatDate(plannedDate),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            );

                            final costField = Expanded(
                              flex: stacked ? 0 : 1,
                              child: TextFormField(
                                controller: costController,
                                enabled: !saving,
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: _inputDecoration(
                                  hint: 'Coût estimé',
                                  icon: Icons.payments_outlined,
                                ).copyWith(
                                  suffixText: 'FCFA',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Le coût est obligatoire.';
                                  }

                                  final amount = double.tryParse(
                                    value.replaceAll(',', '.'),
                                  );

                                  if (amount == null ||
                                      !amount.isFinite ||
                                      amount < 0) {
                                    return 'Montant invalide.';
                                  }

                                  return null;
                                },
                              ),
                            );

                            return Flex(
                              direction:
                              stacked ? Axis.vertical : Axis.horizontal,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                dateField,
                                SizedBox(
                                  width: stacked ? 0 : 14,
                                  height: stacked ? 16 : 0,
                                ),
                                costField,
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final stacked = constraints.maxWidth < 450;

                            final statusField = Expanded(
                              flex: stacked ? 0 : 1,
                              child: DropdownButtonFormField<String>(
                                value: status,
                                isExpanded: true,
                                decoration: _inputDecoration(
                                  hint: 'Statut',
                                  icon: Icons.flag_outlined,
                                ),
                                items: _statuses.map((item) {
                                  return DropdownMenuItem(
                                    value: item,
                                    child: Text(
                                      _statusLabel(item),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: saving
                                    ? null
                                    : (value) {
                                  if (value != null) {
                                    setDialogState(
                                          () => status = value,
                                    );
                                  }
                                },
                              ),
                            );

                            final priorityField = Expanded(
                              flex: stacked ? 0 : 1,
                              child: DropdownButtonFormField<String>(
                                value: priority,
                                isExpanded: true,
                                decoration: _inputDecoration(
                                  hint: 'Priorité',
                                  icon: Icons.priority_high_rounded,
                                ),
                                items: _priorities.map((item) {
                                  return DropdownMenuItem(
                                    value: item,
                                    child: Text(
                                      _priorityLabel(item),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: saving
                                    ? null
                                    : (value) {
                                  if (value != null) {
                                    setDialogState(
                                          () => priority = value,
                                    );
                                  }
                                },
                              ),
                            );

                            return Flex(
                              direction:
                              stacked ? Axis.vertical : Axis.horizontal,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                statusField,
                                SizedBox(
                                  width: stacked ? 0 : 14,
                                  height: stacked ? 16 : 0,
                                ),
                                priorityField,
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: saving
                                    ? null
                                    : () => Navigator.pop(dialogContext),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _navy,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: const BorderSide(color: _border),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Annuler'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: saving
                                    ? null
                                    : () async {
                                  if (!formKey.currentState!
                                      .validate()) {
                                    return;
                                  }

                                  setDialogState(() => saving = true);

                                  try {
                                    final token = await _getToken();

                                    final amount = double.parse(
                                      costController.text
                                          .replaceAll(',', '.'),
                                    );

                                    final data = {
                                      'reference':
                                      'MNT-${DateTime.now().millisecondsSinceEpoch}',
                                      'camion_id': selectedTruck!.id,
                                      'type': type,
                                      'description':
                                      descriptionController.text
                                          .trim(),
                                      'statut': status,
                                      'priorite': priority,
                                      'date_planifiee':
                                      _formatDateForApi(plannedDate),
                                      'cout_estime': amount,
                                    };

                                    await _maintenanceService
                                        .createMaintenance(
                                      data,
                                      token: token,
                                    );

                                    if (!mounted) return;

                                    Navigator.pop(dialogContext);
                                    await _loadData();

                                    if (!mounted) return;

                                    _showMessage(
                                      'Maintenance créée avec succès.',
                                    );
                                  } catch (e) {
                                    if (!dialogContext.mounted) return;

                                    setDialogState(
                                          () => saving = false,
                                    );

                                    _showMessage(
                                      'Impossible de créer la maintenance : ${_cleanError(e)}',
                                      isError: true,
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _navy,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: saving
                                    ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Icon(Icons.save_outlined),
                                label: Text(
                                  saving ? 'Enregistrement...' : 'Enregistrer',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    descriptionController.dispose();
    costController.dispose();
  }

  // ============================================================
  // MODIFICATION
  // ============================================================

  Future<void> _showEditMaintenanceDialog(dynamic maintenance) async {
    final rawId = _value(maintenance, 'id');
    final id = int.tryParse(rawId);

    if (id == null) {
      _showMessage('Identifiant de maintenance invalide.', isError: true);
      return;
    }

    final formKey = GlobalKey<FormState>();

    final descriptionController = TextEditingController(
      text: _value(maintenance, 'description'),
    );

    final costController = TextEditingController(
      text: _value(maintenance, 'cout_estime'),
    );

    String status = _canonicalStatus(
      _value(maintenance, 'statut'),
    );

    String priority = _canonicalPriority(
      _value(maintenance, 'priorite'),
    );

    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(26),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _iconBox(Icons.edit_outlined, _navy),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Modifier la maintenance',
                                style: TextStyle(
                                  color: _navy,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: saving
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _fieldLabel('Description *'),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          enabled: !saving,
                          decoration: _inputDecoration(
                            hint: 'Description de l’intervention',
                            icon: Icons.description_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'La description est obligatoire.';
                            }
                            if (value.trim().length < 5) {
                              return 'Saisissez au moins 5 caractères.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _fieldLabel('Statut'),
                        DropdownButtonFormField<String>(
                          value: status,
                          isExpanded: true,
                          decoration: _inputDecoration(
                            hint: 'Statut',
                            icon: Icons.flag_outlined,
                          ),
                          items: _statuses.map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(_statusLabel(item)),
                            );
                          }).toList(),
                          onChanged: saving
                              ? null
                              : (value) {
                            if (value != null) {
                              setDialogState(() => status = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        _fieldLabel('Priorité'),
                        DropdownButtonFormField<String>(
                          value: priority,
                          isExpanded: true,
                          decoration: _inputDecoration(
                            hint: 'Priorité',
                            icon: Icons.priority_high_outlined,
                          ),
                          items: _priorities.map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(_priorityLabel(item)),
                            );
                          }).toList(),
                          onChanged: saving
                              ? null
                              : (value) {
                            if (value != null) {
                              setDialogState(() => priority = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        _fieldLabel('Coût estimé *'),
                        TextFormField(
                          controller: costController,
                          enabled: !saving,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _inputDecoration(
                            hint: 'Montant estimé',
                            icon: Icons.payments_outlined,
                          ).copyWith(suffixText: 'FCFA'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Le coût est obligatoire.';
                            }

                            final amount = double.tryParse(
                              value.replaceAll(',', '.'),
                            );

                            if (amount == null ||
                                !amount.isFinite ||
                                amount < 0) {
                              return 'Montant invalide.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: saving
                                    ? null
                                    : () => Navigator.pop(dialogContext),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                ),
                                child: const Text('Annuler'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: saving
                                    ? null
                                    : () async {
                                  if (!formKey.currentState!
                                      .validate()) {
                                    return;
                                  }

                                  setDialogState(() => saving = true);

                                  try {
                                    final token = await _getToken();

                                    final data = {
                                      'description':
                                      descriptionController.text
                                          .trim(),
                                      'statut': status,
                                      'priorite': priority,
                                      'cout_estime': double.parse(
                                        costController.text
                                            .replaceAll(',', '.'),
                                      ),
                                    };

                                    await _maintenanceService
                                        .updateMaintenance(
                                      id,
                                      data,
                                      token: token,
                                    );

                                    if (!mounted) return;

                                    Navigator.pop(dialogContext);
                                    await _loadData();

                                    if (!mounted) return;

                                    _showMessage(
                                      'Maintenance modifiée avec succès.',
                                    );
                                  } catch (e) {
                                    if (!dialogContext.mounted) return;

                                    setDialogState(
                                          () => saving = false,
                                    );

                                    _showMessage(
                                      'Erreur de modification : ${_cleanError(e)}',
                                      isError: true,
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _navy,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                ),
                                icon: saving
                                    ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Icon(Icons.check_circle_outline),
                                label: Text(
                                  saving ? 'Enregistrement...' : 'Enregistrer',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    descriptionController.dispose();
    costController.dispose();
  }

  // ============================================================
  // SUPPRESSION
  // ============================================================

  Future<void> _deleteMaintenance(dynamic maintenance) async {
    final id = int.tryParse(_value(maintenance, 'id'));

    if (id == null) {
      _showMessage('Identifiant de maintenance invalide.', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Supprimer la maintenance ?',
            style: TextStyle(
              color: _navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Cette opération supprimera cette maintenance. '
                'Voulez-vous continuer ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final token = await _getToken();

      await _maintenanceService.deleteMaintenance(
        id,
        token: token,
      );

      if (!mounted) return;

      await _loadData();

      if (!mounted) return;

      _showMessage('Maintenance supprimée avec succès.');
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Erreur de suppression : ${_cleanError(e)}',
        isError: true,
      );
    }
  }

  // ============================================================
  // UTILITAIRES UI
  // ============================================================

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? const Color(0xFFDC2626) : _navy,
          content: Text(message),
        ),
      );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: _muted, size: 20),
      filled: true,
      fillColor: const Color(0xFFFAFBFD),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _teal, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: _navy,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: _teal,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            color: _navy,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _iconBox(
      IconData icon,
      Color color, {
        double size = 44,
      }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: 23,
      ),
    );
  }

  // ============================================================
  // STRUCTURE PRINCIPALE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Row(
        children: [
          const ResponsableSidebar(
            current: ResponsableMenuItem.maintenance,
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

  Widget _buildHeader() {
    final auth = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    final user = auth.user;

    final fullName =
    user == null ? 'Responsable' : '${user.prenom} ${user.nom}'.trim();

    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'R';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 30,
        vertical: 18,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: _border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Maintenance',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Gestion des interventions et du suivi technique',
                  style: TextStyle(
                    color: Colors.blueGrey.shade500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, color: _navy),
          ),
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 38,
            color: _border,
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 21,
            backgroundColor: _navy,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fullName.isEmpty ? 'Responsable' : fullName,
                style: const TextStyle(
                  fontSize: 13,
                  color: _navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Responsable de flotte',
                style: TextStyle(
                  color: _muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _teal),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(30),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _iconBox(Icons.cloud_off_outlined, Colors.red, size: 60),
              const SizedBox(height: 18),
              const Text(
                'Impossible de charger les données',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  color: _navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _teal,
      onRefresh: _loadData,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 700 ? 16.0 : 28.0;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(horizontalPadding),
            children: [
              _buildWelcomeBanner(),
              const SizedBox(height: 22),
              _buildKpis(),
              const SizedBox(height: 26),
              _buildFilters(),
              const SizedBox(height: 20),
              _buildMaintenanceList(),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
      boxShadow: [
        BoxShadow(
          color: _navy.withValues(alpha: 0.025),
          blurRadius: 15,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildWelcomeBanner() {
    final count = _maintenances.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, Color(0xFF294B72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Suivi technique de la flotte',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$count intervention${count > 1 ? 's' : ''} enregistrée${count > 1 ? 's' : ''} dans votre flotte.',
                  style: const TextStyle(
                    color: Color(0xFFDCE6F1),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _showAddMaintenanceDialog,
                  icon: const Icon(Icons.add, size: 19),
                  label: const Text('Nouvelle maintenance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.build_circle_outlined,
            size: 76,
            color: Color(0x66FFFFFF),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INDICATEURS KPI
  // ============================================================

  Widget _buildKpis() {
    final total = _maintenances.length;

    final planned = _maintenances.where((item) {
      return _canonicalStatus(_value(item, 'statut')) == 'programmée';
    }).length;

    final inProgress = _maintenances.where((item) {
      return _canonicalStatus(_value(item, 'statut')) == 'en_cours';
    }).length;

    final urgent = _maintenances.where((item) {
      final p = _canonicalPriority(_value(item, 'priorite'));
      return p == 'urgente' || p == 'critique';
    }).length;

    final cards = [
      _KpiData(
        title: 'Total interventions',
        value: total,
        icon: Icons.build_outlined,
        color: _navy,
        subtitle: 'Toutes les maintenances',
      ),
      _KpiData(
        title: 'Programmées',
        value: planned,
        icon: Icons.calendar_month_outlined,
        color: const Color(0xFFD97706),
        subtitle: 'À prendre en charge',
      ),
      _KpiData(
        title: 'En cours',
        value: inProgress,
        icon: Icons.engineering_outlined,
        color: const Color(0xFF2563EB),
        subtitle: 'Interventions actives',
      ),
      _KpiData(
        title: 'Priorité élevée',
        value: urgent,
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFDC2626),
        subtitle: 'Urgentes ou critiques',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1200
            ? 4
            : width >= 700
            ? 2
            : 1;

        const gap = 14.0;
        final cardWidth = (width - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards.map((card) {
            return SizedBox(
              width: cardWidth,
              child: _buildKpiCard(card),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildKpiCard(_KpiData data) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _iconBox(data.icon, data.color, size: 49),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${data.value}',
                  style: const TextStyle(
                    fontSize: 27,
                    height: 1.1,
                    color: _navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10,
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
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(Icons.tune_rounded, _navy, size: 38),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rechercher et filtrer',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Retrouvez rapidement une intervention.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();

                  setState(() {
                    _search = '';
                    _statutFilter = 'Tous';
                    _prioriteFilter = 'Toutes';
                  });
                },
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text('Réinitialiser'),
                style: TextButton.styleFrom(
                  foregroundColor: _navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 1050
                  ? 3
                  : width >= 650
                  ? 2
                  : 1;
              const gap = 12.0;
              final fieldWidth = (width - gap * (columns - 1)) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: 14,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _search = value);
                      },
                      decoration: _inputDecoration(
                        hint: 'Camion, référence, description...',
                        icon: Icons.search_rounded,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<String>(
                      value: _statutFilter,
                      isExpanded: true,
                      decoration: _inputDecoration(
                        hint: 'Tous les statuts',
                        icon: Icons.flag_outlined,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'Tous',
                          child: Text('Tous les statuts'),
                        ),
                        ..._statuses.map(
                              (status) => DropdownMenuItem(
                            value: status,
                            child: Text(_statusLabel(status)),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _statutFilter = value);
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<String>(
                      value: _prioriteFilter,
                      isExpanded: true,
                      decoration: _inputDecoration(
                        hint: 'Toutes les priorités',
                        icon: Icons.priority_high_rounded,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'Toutes',
                          child: Text('Toutes les priorités'),
                        ),
                        ..._priorities.map(
                              (priority) => DropdownMenuItem(
                            value: priority,
                            child: Text(_priorityLabel(priority)),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _prioriteFilter = value);
                        }
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
  // LISTE DES MAINTENANCES
  // ============================================================

  Widget _buildMaintenanceList() {
    final items = _filteredMaintenances;

    return Container(
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(21),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registre des maintenances',
                        style: TextStyle(
                          color: _navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${items.length} résultat${items.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Actualiser la liste',
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh_rounded, color: _navy),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _border),
          if (items.isEmpty)
            _buildEmptyState()
          else
            ...List.generate(items.length, (index) {
              return Column(
                children: [
                  _buildMaintenanceItem(items[index]),
                  if (index != items.length - 1)
                    const Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: _border,
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilters = _search.isNotEmpty ||
        _statutFilter != 'Tous' ||
        _prioriteFilter != 'Toutes';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 42,
      ),
      child: Center(
        child: Column(
          children: [
            _iconBox(
              Icons.build_circle_outlined,
              _muted,
              size: 62,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'Aucun résultat trouvé'
                  : 'Aucune maintenance enregistrée',
              style: const TextStyle(
                color: _navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              hasFilters
                  ? 'Essayez de modifier vos critères de recherche.'
                  : 'Créez une maintenance pour commencer le suivi technique.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            if (!hasFilters)
              ElevatedButton.icon(
                onPressed: _showAddMaintenanceDialog,
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle maintenance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: Colors.white,
                ),
              )
            else
              TextButton(
                onPressed: () {
                  _searchController.clear();

                  setState(() {
                    _search = '';
                    _statutFilter = 'Tous';
                    _prioriteFilter = 'Toutes';
                  });
                },
                child: const Text('Effacer les filtres'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceItem(dynamic maintenance) {
    final id = _value(maintenance, 'id');
    final description = _value(maintenance, 'description');
    final reference = _value(maintenance, 'reference');
    final status = _canonicalStatus(
      _value(maintenance, 'statut'),
    );
    final priority = _canonicalPriority(
      _value(maintenance, 'priorite'),
    );
    final cost = _value(maintenance, 'cout_estime');
    final truck = _truckMatricule(maintenance);

    final dateString = _value(maintenance, 'date_planifiee');
    final date = _parseDate(dateString);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 17,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 580;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _iconBox(
                Icons.build_outlined,
                _navy,
                size: compact ? 42 : 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 7,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          description.isNotEmpty
                              ? description
                              : 'Maintenance #$id',
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        _badge(
                          _statusLabel(status),
                          _statusColor(status),
                        ),
                      ],
                    ),
                    if (reference.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        reference,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 9,
                      children: [
                        if (truck.isNotEmpty)
                          _detail(
                            Icons.local_shipping_outlined,
                            truck,
                          ),
                        if (date != null)
                          _detail(
                            Icons.calendar_month_outlined,
                            _formatDate(date),
                          ),
                        if (cost.isNotEmpty)
                          _detail(
                            Icons.payments_outlined,
                            '${_formatAmount(cost)} FCFA',
                          ),
                        _detail(
                          Icons.priority_high_rounded,
                          _priorityLabel(priority),
                          color: _priorityColor(priority),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'Actions',
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: _muted,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditMaintenanceDialog(maintenance);
                  } else if (value == 'delete') {
                    _deleteMaintenance(maintenance);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 19,
                          color: _navy,
                        ),
                        SizedBox(width: 10),
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
                          size: 19,
                          color: Colors.red,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Supprimer',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _detail(
      IconData icon,
      String label, {
        Color color = _muted,
      }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.16),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _KpiData {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _KpiData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });
}
