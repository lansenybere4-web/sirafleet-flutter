import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/mock_data.dart';
import '../models/truck_model.dart';

class TruckMap extends StatefulWidget {
  const TruckMap({super.key});

  @override
  State<TruckMap> createState() => _TruckMapState();
}

class _TruckMapState extends State<TruckMap> {
  static const Color primary = Color(0xFF1D3557);

  TruckModel? _selectedTruck;

  Color _statusColor(String status) {
    switch (status) {
      case 'en_circulation':
        return const Color(0xFF12B76A);

      case 'en_panne':
        return const Color(0xFFF04438);

      case 'maintenance':
        return const Color(0xFFF79009);

      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(12.6392, -8.0029),
              initialZoom: 13,
              onTap: (_, __) {
                setState(() {
                  _selectedTruck = null;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sirafleet.app',
              ),

              MarkerLayer(
                markers: MockData.trucks.map((truck) {
                  final color = _statusColor(truck.statut);

                  return Marker(
                    point: LatLng(
                      truck.latitude,
                      truck.longitude,
                    ),
                    width: 125,
                    height: 85,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTruck = truck;
                        });
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF102A43),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: color,
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.local_shipping_rounded,
                                      color: color,
                                      size: 14,
                                    ),

                                    const SizedBox(width: 5),

                                    Text(
                                      truck.matricule,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 2),

                                Text(
                                  '${truck.vitesse.toStringAsFixed(0)} km/h',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Icon(
                            Icons.location_on,
                            color: color,
                            size: 30,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Légende
        Positioned(
          left: 16,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                _legend(
                  const Color(0xFF12B76A),
                  'En circulation',
                ),
                const SizedBox(width: 12),
                _legend(
                  const Color(0xFFF04438),
                  'Panne',
                ),
                const SizedBox(width: 12),
                _legend(
                  const Color(0xFFF79009),
                  'Maintenance',
                ),
              ],
            ),
          ),
        ),

        // Informations camion sélectionné
        if (_selectedTruck != null)
          Positioned(
            top: 16,
            right: 16,
            child: _truckInfo(_selectedTruck!),
          ),

        // Badge suivi temps réel
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.gps_fixed,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'Suivi en temps réel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _truckInfo(TruckModel truck) {
    final color = _statusColor(truck.statut);

    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping_rounded,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                truck.matricule,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedTruck = null;
                  });
                },
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),

          const Divider(),

          _infoRow(
            'Statut',
            _statusLabel(truck.statut),
            color,
          ),

          _infoRow(
            'Vitesse',
            '${truck.vitesse.toStringAsFixed(0)} km/h',
            primary,
          ),

          _infoRow(
            'Carburant',
            '${truck.carburant.toStringAsFixed(0)} %',
            primary,
          ),

          _infoRow(
            'Chauffeur',
            truck.chauffeur,
            Colors.black87,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
      String label,
      String value,
      Color color,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}