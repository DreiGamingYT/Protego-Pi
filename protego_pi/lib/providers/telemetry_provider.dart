// lib/providers/telemetry_provider.dart
import 'package:flutter/material.dart';
import '../models/telemetry.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class TelemetryPoint {
  final int? id;
  final String robotId;
  final Telemetry telemetry;
  final String createdAt;

  TelemetryPoint({this.id, required this.robotId, required this.telemetry, required this.createdAt});
}

class TelemetryProvider extends ChangeNotifier {
  // latest single telemetry (for top-line display)
  Telemetry? telemetry;

  // list of telemetry points (most recent first)
  final List<TelemetryPoint> points = [];

  // initialize socket connection and handler
  void startRealtime(String serverUrl) {
    SocketService.connect(serverUrl, (data) {
      try {
        // The server emits an object with keys: id, robotId, payload, created_at
        final id = (data is Map && data['id'] != null) ? (data['id'] as int?) : null;
        final robotId = (data is Map && data['robotId'] != null) ? data['robotId'].toString() : 'unknown';
        final createdAt = (data is Map && data['created_at'] != null) ? data['created_at'].toString() : DateTime.now().toIso8601String();
        dynamic payload = (data is Map && data['payload'] != null) ? data['payload'] : data;

        // Defensive: sometimes payload may be a JSON string; Telemetry.fromPayload handles that
        final Telemetry t = Telemetry.fromPayload(payload);

        final point = TelemetryPoint(id: id, robotId: robotId, telemetry: t, createdAt: createdAt);

        // insert at beginning
        points.insert(0, point);

        // keep latest snapshot too (for top card)
        telemetry = t;

        // cap length to avoid memory growth
        if (points.length > 500) points.removeRange(500, points.length);

        notifyListeners();
      } catch (e) {
        debugPrint('realtime parse error $e');
      }
    });
  }

  void stopRealtime() {
    SocketService.disconnect();
  }

  // manual send telemetry via REST (fallback)
  Future<void> updateTelemetry(String robotId, Telemetry newTelemetry) async {
    final success = await ApiService.sendTelemetry(robotId, newTelemetry);
    if (success) {
      telemetry = newTelemetry;
      points.insert(0, TelemetryPoint(id: null, robotId: robotId, telemetry: newTelemetry, createdAt: DateTime.now().toIso8601String()));
      notifyListeners();
    }
  }

  Future<void> sendCommand(String robotId, Map<String, dynamic> command) async {
    await ApiService.sendCommand(robotId, command);
  }
}
