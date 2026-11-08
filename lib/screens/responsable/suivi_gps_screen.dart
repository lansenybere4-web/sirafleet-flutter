import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/gps_position_model.dart';
import '../../services/gps_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/sira_map.dart';
import 'dashboard_screen.dart';
import '../../services/trajet_service.dart';
import '../../models/trajet_reel_model.dart';
import '../../widgets/route_layers.dart';

import '../../services/mission_service.dart';
import '../../models/mission.dart';

class SuiviGpsScreen extends StatefulWidget {
  const SuiviGpsScreen({super.key});

  @override
  State<SuiviGpsScreen> createState() => _SuiviGpsScreenState();
}

class _SuiviGpsScreenState extends State<SuiviGpsScreen> {
  // ============================================================
  // COULEURS
  // ============================================================

  static const Color background = Color(0xFFF5F7FA);
  static const Color card = Colors.white;
  static const Color primary = Color(0xFF1D3557);
  static const Color textPrimary = Color(0xFF101828);
  static const Color textSecondary = Color(0xFF667085);
  static const Color borderColor = Color(0xFFE4E7EC);

  static const Color successColor = Color(0xFF12B76A);
  static const Color dangerColor = Color(0xFFF04438);
  static const Color warningColor = Color(0xFFF79009);

  // ============================================================
  // SERVICES
  // ============================================================

  final GpsService _gpsService = GpsService();
  final MissionService _missionService = MissionService();

  // ============================================================
  // ITINÉRAIRE DU CAMION SÉLECTIONNÉ
  // ============================================================

  List<LatLng> _selectedRoute = [];
  LatLng? _selectedDestination;
  bool _loadingRoute = false;

  // ============================================================
  // CARTE
  // ============================================================

  final MapController _mapController = MapController();

  bool _mapReady = false;

  static const LatLng _bamakoCenter = LatLng(12.6392, -8.0029);

  // ============================================================
  // ETAT
  // ============================================================

  List<PositionGpsModel> _positions = [];

  PositionGpsModel? _selectedPosition;

  bool _isLoading = true;
  bool _isRefreshing = false;

  String? _errorMessage;

  String _filter = 'Tous';
  String _search = '';

  Timer? _refreshTimer;

  final TrajetService _trajetService = TrajetService();
  TrajetReel? _trajetReel;
  int? _selectedMissionId;
  bool _showPrevu = true;
  bool _showReel = true;
  Timer? _reelTimer;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadFleetPositions();

