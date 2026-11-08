import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/trajet_reel_model.dart';

/// Construit les couches de tracés pour [SiraMap.extraLayers].
/// - prévu : itinéraire routier calculé par OSRM (/route)
/// - trace : positions parcourues localement (app chauffeur, temps réel)
/// - reel  : trajet recalé sur les routes (OSRM /match), repli sur les points GPS bruts
class RouteLayers {
  static const Color prevuColor = Color(0xFF2A9D8F);
  static const Color reelColor = Color(0xFF1D4ED8);

  static List<Widget> build({
    List<LatLng> prevu = const [],
    List<LatLng> trace = const [],
    TrajetReel? reel,
    bool showPrevu = true,
    bool showReel = true,
  }) {
    final polylines = <Polyline>[];

    if (showPrevu && prevu.length >= 2) {
      polylines.add(Polyline(
        points: prevu,
        strokeWidth: 6,
        color: prevuColor.withValues(alpha: 0.85),
        borderColor: Colors.white,
        borderStrokeWidth: 1.5,
      ));
    }

    if (showReel && reel != null) {
      if (reel.segments.isNotEmpty) {
        for (final segment in reel.segments) {
          polylines.add(Polyline(
            points: segment,
            strokeWidth: 4,
            color: reelColor,
          ));
        }
      } else if (reel.positionsBrutes.length >= 2) {
        // Repli : recalage impossible (piste minière hors réseau OSM).
        polylines.add(Polyline(
          points: reel.positionsBrutes,
          strokeWidth: 3,
          color: reelColor.withValues(alpha: 0.7),
        ));
      }
    }

    if (trace.length >= 2) {
      // Copie : flutter_map ne repeint pas une liste mutée en place.
      polylines.add(Polyline(
        points: List<LatLng>.of(trace),
        strokeWidth: 4,
        color: reelColor,
      ));
    }

    return polylines.isEmpty ? const [] : [PolylineLayer(polylines: polylines)];
  }
}
