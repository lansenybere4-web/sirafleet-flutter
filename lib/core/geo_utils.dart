import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

class GeoUtils {
  /// Distance (en mètres) entre le point [p] et la polyligne [line]
  /// (projection équirectangulaire locale, précise sur de courtes distances).
  static double distanceToPolyline(LatLng p, List<LatLng> line) {
    if (line.isEmpty) return double.infinity;

    if (line.length == 1) {
      return const Distance().as(LengthUnit.Meter, p, line.first);
    }

    const double k = 111320; // mètres par degré de latitude
    final double cosLat = math.cos(p.latitude * math.pi / 180);

    double best = double.infinity;

    for (var i = 0; i < line.length - 1; i++) {
      final a = line[i];
      final b = line[i + 1];

      final px = (p.longitude - a.longitude) * k * cosLat;
      final py = (p.latitude - a.latitude) * k;
      final bx = (b.longitude - a.longitude) * k * cosLat;
      final by = (b.latitude - a.latitude) * k;

      final len2 = bx * bx + by * by;
      final double t = len2 > 0
          ? ((px * bx + py * by) / len2).clamp(0.0, 1.0).toDouble()
          : 0.0;

      final dx = px - t * bx;
      final dy = py - t * by;
      final d = math.sqrt(dx * dx + dy * dy);

      if (d < best) best = d;
    }

    return best;
  }
}