    // Positions de la flotte toutes les 10 s
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadFleetPositions(silent: true);
    });

    // Trajet réel (recalage OSRM) toutes les 60 s
    _reelTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _loadTrajetReel();
    });
  }
  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _reelTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // CHARGEMENT GPS
  // ============================================================

  Future<void> _loadFleetPositions({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      if (!mounted) return;
      setState(() => _isRefreshing = true);
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        throw Exception('Session utilisateur expirée. Veuillez vous reconnecter.');
      }

      final positions = await _gpsService.getFleetPositions(token: token);

      if (!mounted) return;

      setState(() {
        _positions = positions;
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = null;

        if (_selectedPosition != null) {
          final selectedId = _selectedPosition!.camionId;

          try {
            _selectedPosition = positions.firstWhere(
                  (position) => position.camionId == selectedId,
            );
          } catch (_) {
            _selectedPosition = null;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // ITINÉRAIRE DU CAMION SÉLECTIONNÉ
  // ============================================================

  Future<void> _loadRouteForSelectedTruck() async {
    final int? camId = _selectedPosition?.camionId;

    if (camId == null) {
      setState(() {
        _selectedRoute = [];
        _selectedDestination = null;
        _trajetReel = null;
        _selectedMissionId = null;
      });
      return;
    }

    setState(() {
      _loadingRoute = true;
      _trajetReel = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final Mission? mission =
      await _missionService.getActiveMissionForCamion(camId, token: token);

      if (!mounted) return;

      if (mission == null) {
        setState(() {
          _selectedRoute = [];
          _selectedDestination = null;
          _selectedMissionId = null;
          _loadingRoute = false;
        });
        return;
      }

      setState(() {
        _selectedMissionId = mission.id;
        _selectedRoute = mission.itineraire;
        _selectedDestination =
        (mission.destinationLat != null && mission.destinationLng != null)
            ? LatLng(mission.destinationLat!, mission.destinationLng!)
            : null;
        _loadingRoute = false;
      });

      await _loadTrajetReel();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _selectedRoute = [];
        _selectedDestination = null;
        _selectedMissionId = null;
        _loadingRoute = false;
      });
    }
  }

  Future<void> _loadTrajetReel() async {
    final int? id = _selectedMissionId;
    if (id == null) return;

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null || token.isEmpty) return;

      final reel = await _trajetService.getTrajetReel(id, token: token);

      if (!mounted || _selectedMissionId != id) return;
      setState(() => _trajetReel = reel);
    } catch (e) {
      debugPrint('Trajet réel : $e');
    }
  }

  // ============================================================
  // POSITIONS FILTREES
  // ============================================================

  List<PositionGpsModel> get _filteredPositions {
    final search = _search.toLowerCase().trim();

    return _positions.where((position) {
      bool matchesFilter = true;

      final status = position.camionStatut ?? '';

      if (_filter == 'Circulation') {
        matchesFilter = status == 'en_circulation';
      } else if (_filter == 'Panne') {
        matchesFilter = status == 'en_panne';
      } else if (_filter == 'Maintenance') {
        matchesFilter = status == 'maintenance';
      }

      final matricule = position.matricule?.toLowerCase() ?? '';
      final chauffeur = position.chauffeurNom?.toLowerCase() ?? '';

      final matchesSearch = search.isEmpty ||
          matricule.contains(search) ||
          chauffeur.contains(search);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  // ============================================================
  // COULEUR / LABEL STATUT
  // ============================================================

  Color _statusColor(String? status) {
    switch (status) {
      case 'disponible':
        return primary;
      case 'en_circulation':
        return successColor;
      case 'en_panne':
        return dangerColor;
      case 'maintenance':
        return warningColor;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'disponible':
        return 'Disponible';
      case 'en_circulation':
        return 'En circulation';
      case 'en_panne':
        return 'En panne';
      case 'maintenance':
        return 'Maintenance';
      default:
        return 'Inconnu';
    }
  }

  // ============================================================
  // CENTRER SUR CAMION
  // ============================================================

  void _moveToPosition(PositionGpsModel position, {double zoom = 14}) {
    if (!_mapReady) return;

    _mapController.move(
      LatLng(position.latitude, position.longitude),
      zoom,
    );
  }

  // ============================================================
  // SELECTION CAMION (une seule déclaration)
  // ============================================================

  void _selectPosition(PositionGpsModel position, {double zoom = 14}) {
    setState(() {
      _selectedPosition = position;
    });

    _moveToPosition(position, zoom: zoom);
    _loadRouteForSelectedTruck();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Row(
                children: [
                  _buildPositionList(),
                  Expanded(child: _buildMap()),
                  if (_selectedPosition != null) _buildPositionDetails(),
                ],
              ),
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
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: card,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Retour au tableau de bord',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const ResponsableDashboardScreen(),
                ),
              );
            },
            icon: const Icon(Icons.arrow_back_rounded, color: primary, size: 23),
          ),
          const SizedBox(width: 5),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: successColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.gps_fixed_rounded, color: successColor, size: 22),
          ),
          const SizedBox(width: 12),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SUIVI GPS',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Localisation en temps réel de la flotte',
                style: TextStyle(color: textSecondary, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          _buildGpsStatus(),
          const SizedBox(width: 18),
          Text(
            '${_filteredPositions.length} camion(s)',
            style: const TextStyle(color: textSecondary, fontSize: 11),
          ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _isRefreshing ? null : () => _loadFleetPositions(),
            icon: _isRefreshing
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.refresh_rounded, color: textSecondary),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUT GPS
  // ============================================================

  Widget _buildGpsStatus() {
    final connected = _errorMessage == null && !_isLoading;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: connected
            ? successColor.withValues(alpha: 0.10)
            : dangerColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: connected
              ? successColor.withValues(alpha: 0.25)
              : dangerColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, color: connected ? successColor : dangerColor, size: 8),
          const SizedBox(width: 7),
          Text(
            connected ? 'GPS CONNECTÉ' : 'GPS DÉCONNECTÉ',
            style: TextStyle(
              color: connected ? successColor : dangerColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LISTE DES CAMIONS
  // ============================================================

  Widget _buildPositionList() {
    return Container(
      width: 285,
      decoration: const BoxDecoration(
        color: card,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: TextField(
              onChanged: (value) => setState(() => _search = value),
              style: const TextStyle(color: textPrimary, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Rechercher un camion...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 19),
                filled: true,
                fillColor: background,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          _buildFilters(),
          const Divider(color: borderColor, height: 1),
          Expanded(child: _buildListContent()),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENU LISTE
  // ============================================================

  Widget _buildListContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final positions = _filteredPositions;

    if (positions.isEmpty) {
      return _buildEmptyPositionList();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: positions.length,
      itemBuilder: (context, index) {
        final position = positions[index];
        final selected = _selectedPosition?.camionId == position.camionId;
        return _positionListItem(position, selected);
      },
    );
  }

  // ============================================================
  // ERREUR
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40, color: dangerColor),
            const SizedBox(height: 12),
            const Text(
              'Impossible de récupérer les positions GPS',
              textAlign: TextAlign.center,
              style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Erreur inconnue',
              textAlign: TextAlign.center,
              style: const TextStyle(color: textSecondary, fontSize: 10),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () => _loadFleetPositions(),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LISTE VIDE
  // ============================================================

  Widget _buildEmptyPositionList() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined, size: 40, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              'Aucune position GPS trouvée',
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
            SizedBox(height: 6),
            Text(
              'Les camions avec une position GPS connue apparaîtront ici.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FILTRES
  // ============================================================

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _filterButton('Tous'),
          const SizedBox(width: 6),
          _filterButton('Circulation'),
          const SizedBox(width: 6),
          _filterButton('Panne'),
          const SizedBox(width: 6),
          _filterButton('Maintenance'),
        ],
      ),
    );
  }

  Widget _filterButton(String title) {
    final selected = _filter == title;

    return GestureDetector(
      onTap: () => setState(() => _filter = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? primary : background,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: selected ? primary : borderColor),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? Colors.white : textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ITEM POSITION
  // ============================================================

  Widget _positionListItem(PositionGpsModel position, bool selected) {
    final statusColor = _statusColor(position.camionStatut);

    return GestureDetector(
      onTap: () => _selectPosition(position),
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? primary : borderColor),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.local_shipping_rounded, color: statusColor, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        position.matricule ?? 'Camion #${position.camionId ?? '-'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        position.chauffeurNom ?? 'Chauffeur non renseigné',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: textSecondary, fontSize: 9),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _smallInfo(Icons.speed_rounded, position.vitesseLabel),
                const Spacer(),
                _smallInfo(Icons.location_on_outlined, position.datePositionLabel),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallInfo(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.grey.shade400, size: 13),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: textSecondary, fontSize: 8),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CARTE (avec itinéraire du camion sélectionné)
  // ============================================================

  Widget _buildMap() {
    final positions = _filteredPositions;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SiraMap(
              controller: _mapController,
              initialCenter: _bamakoCenter,
              initialZoom: 13,
              initialStyle: SiraMapStyle.plan,
              onMapReady: () => _mapReady = true,
              extraLayers: RouteLayers.build(
                prevu: _selectedRoute,
                reel: _trajetReel,
                showPrevu: _showPrevu,
                showReel: _showReel,
              ),
              markers: [
                if (_selectedDestination != null)
                  Marker(
                    point: _selectedDestination!,
                    width: 46,
                    height: 46,
                    child: const Icon(Icons.flag_circle, color: dangerColor, size: 40),
                  ),
                ...positions.map(_buildTruckMarker),
              ],
            ),
          ),
        ),



        // ========================================================
        // LEGENDE
        // ========================================================

        Positioned(
          left: 25,
          bottom: 25,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _legend(successColor, 'Circulation'),
                const SizedBox(width: 12),
                _legend(dangerColor, 'Panne'),
                const SizedBox(width: 12),
                _legend(warningColor, 'Maintenance'),
              ],
            ),
          ),
        ),

        // ========================================================
        // RECENTRAGE BAMAKO
        // ========================================================

        Positioned(
          right: 25,
          bottom: 25,
          child: FloatingActionButton.small(
            heroTag: 'centerMap',
            backgroundColor: card,
            elevation: 3,
            onPressed: () {
              if (_mapReady) {
                _mapController.move(_bamakoCenter, 13);
              }
            },
            child: const Icon(Icons.my_location_rounded, color: primary, size: 18),
          ),
        ),
      ],
    );
  }

  Marker _buildTruckMarker(PositionGpsModel position) {
    final color = _statusColor(position.camionStatut);
    final selected = _selectedPosition?.camionId == position.camionId;

    return Marker(
      point: LatLng(position.latitude, position.longitude),
      width: 110,
      height: 80,
      child: GestureDetector(
        onTap: () => _selectPosition(position, zoom: 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 105),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: selected ? primary : Colors.white,
                borderRadius: BorderRadius.circular(5),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
              ),
              child: Text(
                position.matricule ?? 'Camion',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : color,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(Icons.local_shipping_rounded, color: color, size: selected ? 38 : 32),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LEGENDE
  // ============================================================

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: textSecondary, fontSize: 9)),
      ],
    );
  }

  // ============================================================
  // DETAILS
  // ============================================================

  Widget _buildPositionDetails() {
    final position = _selectedPosition!;
    final color = _statusColor(position.camionStatut);

    return Container(
      width: 285,
      decoration: const BoxDecoration(
        color: card,
        border: Border(left: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'DÉTAILS DU CAMION',
                    style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Fermer',
                  onPressed: () => setState(() {
                    _selectedPosition = null;
                    _selectedRoute = [];
                    _selectedDestination = null;
                    _trajetReel = null;
                    _selectedMissionId = null;
                  }),
                  icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 18),
                ),
              ],
            ),
          ),
          const Divider(color: borderColor, height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.local_shipping_rounded, color: color, size: 38),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      position.matricule ?? 'Camion #${position.camionId ?? '-'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(position.camionStatut),
                        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // ------------------------------------------------
                  // STATUT ITINÉRAIRE
                  // ------------------------------------------------

                  if (_loadingRoute)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Chargement de l\'itinéraire...',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else if (_selectedRoute.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.route, size: 14, color: successColor),
                          SizedBox(width: 6),
                          Text(
                            'Itinéraire actif affiché',
                            style: TextStyle(fontSize: 10, color: successColor),
                          ),
                        ],
                      ),
                    ),

                  if (_selectedRoute.isNotEmpty || _trajetReel?.aDesDonnees == true)
                    _buildRouteControls(),

                  const SizedBox(height: 25),

                  _detailRow('Chauffeur', position.chauffeurNom ?? 'Non renseigné',
                      Icons.person_outline_rounded),
                  _detailRow('Vitesse', position.vitesseLabel, Icons.speed_rounded),
                  _detailRow('Latitude', position.latitude.toStringAsFixed(6),
                      Icons.location_on_outlined),
                  _detailRow('Longitude', position.longitude.toStringAsFixed(6),
                      Icons.location_on_outlined),
                  _detailRow(
                    'Précision GPS',
                    position.precisionGps != null
                        ? '${position.precisionGps!.toStringAsFixed(1)} m'
                        : 'Non disponible',
                    Icons.gps_fixed_rounded,
                  ),
                  _detailRow(
                    'Altitude',
                    position.altitude != null
                        ? '${position.altitude!.toStringAsFixed(1)} m'
                        : 'Non disponible',
                    Icons.height_rounded,
                  ),
                  _detailRow(
                    'Direction',
                    position.direction != null
                        ? '${position.direction!.toStringAsFixed(0)}°'
                        : 'Non disponible',
                    Icons.explore_outlined,
                  ),
                  _detailRow('Date position', position.datePositionLabel, Icons.schedule_outlined),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _moveToPosition(position, zoom: 16),
                      icon: const Icon(Icons.gps_fixed_rounded, size: 16),
                      label: const Text(
                        'CENTRER SUR LE CAMION',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteControls() {
    final reel = _trajetReel;
    final ecart = reel?.ecart;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Prévu', style: TextStyle(fontSize: 10)),
                selected: _showPrevu,
                selectedColor: RouteLayers.prevuColor.withValues(alpha: 0.2),
                onSelected: (v) => setState(() => _showPrevu = v),
              ),
              FilterChip(
                label: const Text('Réel', style: TextStyle(fontSize: 10)),
                selected: _showReel,
                selectedColor: RouteLayers.reelColor.withValues(alpha: 0.2),
                onSelected: (v) => setState(() => _showReel = v),
              ),
            ],
          ),
          if (reel != null && reel.aDesDonnees && !reel.matchOk)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Tracé GPS brut (recalage routier impossible)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: Colors.grey),
              ),
            ),
          if (reel != null && reel.matchOk)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${reel.distanceKm.toStringAsFixed(1)} km parcourus',
                style: const TextStyle(fontSize: 10, color: textSecondary),
              ),
            ),
          if (ecart != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Écart max ${ecart.maxM} m · moyen ${ecart.moyenM} m · '
                    '${ecart.pourcentageHors}% hors tracé',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9, color: textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // LIGNE DETAIL
  // ============================================================

  Widget _detailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(color: textSecondary, fontSize: 10)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: textPrimary, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}