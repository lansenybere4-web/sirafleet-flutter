import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// Publie la position GPS du téléphone sur le broker MQTT.
/// Topic : {prefix}/camions/{matricule}/position
/// JSON  : {"lat":..., "lon":..., "v":..., "src":"gps"}
/// (format attendu par la commande Laravel `php artisan mqtt:ecouter`)
class PositionMqttService {
  static const String broker = 'broker.hivemq.com';
  static const int port = 1883;

  // Doit être identique à MQTT_PREFIX dans le .env de Laravel.
  static const String prefix = 'sirafleet_lanseny_2026';

  MqttServerClient? _client;
  bool _connecting = false;

  bool get _connected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<void> _connecter() async {
    if (_connected || _connecting) return;
    _connecting = true;

    try {
      _client = MqttServerClient(
        broker,
        'sirafleet_app_${DateTime.now().millisecondsSinceEpoch}',
      )
        ..port = port
        ..keepAlivePeriod = 30
        ..autoReconnect = true
        ..logging(on: false);

      await _client!.connect();
    } catch (e) {
      debugPrint('MQTT connexion impossible : $e');
      _client?.disconnect();
      _client = null;
    } finally {
      _connecting = false;
    }
  }

  Future<void> publier(String matricule, Position p) async {
    try {
      await _connecter();
      if (!_connected) return;

      final String payload = jsonEncode({
        'lat': p.latitude,
        'lon': p.longitude,
        'v': p.speed > 0 ? p.speed * 3.6 : 0.0, // km/h
        'src': 'gps',
      });

      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder()
        ..addString(payload);

      _client!.publishMessage(
        '$prefix/camions/$matricule/position',
        MqttQos.atLeastOnce,
        builder.payload!,
      );
    } catch (e) {
      debugPrint('MQTT publication impossible : $e');
    }
  }

  void arreter() {
    _client?.disconnect();
    _client = null;
  }
}
