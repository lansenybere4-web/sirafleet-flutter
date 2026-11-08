import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants.dart';

enum SiraMapStyle { sombre, satellite, plan }

class SiraMap extends StatefulWidget {
  final MapController? controller;
  final LatLng initialCenter;
  final double initialZoom;
  final List<Marker> markers;
  final List<Widget> extraLayers; // polylignes (itinéraire prévu / réel)
  final SiraMapStyle initialStyle;
  final double selectorTop;
  final VoidCallback? onMapReady;
  final void Function(TapPosition, LatLng)? onTap;

  const SiraMap({
    super.key,
    this.controller,
    this.initialCenter = const LatLng(12.6392, -8.0029),
    this.initialZoom = 12,
    this.markers = const [],
    this.extraLayers = const [],
    this.initialStyle = SiraMapStyle.sombre,
    this.selectorTop = 12,
    this.onMapReady,
    this.onTap,
  });

  @override
  State<SiraMap> createState() => _SiraMapState();
}

class _SiraMapState extends State<SiraMap> {
  late SiraMapStyle _style = widget.initialStyle;

  // Si MapTiler ne répond pas (clé invalide, origine refusée, quota, réseau),
  // on bascule automatiquement sur des fonds sans clé.
  bool _secours = false;
  int _erreursTuiles = 0;
  static const int _seuilErreurs = 4;

  // ------------------------------------------------------------
  // FONDS DE CARTE
  // ------------------------------------------------------------

  String get _tuilesMapTiler {
    final k = AppConstants.mapTilerKey;
    switch (_style) {
      case SiraMapStyle.sombre:
        return 'https://api.maptiler.com/maps/dataviz-dark/{z}/{x}/{y}.png?key=$k';
      case SiraMapStyle.satellite:
        return 'https://api.maptiler.com/maps/hybrid/{z}/{x}/{y}.jpg?key=$k';
      case SiraMapStyle.plan:
        return 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$k';
    }
  }

  String get _tuilesSecours {
    switch (_style) {
      case SiraMapStyle.sombre:
        return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
      case SiraMapStyle.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/'
            'World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case SiraMapStyle.plan:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  List<String> get _sousDomaines =>
      (_secours && _style == SiraMapStyle.sombre)
          ? const ['a', 'b', 'c', 'd']
          : const <String>[];

  List<SourceAttribution> get _attributions {
    if (!_secours) {
      return const [
        TextSourceAttribution('© MapTiler'),
        TextSourceAttribution('© OpenStreetMap contributors'),
      ];
    }
    switch (_style) {
      case SiraMapStyle.sombre:
        return const [
          TextSourceAttribution('© CARTO'),
          TextSourceAttribution('© OpenStreetMap contributors'),
        ];
      case SiraMapStyle.satellite:
        return const [TextSourceAttribution('© Esri, Maxar, Earthstar')];
      case SiraMapStyle.plan:
        return const [TextSourceAttribution('© OpenStreetMap contributors')];
    }
  }

  void _onTileError(Object error) {
    if (_secours) return;

    _erreursTuiles++;
    debugPrint('Tuile MapTiler en erreur ($_erreursTuiles) : $error');

    if (_erreursTuiles >= _seuilErreurs && mounted) {
      setState(() => _secours = true);
    }
  }

  void _reessayerMapTiler() {
    setState(() {
      _secours = false;
      _erreursTuiles = 0;
    });
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final urlTemplate = _secours ? _tuilesSecours : _tuilesMapTiler;

    return Stack(children: [
      FlutterMap(
        mapController: widget.controller,
        options: MapOptions(
          initialCenter: widget.initialCenter,
          initialZoom: widget.initialZoom,
          minZoom: 4,
          maxZoom: 18,
          onMapReady: widget.onMapReady,
          onTap: widget.onTap,
        ),
        children: [
          TileLayer(
            key: ValueKey('$_secours-${_style.name}'),
            urlTemplate: urlTemplate,
            subdomains: _sousDomaines,
            userAgentPackageName: 'com.sirafleet.app',
            maxNativeZoom: 18,
            errorTileCallback: (tile, error, stackTrace) => _onTileError(error),
          ),
          ...widget.extraLayers,
          MarkerLayer(markers: widget.markers),
          RichAttributionWidget(attributions: _attributions),
        ],
      ),
      Positioned(
        top: widget.selectorTop,
        right: 12,
        child: SegmentedButton<SiraMapStyle>(
          showSelectedIcon: false,
          selected: {_style},
          onSelectionChanged: (s) => setState(() => _style = s.first),
          segments: const [
            ButtonSegment(value: SiraMapStyle.sombre, label: Text('Sombre')),
            ButtonSegment(value: SiraMapStyle.satellite, label: Text('Satellite')),
            ButtonSegment(value: SiraMapStyle.plan, label: Text('Plan')),
          ],
        ),
      ),
      if (_secours)
        Positioned(
          left: 8,
          bottom: 8,
          child: Material(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _reessayerMapTiler,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 14, color: Colors.orange),
                    SizedBox(width: 6),
                    Text(
                      'MapTiler indisponible · fond de secours (toucher pour réessayer)',
                      style: TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}
