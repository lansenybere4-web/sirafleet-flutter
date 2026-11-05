import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

import '../../models/camion_model.dart';
import '../../models/chauffeur_model.dart';
import '../../models/mission.dart';

import '../../services/camion_service.dart';
import '../../services/chauffeur_service.dart';
import '../../services/mission_service.dart';

import '../../widgets/destination_picker.dart';
import '../../providers/auth_provider.dart';

class NouvelleMissionScreen extends StatefulWidget {
  final Mission? missionToEdit;

  const NouvelleMissionScreen({super.key, this.missionToEdit});

  @override
  State<NouvelleMissionScreen> createState() => _NouvelleMissionScreenState();
}

class _NouvelleMissionScreenState extends State<NouvelleMissionScreen> {
  // ================================================================
  // PALETTE
  // ================================================================

  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color borderColor = Color(0xFFE4E7EC);
  static const Color textSecondary = Color(0xFF667085);

  final _formKey = GlobalKey<FormState>();

  final MissionService _missionService = MissionService();
  final CamionService _camionService = CamionService();
  final ChauffeurService _chauffeurService = ChauffeurService();

  // ================================================================
  // CONTROLLERS
  // ================================================================

  final _referenceController = TextEditingController();
  final _objetController = TextEditingController();
  final _origineController = TextEditingController();
  final _destinationController = TextEditingController();
  final _descriptionController = TextEditingController();

  // ================================================================
  // DONNÉES
  // ================================================================

  List<Camion> _camions = [];
  List<Chauffeur> _chauffeurs = [];

  Camion? _selectedCamion;
  Chauffeur? _selectedChauffeur;

  LatLng? _destinationLatLng;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  String _selectedType = 'Transport';
  String _selectedPriorite = 'Normale';

  final List<String> _typesMission = [
    'Transport',
    'Livraison',
    'Approvisionnement',
    'Déplacement',
    'Convoyage',
    'Autre',
  ];

  final List<String> _priorites = ['Basse', 'Normale', 'Haute', 'Urgente'];

  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;

  bool get _isEditing => widget.missionToEdit != null;

  // ================================================================
  // CAMIONS DISPONIBLES UNIQUEMENT
  // ================================================================

  /// Seuls les camions dont le statut réel est "disponible" sont proposés.
  /// En modification, le camion déjà affecté à la mission reste proposé
  /// (même s'il est "en mission" ou autre) pour ne pas casser le formulaire.
  List<Camion> get _camionsDisponibles {
    final editedCamionId = widget.missionToEdit?.camionId;

    return _camions
        .where((c) => c.estDisponible || c.id == editedCamionId)
        .toList();
  }

