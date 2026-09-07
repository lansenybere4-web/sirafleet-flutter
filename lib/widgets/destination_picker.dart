import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

/// Sélecteur de destination pro : recherche d'adresse (Nominatim)
/// + ajustement fin en tapant/glissant le marqueur sur la carte OSM.
class DestinationPicker extends StatefulWidget {
  final LatLng? initialPosition;
  final String? initialAddress;
  final ValueChanged<DestinationResult> onDestinationSelected;

  const DestinationPicker({
    super.key,
    this.initialPosition,
    this.initialAddress,
    required this.onDestinationSelected,
  });

  @override
  State<DestinationPicker> createState() => _DestinationPickerState();
}

class DestinationResult {
  final LatLng position;
  final String address;
  DestinationResult({required this.position, required this.address});
}

class _Suggestion {
  final LatLng position;
  final String displayName;
  _Suggestion({required this.position, required this.displayName});
}

class _DestinationPickerState extends State<DestinationPicker> {
  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);

  // Nominatim exige un User-Agent identifiable (politique d'usage OSM).
  static const Map<String, String> _headers = {
    'User-Agent': 'SiraFleetApp/1.0 (contact@sirafleet.example)',
  };

  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  Timer? _debounce;
  LatLng? _selectedPosition;
  String _selectedAddress = '';
  List<_Suggestion> _suggestions = [];
  bool _searching = false;

  static const LatLng _bamakoCenter = LatLng(12.6392, -8.0029);

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    _selectedAddress = widget.initialAddress ?? '';
    _searchController.text = _selectedAddress;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // ==============================================================
  // RECHERCHE (débounce 600ms — respecte la limite Nominatim 1 req/s)
  // ==============================================================

  void _onSearchChanged(String input) {
    _debounce?.cancel();

    if (input.trim().length < 3) {
      setState(() => _suggestions = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 600), () {
      _searchAddress(input);
    });
  }

  Future<void> _searchAddress(String input) async {
    setState(() => _searching = true);

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': input,
      'format': 'json',
      'addressdetails': '0',
      'limit': '6',
      'countrycodes': 'ml', // biaise sur le Mali, retire si besoin
      'accept-language': 'fr',
    });

    try {
      final response = await http.get(uri, headers: _headers);
      final List data = jsonDecode(response.body);

      setState(() {
        _suggestions = data.map((item) {
          return _Suggestion(
            position: LatLng(
              double.parse(item['lat']),
              double.parse(item['lon']),
            ),
            displayName: item['display_name'],
          );
        }).toList();
      });
    } catch (_) {
      // silencieux — l'utilisateur peut toujours pointer sur la carte
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _selectSuggestion(_Suggestion suggestion) {
    setState(() {
      _selectedPosition = suggestion.position;
      _selectedAddress = suggestion.displayName;
      _searchController.text = suggestion.displayName;
      _suggestions = [];
    });

    _mapController.move(suggestion.position, 15);

    widget.onDestinationSelected(
      DestinationResult(
        position: suggestion.position,
        address: suggestion.displayName,
      ),
    );
  }

  // ==============================================================
  // GÉOCODAGE INVERSE (ajustement manuel sur la carte)
  // ==============================================================

  Future<void> _reverseGeocode(LatLng position) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': position.latitude.toString(),
      'lon': position.longitude.toString(),
      'format': 'json',
      'accept-language': 'fr',
    });

    String address =
        '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';

    try {
      final response = await http.get(uri, headers: _headers);
      final data = jsonDecode(response.body);
      if (data['display_name'] != null) {
        address = data['display_name'];
      }
    } catch (_) {
      // on garde les coordonnées brutes comme libellé de secours
    }

    if (!mounted) return;

    setState(() {
      _selectedAddress = address;
      _searchController.text = address;
    });

    widget.onDestinationSelected(
      DestinationResult(position: position, address: address),
    );
  }

  void _onMapTapped(TapPosition tapPosition, LatLng position) {
    setState(() {
      _selectedPosition = position;
      _suggestions = [];
    });
    _reverseGeocode(position);
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ------------------------------------------------------
        // BARRE DE RECHERCHE
        // ------------------------------------------------------
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Rechercher une adresse ou un lieu...',
              prefixIcon: Icon(Icons.search, color: primaryColor),
              suffixIcon: _searching
                  ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            ),
          ),
        ),

        // ------------------------------------------------------
        // SUGGESTIONS
        // ------------------------------------------------------
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
              ],
            ),
            child: Column(
              children: _suggestions.map((s) {
                return ListTile(
                  dense: true,
                  leading:
                  const Icon(Icons.location_on_outlined, color: accentColor),
                  title: Text(s.displayName,
                      style: const TextStyle(fontSize: 12.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  onTap: () => _selectSuggestion(s),
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 12),

        // ------------------------------------------------------
        // CARTE (ajustement fin)
        // ------------------------------------------------------
        Container(
          height: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.antiAlias,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPosition ?? _bamakoCenter,
              initialZoom: _selectedPosition != null ? 14 : 12,
              onTap: _onMapTapped,
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sirafleet.app',
              ),
              if (_selectedPosition != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _selectedPosition!,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.location_on,
                        color: Color(0xFFE63946), size: 42),
                  ),
                ]),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Tape le point exact sur la carte pour l\'ajuster.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
        ),

        // ------------------------------------------------------
        // RÉCAP ADRESSE SÉLECTIONNÉE
        // ------------------------------------------------------
        if (_selectedPosition != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.flag, color: accentColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedAddress,
                    style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}