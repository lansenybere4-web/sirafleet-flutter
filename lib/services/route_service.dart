import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMin;

  RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMin,
  });

  /// Format prêt à envoyer au backend Laravel.
  List<Map<String, double>> toBackendFormat() {
    return points
        .map((p) => {'lat': p.latitude, 'lng': p.longitude})
        .toList();
  }
}

class RouteService {
  // Récupérée sur https://openrouteservice.org/dev/#/signup
  static const String _apiKey = String.fromEnvironment('ORS_API_KEY');

  static const Duration _timeout = Duration(seconds: 12);

  /// Calcule un itinéraire routier réel entre deux points.
  /// Lève une exception si l'API échoue (à toi de prévoir un fallback
  /// ligne droite côté appelant si besoin).
  Future<RouteResult> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final uri = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/driving-car',
    );

    final response = await http
        .post(
      uri,
      headers: {
        'Authorization': _apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        // ORS attend [longitude, latitude]
        'coordinates': [
          [origin.longitude, origin.latitude],
          [destination.longitude, destination.latitude],
        ],
      }),
    )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Impossible de calculer l\'itinéraire (${response.statusCode}).',
      );
    }

    final data = jsonDecode(response.body);

    final feature = data['features'][0];
    final coordinates = feature['geometry']['coordinates'] as List;
    final summary = feature['properties']['summary'];

    final points = coordinates
        .map<LatLng>((c) => LatLng(c[1] as double, (c[0] as num).toDouble()))
        .toList();

    return RouteResult(
      points: points,
      distanceKm: (summary['distance'] as num) / 1000.0,
      durationMin: ((summary['duration'] as num) / 60).round(),
    );
  }
}