  /// Valeur du dropdown : on retrouve l'instance présente dans la liste
  /// filtrée (évite l'assertion Flutter si la liste a été rechargée).
  Camion? get _camionSelectionne {
    final selected = _selectedCamion;
    if (selected == null) return null;

    for (final c in _camionsDisponibles) {
      if (c.id == selected.id) return c;
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _objetController.dispose();
    _origineController.dispose();
    _destinationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ================================================================
  // CHARGEMENT
  // ================================================================

  Future<void> _loadData() async {
    final token = context.read<AuthProvider>().token;

    if (token == null || token.trim().isEmpty) {
      setState(() {
        _loading = false;
        _errorMessage = 'Session expirée. Veuillez vous reconnecter.';
      });
      return;
    }

    try {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });

      final results = await Future.wait([
        _camionService.getCamions(token: token),
        _chauffeurService.getChauffeurs(token: token),
      ]);

      if (!mounted) return;

      setState(() {
        _camions = results[0] as List<Camion>;
        _chauffeurs = results[1] as List<Chauffeur>;
        _loading = false;

        // Si le camion sélectionné n'est plus disponible après rechargement,
        // on le désélectionne (sauf en modification de sa propre mission).
        final sel = _selectedCamion;
        if (sel != null && _camionSelectionne == null) {
          _selectedCamion = null;
        }
      });

      if (_isEditing && _referenceController.text.isEmpty) {
        _prefillFromMission(widget.missionToEdit!);
      } else if (!_isEditing && _selectedDate == null) {
        setState(() {
          _selectedDate = DateTime.now();
          _selectedTime = const TimeOfDay(hour: 8, minute: 0);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  void _prefillFromMission(Mission mission) {
    _referenceController.text = mission.reference;
    _objetController.text = mission.objet;
    _origineController.text = mission.origine;
    _destinationController.text = mission.destination;
    _descriptionController.text = mission.description;

    if (_typesMission.contains(mission.type)) _selectedType = mission.type;
    if (_priorites.contains(mission.priorite)) {
      _selectedPriorite = mission.priorite;
    }

    if (mission.destinationLat != null && mission.destinationLng != null) {
      _destinationLatLng =
          LatLng(mission.destinationLat!, mission.destinationLng!);
    }

    if (mission.camionId != null) {
      for (final c in _camions) {
        if (c.id == mission.camionId) {
          _selectedCamion = c;
          break;
        }
      }
    }

    if (mission.chauffeurId != null) {
      for (final c in _chauffeurs) {
        if (c.id == mission.chauffeurId) {
          _selectedChauffeur = c;
          break;
        }
      }
    }

    if (mission.date.isNotEmpty) {
      try {
        _selectedDate = DateTime.parse(mission.date);
      } catch (_) {
        _selectedDate = DateTime.now();
      }
    }

    if (mission.heure.isNotEmpty && mission.heure.contains(':')) {
      final parts = mission.heure.split(':');
      final hour = int.tryParse(parts[0]);
      final minute = parts.length > 1 ? int.tryParse(parts[1]) : 0;

      if (hour != null && minute != null) {
        _selectedTime = TimeOfDay(hour: hour, minute: minute);
      }
    }

    _selectedDate ??= DateTime.now();
    _selectedTime ??= const TimeOfDay(hour: 8, minute: 0);

    if (mounted) setState(() {});
  }

  // ================================================================
  // DATE / HEURE
  // ================================================================

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = _selectedDate ?? today;

    final firstDate = selected.isBefore(today)
        ? DateTime(selected.year, selected.month, selected.day)
        : today;

    final date = await showDatePicker(
      context: context,
      initialDate: selected.isBefore(firstDate) ? firstDate : selected,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5, now.month, now.day),
      helpText: 'Date de la mission',
      cancelText: 'Annuler',
      confirmText: 'Valider',
      locale: const Locale('fr', 'FR'),
    );

    if (date == null) return;
    setState(() => _selectedDate = date);
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Heure de la mission',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );

    if (time == null) return;
    setState(() => _selectedTime = time);
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ================================================================
  // SOUMISSION
  // ================================================================

  Future<void> _submitMission() async {
    FocusScope.of(context).unfocus();
    if (_saving) return;

    if (!_formKey.currentState!.validate()) return;

    final camion = _camionSelectionne;

    if (camion == null) {
      _showError('Veuillez sélectionner un camion disponible.');
      return;
    }

    if (_selectedChauffeur == null) {
      _showError('Veuillez sélectionner un chauffeur.');
      return;
    }

    if (_destinationLatLng == null) {
      _showError('Veuillez sélectionner la destination sur la carte.');
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      _showError('Veuillez sélectionner la date et l\'heure.');
      return;
    }

    final token = context.read<AuthProvider>().token;

    if (token == null || token.trim().isEmpty) {
      _showError('Session expirée. Veuillez vous reconnecter.');
      return;
    }

    try {
      setState(() {
        _saving = true;
        _errorMessage = null;
      });

      final statut = _isEditing ? widget.missionToEdit!.statut : 'a_venir';

      final mission = Mission(
        id: _isEditing ? widget.missionToEdit!.id : null,
        reference: _referenceController.text.trim(),
        objet: _objetController.text.trim(),
        type: _selectedType,
        priorite: _selectedPriorite,
        origine: _origineController.text.trim(),
        destination: _destinationController.text.trim(),
        destinationLat: _destinationLatLng!.latitude,
        destinationLng: _destinationLatLng!.longitude,
        camion: camion.matricule,
        chauffeur: _selectedChauffeur!.nomComplet,
        camionId: camion.id,
        chauffeurId: _selectedChauffeur!.id,
        date: _formatDate(_selectedDate!),
        heure: _formatTime(_selectedTime!),
        distance: '', // calculée automatiquement au démarrage
        statut: statut,
        description: _descriptionController.text.trim(),
      );

      final result = _isEditing
          ? await _missionService.updateMission(mission, token: token)
          : await _missionService.createMission(mission, token: token);

      if (!mounted) return;
      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Mission ${result.reference} modifiée avec succès.'
              : 'Mission ${result.reference} créée avec succès.'),
          backgroundColor: accentColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = _cleanError(e);
      });
      _showError(_errorMessage!);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: dangerColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _cleanError(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Text(
          _isEditing ? 'Modifier la mission' : 'Nouvelle mission',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: borderColor),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null &&
                        _errorMessage!.isNotEmpty)
                      _errorBanner(),

                    _headerCard(),

                    const SizedBox(height: 20),

                    _sectionCard(
                      step: '1',
                      title: 'Informations générales',
                      icon: Icons.assignment_outlined,
                      child: _generalInfoSection(),
                    ),

                    const SizedBox(height: 16),

                    _sectionCard(
                      step: '2',
                      title: 'Affectation',
                      icon: Icons.local_shipping_outlined,
                      subtitle:
                      'Seuls les camions disponibles (ni en mission, ni en maintenance, ni en panne) sont proposés.',
                      child: _affectationSection(),
                    ),

                    const SizedBox(height: 16),

                    _sectionCard(
                      step: '3',
                      title: 'Destination',
                      icon: Icons.pin_drop_outlined,
                      subtitle:
                      'L\'itinéraire sera calculé automatiquement au démarrage de la mission par le chauffeur.',
                      child: _destinationSection(),
                    ),

                    const SizedBox(height: 16),

                    _sectionCard(
                      step: '4',
                      title: 'Planification',
                      icon: Icons.event_outlined,
                      child: _planificationSection(),
                    ),

                    const SizedBox(height: 16),

                    _sectionCard(
                      step: '5',
                      title: 'Description',
                      icon: Icons.notes_outlined,
                      optional: true,
                      child: _descriptionSection(),
                    ),

                    const SizedBox(height: 28),

                    _actionButtons(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // BANNIÈRE ERREUR
  // ================================================================

  Widget _errorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dangerColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: dangerColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: dangerColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: dangerColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // EN-TÊTE
  // ================================================================

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, Color(0xFF2A4A73)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_road_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing
                      ? 'Modifier une mission existante'
                      : 'Planifier une nouvelle mission',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Renseignez les informations ci-dessous et affectez un camion et un chauffeur.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CARTE DE SECTION (réutilisable)
  // ================================================================

  Widget _sectionCard({
    required String step,
    required String title,
    required IconData icon,
    required Widget child,
    String? subtitle,
    bool optional = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  step,
                  style: const TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, color: primaryColor, size: 19),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              if (optional) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Optionnel',
                    style: TextStyle(fontSize: 10, color: textSecondary),
                  ),
                ),
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Text(
                subtitle,
                style: const TextStyle(fontSize: 11.5, color: textSecondary),
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ================================================================
  // SECTION 1 — INFORMATIONS GÉNÉRALES
  // ================================================================

  Widget _generalInfoSection() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _textField(
                controller: _referenceController,
                label: 'Référence',
                hint: 'Ex: MIS-2026-001',
                icon: Icons.tag,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'La référence est obligatoire.'
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 3,
              child: _textField(
                controller: _objetController,
                label: 'Objet de la mission',
                hint: 'Ex: Transport de minerai',
                icon: Icons.description_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'L\'objet est obligatoire.'
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _dropdown<String>(
                value: _selectedType,
                label: 'Type de mission',
                icon: Icons.category_outlined,
                items: _typesMission,
                itemLabel: (v) => v,
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _dropdown<String>(
                value: _selectedPriorite,
                label: 'Priorité',
                icon: Icons.flag_outlined,
                items: _priorites,
                itemLabel: (v) => v,
                onChanged: (v) => setState(() => _selectedPriorite = v!),
                trailingBadge: _prioriteBadge(_selectedPriorite),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget? _prioriteBadge(String priorite) {
    Color color;
    switch (priorite) {
      case 'Urgente':
        color = dangerColor;
        break;
      case 'Haute':
        color = Colors.orange;
        break;
      case 'Basse':
        color = Colors.grey;
        break;
      default:
        color = accentColor;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  // ================================================================
  // SECTION 2 — AFFECTATION
  // ================================================================

  Widget _affectationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _camionDropdown(),
        const SizedBox(height: 8),
        _camionsInfo(),
        const SizedBox(height: 14),
        _chauffeurDropdown(),
      ],
    );
  }

  /// Message d'information sous la liste des camions.
  Widget _camionsInfo() {
    final dispo = _camionsDisponibles.length;
    final total = _camions.length;

    if (total > 0 && dispo == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: dangerColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: dangerColor.withValues(alpha: 0.25)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: dangerColor, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Aucun camion disponible pour le moment : tous sont en '
                    'mission, en maintenance ou en panne.',
                style: TextStyle(fontSize: 12, color: dangerColor),
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      '$dispo camion(s) disponible(s) sur $total',
      style: const TextStyle(fontSize: 11.5, color: textSecondary),
    );
  }

  Widget _camionDropdown() {
    final camions = _camionsDisponibles;

    return DropdownButtonFormField<Camion>(
      value: _camionSelectionne,
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Camion',
        hint: camions.isEmpty
            ? 'Aucun camion disponible'
            : 'Sélectionner un camion disponible',
        icon: Icons.local_shipping_outlined,
      ),
      items: camions.map((c) {
        final marque =
        (c.marque != null && c.marque!.isNotEmpty) ? ' - ${c.marque}' : '';
        final modele =
        (c.modele != null && c.modele!.isNotEmpty) ? ' ${c.modele}' : '';

        return DropdownMenuItem<Camion>(
          value: c,
          child: Text(
            '${c.matricule}$marque$modele',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: camions.isEmpty
          ? null
          : (c) => setState(() => _selectedCamion = c),
      validator: (v) =>
      v == null ? 'Veuillez sélectionner un camion disponible.' : null,
    );
  }

  Widget _chauffeurDropdown() {
    return DropdownButtonFormField<Chauffeur>(
      value: _selectedChauffeur,
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Chauffeur',
        hint: 'Sélectionner un chauffeur',
        icon: Icons.person_outline,
      ),
      items: _chauffeurs.map((c) {
        return DropdownMenuItem<Chauffeur>(
          value: c,
          child: Text(c.nomComplet, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (c) => setState(() => _selectedChauffeur = c),
      validator: (v) =>
      v == null ? 'Veuillez sélectionner un chauffeur.' : null,
    );
  }

  // ================================================================
  // SECTION 3 — DESTINATION
  // ================================================================

  Widget _destinationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. POINT DE DÉPART (saisie texte)
        _textField(
          controller: _origineController,
          label: 'Point de départ',
          hint: 'Ex: Bamako, Entrepôt Principal, Site de Kayes...',
          icon: Icons.trip_origin,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Le point de départ est obligatoire.'
              : null,
        ),

        const SizedBox(height: 20),

        // 2. DESTINATION (sélection sur carte)
        const Text(
          'Destination',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 8),

        DestinationPicker(
          initialPosition: _destinationLatLng,
          initialAddress: _destinationController.text.isNotEmpty
              ? _destinationController.text
              : null,
          onDestinationSelected: (result) {
            setState(() {
              _destinationLatLng = result.position;
              _destinationController.text = result.address;
            });
          },
        ),
      ],
    );
  }

  // ================================================================
  // SECTION 4 — PLANIFICATION
  // ================================================================

  Widget _planificationSection() {
    return Row(
      children: [
        Expanded(child: _dateSelector()),
        const SizedBox(width: 14),
        Expanded(child: _timeSelector()),
      ],
    );
  }

  Widget _dateSelector() {
    final text =
    _selectedDate == null ? 'Sélectionner' : _formatDate(_selectedDate!);

    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration:
        _inputDecoration(label: 'Date', icon: Icons.calendar_today),
        child: Text(
          text,
          style: TextStyle(
            color: _selectedDate == null ? Colors.grey : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _timeSelector() {
    final text =
    _selectedTime == null ? 'Sélectionner' : _formatTime(_selectedTime!);

    return InkWell(
      onTap: _selectTime,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _inputDecoration(label: 'Heure', icon: Icons.access_time),
        child: Text(
          text,
          style: TextStyle(
            color: _selectedTime == null ? Colors.grey : Colors.black87,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // SECTION 5 — DESCRIPTION
  // ================================================================

  Widget _descriptionSection() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 4,
      decoration: _inputDecoration(
        label: 'Notes complémentaires',
        hint: 'Informations utiles pour le chauffeur ou le suivi...',
        icon: Icons.notes,
      ),
    );
  }

  // ================================================================
  // BOUTONS D'ACTION
  // ================================================================

  Widget _actionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: textSecondary,
            side: const BorderSide(color: borderColor),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Annuler'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _saving ? null : _submitMission,
          icon: _saving
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Icon(Icons.check_circle_outline, size: 20),
          label: Text(
            _saving
                ? (_isEditing ? 'Modification...' : 'Création...')
                : (_isEditing
                ? 'Enregistrer les modifications'
                : 'Créer la mission'),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // HELPERS UI
  // ================================================================

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: textSecondary),
      filled: true,
      fillColor: backgroundColor,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dangerColor, width: 1.2),
      ),
      labelStyle: const TextStyle(fontSize: 12.5, color: textSecondary),
      hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _inputDecoration(label: label, hint: hint, icon: icon),
      style: const TextStyle(fontSize: 13.5),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required String label,
    required IconData icon,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
    Widget? trailingBadge,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: _inputDecoration(label: label, icon: icon),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Row(
            children: [
              if (trailingBadge != null && item == value) ...[
                trailingBadge,
                const SizedBox(width: 6),
              ],
              Text(itemLabel(item), overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
