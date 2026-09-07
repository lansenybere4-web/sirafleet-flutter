import 'package:flutter/material.dart';

import '../../services/mission_service.dart';
import 'rapport_mission_screen.dart';
import 'suivi_gps_screen.dart';

class MissionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> mission;
  final String? token;

  const MissionDetailScreen({
    super.key,
    required this.mission,
    this.token,
  });

  @override
  State<MissionDetailScreen> createState() =>
      _MissionDetailScreenState();
}

class _MissionDetailScreenState
    extends State<MissionDetailScreen> {
  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  final MissionService _missionService = MissionService();

  late String statut;

  // Indique qu'un appel réseau (démarrage/fin) est en cours,
  // pour désactiver les boutons et éviter les doubles taps.
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();

    statut =
        widget.mission['statut']?.toString() ?? 'Planifiée';
  }

  // ================================================================
  // ID DE LA MISSION
  // ================================================================

  int? get _missionId {
    final dynamic value = widget.mission['id'];

    if (value == null) return null;

    if (value is int) return value;

    return int.tryParse(value.toString());
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.mission['reference']?.toString().isNotEmpty ==
              true
              ? widget.mission['reference'].toString()
              : 'Mission ${widget.mission['id'] ?? ''}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          14,
          14,
          14,
          25,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),

            const SizedBox(height: 18),

            _buildSectionTitle(
              'Mon trajet',
              Icons.route,
            ),

            const SizedBox(height: 10),

            _buildRouteCard(),

            const SizedBox(height: 18),

            _buildSectionTitle(
              'Mon camion',
              Icons.local_shipping_outlined,
            ),

            const SizedBox(height: 10),

            _buildTruckCard(),

            const SizedBox(height: 18),

            _buildSectionTitle(
              'Informations',
              Icons.info_outline,
            ),

            const SizedBox(height: 10),

            _buildInformationCard(),

            const SizedBox(height: 22),

            _buildActions(),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // STATUT
  // ================================================================

  Widget _buildStatusCard() {
    final Color color = _getStatusColor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(),
              color: color,
              size: 32,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'État de la mission',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            statut,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            _getStatusDescription(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusDescription() {
    switch (statut) {
      case 'En cours':
        return 'Vous êtes actuellement en mission';

      case 'Terminée':
        return 'Cette mission a été terminée';

      default:
        return 'Cette mission vous a été attribuée par le responsable';
    }
  }

  // ================================================================
  // TITRE SECTION
  // ================================================================

  Widget _buildSectionTitle(
      String title,
      IconData icon,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          color: primaryColor,
          size: 21,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: primaryColor,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // TRAJET
  // ================================================================

  Widget _buildRouteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildLocation(
            icon: Icons.radio_button_checked,
            color: accentColor,
            label: 'DÉPART',
            value: widget.mission['origine']?.toString() ??
                'Non défini',
          ),

          Row(
            children: [
              const SizedBox(width: 10),
              Container(
                height: 35,
                width: 2,
                color: Colors.grey.shade300,
              ),
            ],
          ),

          _buildLocation(
            icon: Icons.location_on,
            color: dangerColor,
            label: 'ARRIVÉE',
            value:
            widget.mission['destination']?.toString() ??
                'Non définie',
          ),
        ],
      ),
    );
  }

  Widget _buildLocation({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 23,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================================================================
  // CAMION
  // ================================================================

  Widget _buildTruckCard() {
    final camionNom =
    widget.mission['camion']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_shipping,
              color: primaryColor,
              size: 31,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Camion affecté',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  (camionNom == null || camionNom.isEmpty)
                      ? 'Non affecté'
                      : camionNom,
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  widget.mission['type']?.toString() ??
                      'Camion',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
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
  // INFORMATIONS
  // ================================================================

  Widget _buildInformationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.calendar_today,
            'Date',
            widget.mission['date']?.toString() ??
                'Non définie',
          ),

          _divider(),

          _buildInfoRow(
            Icons.access_time,
            'Heure',
            widget.mission['heure']?.toString() ??
                'Non définie',
          ),

          _divider(),

          _buildInfoRow(
            Icons.route,
            'Distance',
            widget.mission['distance']?.toString() ??
                'Non définie',
          ),

          _divider(),

          _buildInfoRow(
            Icons.local_shipping_outlined,
            'Type de transport',
            widget.mission['type']?.toString() ??
                'Transport',
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ACTIONS CHAUFFEUR
  // ================================================================

  Widget _buildActions() {
    // --------------------------------------------------------------
    // MISSION PLANIFIÉE (À VENIR)
    // --------------------------------------------------------------

    if (statut == 'Planifiée') {
      return SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton.icon(
          onPressed: _isUpdating
              ? null
              : () {
            _confirmStartMission(context);
          },
          icon: _isUpdating
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Icon(
            Icons.play_arrow,
            size: 25,
          ),
          label: const Text(
            'DÉMARRER LA MISSION',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    // --------------------------------------------------------------
    // MISSION EN COURS
    // --------------------------------------------------------------

    if (statut == 'En cours') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton.icon(
              onPressed: _openGps,
              icon: const Icon(
                Icons.location_on,
                size: 25,
              ),
              label: const Text(
                'SUIVRE LA MISSION',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton.icon(
              onPressed: _isUpdating
                  ? null
                  : () {
                _confirmFinishMission(context);
              },
              icon: _isUpdating
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: dangerColor,
                ),
              )
                  : const Icon(Icons.flag),
              label: const Text(
                'TERMINER LA MISSION',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: dangerColor,
                side: const BorderSide(
                  color: dangerColor,
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // --------------------------------------------------------------
    // MISSION TERMINÉE (ou Annulée)
    // --------------------------------------------------------------

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: accentColor,
                size: 24,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Mission terminée et enregistrée',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: OutlinedButton.icon(
            onPressed: _openReport,
            icon: const Icon(
              Icons.description_outlined,
            ),
            label: const Text(
              'VOIR LE RAPPORT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(
                color: primaryColor.withValues(alpha: 0.35),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // CONFIRMATION DÉMARRAGE (appelle l'API)
  // ================================================================

  void _confirmStartMission(BuildContext context) {
    final id = _missionId;

    if (id == null) {
      _showError(
        'Cette mission ne possède pas d\'identifiant valide.',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Démarrer la mission ?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'La mission passera en cours et le suivi GPS pourra être utilisé pendant son exécution.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('ANNULER'),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                setState(() {
                  _isUpdating = true;
                });

                try {
                  final updated = await _missionService
                      .startMission(
                    id,
                    token: widget.token,
                  );

                  if (!mounted) return;

                  setState(() {
                    statut = updated.statut;
                    widget.mission['statut'] = updated.statut;
                    _isUpdating = false;
                  });

                  if (!context.mounted) return;

                  _openGps();
                } catch (e) {
                  if (!mounted) return;

                  setState(() {
                    _isUpdating = false;
                  });

                  _showError(
                    e.toString().replaceFirst('Exception: ', ''),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('DÉMARRER'),
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // GPS
  // ================================================================

  void _openGps() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SuiviGpsScreen(
          mission: widget.mission,
        ),
      ),
    );
  }

  // ================================================================
  // TERMINER LA MISSION (appelle l'API après le rapport)
  // ================================================================

  void _confirmFinishMission(BuildContext context) {
    final id = _missionId;

    if (id == null) {
      _showError(
        'Cette mission ne possède pas d\'identifiant valide.',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Terminer la mission ?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Êtes-vous arrivé à destination ? Vous devrez ensuite remplir le rapport de mission.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('PAS ENCORE'),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                if (!context.mounted) return;

                final rapport = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RapportMissionScreen(
                      mission: widget.mission,
                    ),
                  ),
                );

                if (!context.mounted) return;

                // Le statut ne passe à Terminée côté serveur
                // que si le rapport a été validé.
                if (rapport == null) return;

                setState(() {
                  _isUpdating = true;
                });

                try {
                  final updated = await _missionService
                      .completeMission(
                    id,
                    token: widget.token,
                  );

                  if (!mounted) return;

                  setState(() {
                    statut = updated.statut;
                    widget.mission['statut'] = updated.statut;
                    widget.mission['rapport'] = rapport;
                    _isUpdating = false;
                  });

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Mission terminée et rapport envoyé.',
                      ),
                      backgroundColor: accentColor,
                    ),
                  );

                  Navigator.pop(context, true);
                } catch (e) {
                  if (!mounted) return;

                  setState(() {
                    _isUpdating = false;
                  });

                  _showError(
                    e.toString().replaceFirst('Exception: ', ''),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerColor,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'OUI, TERMINER',
              ),
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // RAPPORT
  // ================================================================

  void _openReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RapportMissionScreen(
          mission: widget.mission,
        ),
      ),
    );
  }

  // ================================================================
  // ERREUR
  // ================================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: dangerColor,
      ),
    );
  }

  // ================================================================
  // INFO ROW
  // ================================================================

  Widget _buildInfoRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 19,
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
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================================================================
  // DIVIDER
  // ================================================================

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Divider(
        color: Colors.grey.shade200,
        height: 1,
      ),
    );
  }

  // ================================================================
  // COULEUR STATUT
  // ================================================================

  Color _getStatusColor() {
    switch (statut) {
      case 'En cours':
        return Colors.orange;

      case 'Terminée':
        return accentColor;

      case 'Annulée':
        return dangerColor;

      default:
        return primaryColor;
    }
  }

  // ================================================================
  // ICÔNE STATUT
  // ================================================================

  IconData _getStatusIcon() {
    switch (statut) {
      case 'En cours':
        return Icons.directions_car;

      case 'Terminée':
        return Icons.check_circle;

      case 'Annulée':
        return Icons.cancel;

      default:
        return Icons.schedule;
    }
  }

  // ================================================================
  // DÉCORATION CARTE
  // ================================================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}