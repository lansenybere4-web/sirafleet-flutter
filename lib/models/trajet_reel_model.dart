import 'package:latlong2/latlong.dart';

class EcartTrajet {
  final int maxM;
  final int moyenM;
  final double pourcentageHors;

  const EcartTrajet({
    required this.maxM,
    required this.moyenM,
    required this.pourcentageHors,
  });

  factory EcartTrajet.fromJson(Map<String, dynamic> json) => EcartTrajet(
    maxM: (json['ecart_max_m'] as num?)?.toInt() ?? 0,
    moyenM: (json['ecart_moyen_m'] as num?)?.toInt() ?? 0,
    pourcentageHors: (json['pourcentage_hors'] as num?)?.toDouble() ?? 0,
  );
}

class TrajetReel {
  final int nombrePositions;

  /// true si OSRM a réussi à recaler les positions sur le réseau routier.
  final bool matchOk;

  /// Tracé recalé sur les routes (un segment par portion continue).
  final List<List<LatLng>> segments;

  /// Positions GPS brutes (≤ 300) : repli si le recalage échoue (pistes minières).
  final List<LatLng> positionsBrutes;

  final double distanceKm;
  final EcartTrajet? ecart;

  const TrajetReel({
    required this.nombrePositions,
    required this.matchOk,
    required this.segments,
    required this.positionsBrutes,
    required this.distanceKm,
    this.ecart,
  });

  bool get aDesDonnees => segments.isNotEmpty || positionsBrutes.length >= 2;

  factory TrajetReel.fromJson(Map<String, dynamic> json) {
    final segments = <List<LatLng>>[];
    double distance = 0;

    final rawSegments = json['segments'];
    if (rawSegments is List) {
      for (final s in rawSegments) {
        if (s is! Map) continue;

        distance += (s['distance_km'] as num?)?.toDouble() ?? 0;

        final geometry = s['geometry'];
        final coords = geometry is Map ? geometry['coordinates'] : null;
        if (coords is! List) continue;

        // GeoJSON : [longitude, latitude]
        final points = <LatLng>[];
        for (final c in coords) {
          if (c is List && c.length >= 2) {
            points.add(LatLng(
              (c[1] as num).toDouble(),
              (c[0] as num).toDouble(),
            ));
          }
        }
        if (points.length >= 2) segments.add(points);
      }
    }

    final brutes = <LatLng>[];
    final rawBrutes = json['positions_brutes'];
    if (rawBrutes is List) {
      for (final p in rawBrutes) {
        // Format backend : [latitude, longitude]
        if (p is List && p.length >= 2) {
          brutes.add(LatLng(
            (p[0] as num).toDouble(),
            (p[1] as num).toDouble(),
          ));
        }
      }
    }

    final rawEcart = json['ecart'];

    return TrajetReel(
      nombrePositions: (json['nombre_positions'] as num?)?.toInt() ?? 0,
      matchOk: json['match_ok'] == true,
      segments: segments,
      positionsBrutes: brutes,
      distanceKm: distance,
      ecart: rawEcart is Map
          ? EcartTrajet.fromJson(Map<String, dynamic>.from(rawEcart))
          : null,
    );
  }
}
