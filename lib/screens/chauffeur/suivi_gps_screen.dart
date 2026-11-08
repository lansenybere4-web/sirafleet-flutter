import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/geo_utils.dart';
import '../../services/signalement_service.dart';
import '../../services/position_mqtt_service.dart'; // NOUVEAU : envoi MQTT
import '../../services/trajet_service.dart';
import '../../widgets/route_layers.dart';
import '../../widgets/sira_map.dart';
import 'alertes_screen.dart';

import '../../providers/auth_provider.dart';
//import '../../services/gps_service.dart';

class SuiviGpsScreen extends StatefulWidget {
  final Map<String, dynamic>? mission;

  const SuiviGpsScreen({super.key, this.mission});

  @override
  State<SuiviGpsScreen> createState() => _SuiviGpsScreenState();
}

class _SuiviGpsScreenState extends State<SuiviGpsScreen> {
  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  //final GpsService _gpsService = GpsService();
  final MapController _mapController = MapController();
  final SignalementService _signalementService = SignalementService();

  // NOUVEAU : service qui envoie la position au broker MQTT
  final PositionMqttService _mqtt = PositionMqttService();

  Timer? _gpsTimer;

  LatLng? _currentPosition;

  bool _gpsConnected = false;
  bool _isLoadingGps = true;
  bool _isSendingPosition = false;
  bool _isSendingSos = false;

  String? _gpsError;

  DateTime? _lastUpdate;
  DateTime? _trackingStartedAt;

  double _currentSpeed = 0.0;
  double _distanceTravelled = 0.0;
  double _distanceRemaining = 0.0;
  int _durationMinutes = 0;

  // ================================================================
  // ITINÉRAIRE RÉEL (calculé par OpenRouteService au démarrage,
  // sauvegardé côté serveur puis simplement affiché ici)
  // ================================================================

  List<LatLng> _routePoints = [];
  final TrajetService _trajetService = TrajetService();
  final List<LatLng> _trace = [];
  int _horsRouteCount = 0;
  bool _recalculating = false;
  DateTime? _lastReroute;

  static const double _seuilDeviationM = 150;
  static const int _fixesAvantRecalcul = 3;
  static const Duration _delaiRecalcul = Duration(minutes: 1);

  static const LatLng _defaultPosition = LatLng(12.6392, -8.0029);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGps();
    });
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _mqtt.arreter(); // NOUVEAU : ferme la connexion MQTT
    super.dispose();
  }

  // ================================================================
  // CHARGER L'ITINÉRAIRE SAUVEGARDÉ
  // ================================================================

  void _loadSavedRoute() {
    final dynamic raw = widget.mission?['itineraire'];

    if (raw is! List || raw.isEmpty) return;

    final List<LatLng> points = [];

    for (final dynamic item in raw) {
      if (item is Map) {
        final lat = item['lat'];
        final lng = item['lng'];

        if (lat != null && lng != null) {
          points.add(LatLng(
            (lat as num).toDouble(),
            (lng as num).toDouble(),
          ));
        }
      }
    }

    if (points.isNotEmpty && mounted) {
      setState(() {
        _routePoints = points;
      });
    }
  }

  // ================================================================
  // INITIALISATION GPS
  // ================================================================

  Future<void> _initializeGps() async {
    if (!mounted) return;

    setState(() {
      _isLoadingGps = true;
      _gpsError = null;
    });

    try {
      if (widget.mission == null) {
        throw Exception('Aucune mission n’a été fournie.');
      }

      if (missionId == '---') {
        throw Exception('Identifiant de mission introuvable.');
      }

      if (destinationPosition == null) {
        throw Exception(
          'Les coordonnées GPS de la destination '
              'ne sont pas disponibles pour cette mission.',
        );
      }

      final bool serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Le service de localisation est désactivé.');
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Permission de localisation refusée.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Permission GPS refusée définitivement. '
              'Activez-la dans les paramètres du téléphone.',
        );
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _loadSavedRoute();

      await _processLocalPosition(position);

      _trackingStartedAt ??= DateTime.now();

      await _refreshLocalPosition();

      _startGpsTracking();
    } catch (e) {
      debugPrint('Erreur initialisation GPS : $e');

      if (!mounted) return;

      setState(() {
        _gpsConnected = false;
        _isLoadingGps = false;
        _gpsError = _cleanError(e);
      });
    }
  }

  // ================================================================
  // SUIVI GPS AUTOMATIQUE
  // ================================================================

  void _startGpsTracking() {
    _gpsTimer?.cancel();
    _trackingStartedAt ??= DateTime.now();

    _gpsTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshLocalPosition();
    });
  }

  // ================================================================
  // LECTURE POSITION GPS
  // ================================================================

  Future<void> _refreshLocalPosition() async {
    if (!mounted || _isSendingPosition) return;

    try {
      _isSendingPosition = true;

      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Le GPS du téléphone est désactivé.');
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Met a jour la carte, la vitesse, la distance... et envoie la position
      await _processLocalPosition(position);
    } catch (e) {
      debugPrint('Erreur position locale : $e');

      if (!mounted) return;

      setState(() {
        _gpsConnected = false;
        _isLoadingGps = false;
        _gpsError = _cleanError(e);
      });
    } finally {
      _isSendingPosition = false;
    }
  }

  // ================================================================
  // TRAITEMENT POSITION LOCALE (+ ENVOI MQTT)
  // ================================================================

  Future<void> _processLocalPosition(Position position) async {
    final LatLng newPosition = LatLng(
      position.latitude.toDouble(),
      position.longitude.toDouble(),
    );

    if (_currentPosition != null) {
      final double distance = _calculateDistance(
        _currentPosition!,
        newPosition,
      );

      if (distance >= 0.005) {
        _distanceTravelled += distance;
      }
    }

    final LatLng? destination = destinationPosition;
    double remaining = 0.0;

    if (destination != null) {
      remaining = _calculateDistance(newPosition, destination);
    }

    final double speed = position.speed > 0 ? position.speed * 3.6 : 0.0;

    _trackingStartedAt ??= DateTime.now();

    final Duration duration = DateTime.now().difference(_trackingStartedAt!);

    if (!mounted) return;

    if (_trace.isEmpty ||
        _calculateDistance(_trace.last, newPosition) >= 0.01) {
      _trace.add(newPosition); // ≥ 10 m
    }

    setState(() {
      _currentPosition = newPosition;
      _currentSpeed = speed;
      _distanceRemaining = remaining;
      _durationMinutes = duration.inMinutes;
      _gpsConnected = true;
      _isLoadingGps = false;
      _lastUpdate = DateTime.now();
      _gpsError = null;
    });

    unawaited(_verifierItineraire(newPosition));

    // NOUVEAU : envoi de la position à l'application (MQTT → Laravel)
    final String matricule = _matriculeCamion;
    if (matricule.isNotEmpty) {
      unawaited(_mqtt.publier(matricule, position));
    } else {
      debugPrint('MQTT : matricule du camion introuvable dans la mission.');
    }

    try {
      _mapController.move(newPosition, 14);
    } catch (_) {
      // La carte peut ne pas être encore initialisée.
    }
  }


  Future<void> _verifierItineraire(LatLng pos) async {
    if (_recalculating) return;

    final bool sansRoute = _routePoints.length < 2;

    if (!sansRoute) {
      final d = GeoUtils.distanceToPolyline(pos, _routePoints);
      _horsRouteCount = d > _seuilDeviationM ? _horsRouteCount + 1 : 0;
    }

    if (!sansRoute && _horsRouteCount < _fixesAvantRecalcul) return;

    final dernier = _lastReroute;
    if (dernier != null && DateTime.now().difference(dernier) < _delaiRecalcul) {
      return; // évite de marteler le serveur
    }

    await _recalculerItineraire(pos, silencieux: sansRoute);
  }

  Future<void> _recalculerItineraire(LatLng pos, {bool silencieux = false}) async {
    final token = context.read<AuthProvider>().token;
    final int? mission = int.tryParse(missionId);

    if (token == null || token.isEmpty || mission == null) return;

    _recalculating = true;
    _lastReroute = DateTime.now();

    try {
      final points = await _trajetService.recalculerItineraire(
        mission,
        token: token,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );

      if (!mounted) return;

      setState(() {
        _routePoints = points;
        _horsRouteCount = 0;
      });

      if (!silencieux) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Itinéraire recalculé.'),
            backgroundColor: accentColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Recalcul itinéraire : $e');
    } finally {
      _recalculating = false;
    }
  }

  // ================================================================
  // CALCUL DISTANCE HAVERSINE (utilisé pour les stats, pas le tracé)
  // ================================================================

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371.0;

    final double lat1 = point1.latitude * math.pi / 180;
    final double lat2 = point2.latitude * math.pi / 180;
    final double deltaLat =
        (point2.latitude - point1.latitude) * math.pi / 180;
    final double deltaLng =
        (point2.longitude - point1.longitude) * math.pi / 180;

    final double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  // ================================================================
  // ACTUALISER GPS
  // ================================================================

  Future<void> _refreshGps() async {
    await _refreshLocalPosition();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _gpsConnected
              ? 'Position GPS mise à jour.'
              : 'Impossible de mettre à jour le GPS.',
        ),
        backgroundColor: _gpsConnected ? accentColor : dangerColor,
      ),
    );
  }

  // ================================================================
  // GETTERS
  // ================================================================

  String get missionId {
    final dynamic id = widget.mission?['id'] ?? widget.mission?['mission_id'];
    return id == null ? '---' : id.toString();
  }

  int? get camionId {
    final Map<String, dynamic>? mission = widget.mission;
    if (mission == null) return null;

    final dynamic directId = mission['camion_id'] ?? mission['camionId'];
    final int? parsedDirect = _toInt(directId);
    if (parsedDirect != null) return parsedDirect;

    final dynamic camion = mission['camion'];
    if (camion is Map) {
      return _toInt(camion['id'] ?? camion['camion_id']);
    }

    return null;
  }

  // NOUVEAU : matricule utilisé dans le topic MQTT
  // (doit être identique à la colonne `matricule` de la table camions)
  String get _matriculeCamion {
    final dynamic camion = widget.mission?['camion'];
    if (camion is Map) {
      return (camion['matricule'] ?? camion['immatriculation'] ?? '')
          .toString()
          .trim();
    }
    return '';
  }

  String get truck {
    final dynamic camion = widget.mission?['camion'];
    if (camion is Map) {
      return camion['immatriculation']?.toString() ??
          camion['matricule']?.toString() ??
          camion['nom']?.toString() ??
          'Camion';
    }
    return camion?.toString() ?? 'Camion';
  }

  String get origin =>
      widget.mission?['origine']?.toString() ?? 'Site minier';

  String get destination =>
      widget.mission?['destination']?.toString() ?? 'Destination';

  LatLng get currentPosition =>
      _currentPosition ?? _originPosition ?? _defaultPosition;

  LatLng? get _originPosition {
    final lat = widget.mission?['origine_lat'];
    final lng = widget.mission?['origine_lng'];
    final double? la = _toDoubleNullable(lat);
    final double? ln = _toDoubleNullable(lng);
    return (la != null && ln != null) ? LatLng(la, ln) : null;
  }

  LatLng? get destinationPosition {
    final lat = widget.mission?['destination_lat'];
    final lng = widget.mission?['destination_lng'];
    final double? la = _toDoubleNullable(lat);
    final double? ln = _toDoubleNullable(lng);
    return (la != null && ln != null) ? LatLng(la, ln) : null;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ma position',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _refreshGps,
            icon: const Icon(Icons.refresh),
          ),
          _buildGpsStatus(),
          const SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildMap()),
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: _buildDestinationCard(),
          ),
          if (_gpsError != null)
            Positioned(
              top: 125,
              left: 14,
              right: 14,
              child: _buildGpsError(),
            ),
          if (_isLoadingGps)
            Positioned(
              top: 190,
              left: 0,
              right: 0,
              child: Center(child: _buildLoadingCard()),
            ),
          Positioned(
            right: 15,
            bottom: 315,
            child: _buildMyLocationButton(),
          ),
          Positioned(left: 15, bottom: 315, child: _buildSosButton()),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _buildBottomInformation(),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CARTE (avec vrai itinéraire routier)
  // ================================================================

  Widget _buildMap() {
    final LatLng? destination = destinationPosition;

    final List<Marker> markers = [
      Marker(
        point: currentPosition,
        width: 70,
        height: 70,
        child: _buildTruckMarker(),
      ),
    ];

    if (destination != null) {
      markers.add(
        Marker(
          point: destination,
          width: 70,
          height: 70,
          child: _buildDestinationMarker(),
        ),
      );
    }



    return SiraMap(
      controller: _mapController,
      initialCenter: currentPosition,
      initialZoom: 13.5,
      initialStyle: SiraMapStyle.plan,
      selectorTop: 104,
      markers: markers,
      extraLayers: RouteLayers.build(
        prevu: _routePoints,
        trace: _trace,
      ),
    );
  }

  Widget _buildTruckMarker() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: primaryColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8),
        ],
      ),
      child: const Icon(Icons.local_shipping, color: Colors.white, size: 27),
    );
  }

  Widget _buildDestinationMarker() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: dangerColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8),
        ],
      ),
      child: const Icon(Icons.flag, color: Colors.white, size: 25),
    );
  }

  Widget _buildDestinationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: dangerColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flag, color: dangerColor, size: 27),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DESTINATION',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  destination,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  destinationPosition != null && _distanceRemaining > 0
                      ? '${_distanceRemaining.toStringAsFixed(1)} km restantes'
                      : 'Distance indisponible',
                  style: const TextStyle(
                    color: dangerColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dangerColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off, color: dangerColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _gpsError!,
              style: const TextStyle(
                color: dangerColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: _initializeGps,
            icon: const Icon(Icons.refresh, color: primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('Localisation GPS...', style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBottomInformation() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.assignment, color: primaryColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MISSION',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '#$missionId',
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('CAMION', style: TextStyle(color: Colors.grey, fontSize: 9)),
                  Text(
                    truck,
                    style: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 13),
          const Divider(height: 1),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _buildSimpleStat(
                  icon: Icons.speed,
                  value: _currentSpeed.toStringAsFixed(0),
                  label: 'km/h',
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildSimpleStat(
                  icon: Icons.route,
                  value: _distanceTravelled.toStringAsFixed(1),
                  label: 'km parcourus',
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildSimpleStat(
                  icon: Icons.timer,
                  value: '$_durationMinutes',
                  label: 'minutes',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildRoutePoint(Icons.circle, accentColor, origin)),
              Container(width: 30, height: 2, color: Colors.grey.shade300),
              Expanded(child: _buildRoutePoint(Icons.flag, dangerColor, destination)),
            ],
          ),
          const SizedBox(height: 14),
          if (_lastUpdate != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_done, size: 15, color: accentColor),
                  const SizedBox(width: 5),
                  Text(
                    'Synchronisé à ${_formatTime(_lastUpdate!)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: destinationPosition != null ? _startNavigation : null,
              icon: const Icon(Icons.navigation, size: 23),
              label: const Text(
                'GUIDAGE',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat({required IconData icon, required String value, required String label}) {
    return Column(
      children: [
        Icon(icon, color: primaryColor, size: 21),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 9),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 40, width: 1, color: Colors.grey.shade200);
  }

  Widget _buildRoutePoint(IconData icon, Color color, String value) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildGpsStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: _gpsConnected ? Colors.greenAccent : dangerColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _gpsConnected ? 'GPS actif' : 'GPS coupé',
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMyLocationButton() {
    return FloatingActionButton(
      heroTag: 'locationButton',
      backgroundColor: Colors.white,
      foregroundColor: primaryColor,
      elevation: 6,
      onPressed: () async {
        if (_currentPosition == null) {
          await _refreshGps();
        }

        if (!mounted) return;

        try {
          _mapController.move(currentPosition, 15);
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous êtes ici.'), duration: Duration(seconds: 1)),
        );
      },
      child: const Icon(Icons.my_location),
    );
  }

  Future<void> _sendSos() async {
    if (_isSendingSos) return;

    final AuthProvider authProvider = context.read<AuthProvider>();
    final String? token = authProvider.token;

    if (token == null || token.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session utilisateur introuvable.'),
          backgroundColor: dangerColor,
        ),
      );
      return;
    }

    final int? mission = int.tryParse(missionId);

    if (mission == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Identifiant de mission introuvable.'),
          backgroundColor: dangerColor,
        ),
      );
      return;
    }

    final int? camion = camionId;

    if (camion == null || camion <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Identifiant du camion introuvable.'),
          backgroundColor: dangerColor,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isSendingSos = true;
      });

      // On récupère une position GPS fraîche avant d'envoyer le SOS.
      Position position;

      try {
        final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

        if (!serviceEnabled) {
          throw Exception('Le GPS du téléphone est désactivé.');
        }

        LocationPermission permission = await Geolocator.checkPermission();

        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw Exception(
            'La permission GPS est nécessaire pour envoyer la position.',
          );
        }

        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
      } catch (e) {
        // Si le GPS vient d'échouer mais qu'on possède déjà une
        // position récente, on l'utilise en secours.
        if (_currentPosition != null) {
          position = Position(
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: _currentSpeed / 3.6,
            speedAccuracy: 0,
            isMocked: false,
          );
        } else {
          rethrow;
        }
      }

      await _signalementService.sendSos(
        token,
        missionId: mission,
        camionId: camion,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 SOS envoyé au responsable de flotte.'),
          backgroundColor: dangerColor,
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AlertesScreen(mission: widget.mission)),
      );
    } catch (e) {
      debugPrint('Erreur SOS : $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cleanError(e)),
          backgroundColor: dangerColor,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingSos = false;
        });
      }
    }
  }

  Widget _buildSosButton() {
    return SizedBox(
      width: 64,
      height: 64,
      child: FloatingActionButton(
        heroTag: 'sosButton',
        backgroundColor: dangerColor,
        foregroundColor: Colors.white,
        elevation: 6,
        onPressed: _isSendingSos ? null : _showSosConfirmation,
        child: _isSendingSos
            ? const SizedBox(
          width: 25,
          height: 25,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Icon(Icons.sos, size: 30),
      ),
    );
  }

  void _startNavigation() {
    final LatLng? destination = destinationPosition;

    if (destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les coordonnées de destination ne sont pas disponibles.'),
          backgroundColor: dangerColor,
        ),
      );
      return;
    }

    try {
      _mapController.move(destination, 14);
    } catch (_) {}

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Destination : $destination'), backgroundColor: accentColor),
    );
  }

  void _showSosConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(Icons.sos, color: dangerColor, size: 28),
              SizedBox(width: 10),
              Text(
                'Urgence',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Vous êtes sur le point de déclencher une alerte SOS.\n\n'
                'Le responsable de flotte recevra immédiatement votre alerte '
                'avec votre position GPS, votre camion et votre mission.',
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('ANNULER'),
            ),
            ElevatedButton.icon(
              onPressed: _isSendingSos
                  ? null
                  : () async {
                Navigator.pop(dialogContext);

                await _sendSos();
              },
              icon: const Icon(Icons.sos),
              label: const Text(
                'OUI, SOS',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  double? _toDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.').trim());
  }

  String _cleanError(Object error) {
    String message = error.toString();
    if (message.startsWith('Exception: ')) {
      message = message.replaceFirst('Exception: ', '');
    }
    return message.trim().isEmpty ? 'Une erreur GPS est survenue.' : message.trim();
  }
}
