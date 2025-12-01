// lib/models/telemetry.dart
import 'dart:convert';

class Telemetry {
  // legacy simple fields
  final double? temp;
  final double? distance;

  // lidar-specific
  final int? points; // number of points in a scan (e.g. 687)
  final double? scanTime; // seconds (e.g. 0.177)
  final List<double?>? rangesSampled; // sampled ranges (null = inf / no reading)
  final String? rawLine; // raw log line if present
  final Map<String, dynamic>? rawPayload; // keep original for debugging

  Telemetry({
    this.temp,
    this.distance,
    this.points,
    this.scanTime,
    this.rangesSampled,
    this.rawLine,
    this.rawPayload,
  });

  // Factory that understands several payload shapes
  factory Telemetry.fromPayload(dynamic payload) {
    if (payload == null) return Telemetry();

    // If payload is a JSON string, try decoding
    if (payload is String) {
      try {
        final dynamic parsed = payload.isNotEmpty ? jsonDecode(payload) : null;
        if (parsed != null) return Telemetry.fromPayload(parsed);
      } catch (_) {
        // leave as rawLine fallback
        return Telemetry(rawLine: payload, rawPayload: {'_raw': payload});
      }
    }

    if (payload is Map<String, dynamic>) {
      // legacy numeric temp/distance
      if (payload.containsKey('temp') && payload.containsKey('distance')) {
        double? t, d;
        try {
          t = (payload['temp'] as num?)?.toDouble();
        } catch (_) {}
        try {
          d = (payload['distance'] as num?)?.toDouble();
        } catch (_) {}
        return Telemetry(temp: t, distance: d, rawPayload: payload);
      }

      // tof_stdout_bridge style: points, scan_time_s, raw_line
      if (payload.containsKey('points') || payload.containsKey('scan_time_s') || payload.containsKey('raw_line')) {
        int? pts;
        double? st;
        try {
          pts = (payload['points'] is num) ? (payload['points'] as num).toInt() : int.tryParse(payload['points']?.toString() ?? '');
        } catch (_) {}
        try {
          st = (payload['scan_time_s'] is num) ? (payload['scan_time_s'] as num).toDouble() : double.tryParse(payload['scan_time_s']?.toString() ?? '');
        } catch (_) {}
        return Telemetry(points: pts, scanTime: st, rawLine: payload['raw_line']?.toString(), rawPayload: payload);
      }

      // ros2_lidar_bridge_socketio style: ranges_sampled, angle_min, ...
      if (payload.containsKey('ranges_sampled')) {
        List<dynamic>? arr = payload['ranges_sampled'] as List<dynamic>?;
        List<double?> sampled = [];
        if (arr != null) {
          for (var v in arr) {
            if (v == null) sampled.add(null);
            else {
              try {
                sampled.add((v as num).toDouble());
              } catch (_) {
                final dv = double.tryParse(v.toString());
                sampled.add(dv);
              }
            }
          }
        }
        // compute a simple average (ignore nulls)
        double? avg;
        final nonNull = sampled.where((e) => e != null).map((e) => e!).toList();
        if (nonNull.isNotEmpty) {
          avg = nonNull.reduce((a, b) => a + b) / nonNull.length;
        }
        return Telemetry(
          rangesSampled: sampled,
          points: sampled.length,
          distance: avg,
          scanTime: (payload['scan_time'] is num) ? (payload['scan_time'] as num).toDouble() : (payload['scan_time_s'] is num ? (payload['scan_time_s'] as num).toDouble() : null),
          rawPayload: payload,
        );
      }

      // fallback - keep payload available
      return Telemetry(rawPayload: payload);
    }

    // unknown type
    return Telemetry(rawPayload: {'_value': payload});
  }

  // Convert back to JSON for API senders (used by ApiService)
  Map<String, dynamic> toJson() {
    // Prefer rich lidar fields if present
    if (rangesSampled != null) {
      return {
        'ranges_sampled': rangesSampled,
        if (angleMeta != null) ...angleMeta!, // angleMeta helper below
        'points': points,
        'scan_time_s': scanTime,
      }..removeWhere((k, v) => v == null);
    }

    if (points != null || scanTime != null || rawLine != null) {
      return {
        'points': points,
        'scan_time_s': scanTime,
        'raw_line': rawLine,
      }..removeWhere((k, v) => v == null);
    }

    // fallback to temp/distance or raw payload
    if (temp != null || distance != null) {
      return {
        'temp': temp,
        'distance': distance,
      }..removeWhere((k, v) => v == null);
    }

    if (rawPayload != null) return rawPayload!;

    return {};
  }

  // Optional helper to include angle metadata if present in rawPayload
  Map<String, dynamic>? get angleMeta {
    if (rawPayload == null) return null;
    final keys = ['angle_min', 'angle_increment', 'range_max', 'range_min'];
    final meta = <String, dynamic>{};
    for (var k in keys) {
      if (rawPayload!.containsKey(k)) meta[k] = rawPayload![k];
    }
    return meta.isNotEmpty ? meta : null;
  }

  // Useful text summary for UI
  String summary() {
    if (points != null) {
      final st = (scanTime != null) ? ' is ${scanTime!.toStringAsFixed(3)}s' : '';
      return 'Scan: $points points$st';
    }
    if (temp != null || distance != null) {
      final t = temp != null ? '${temp!.toStringAsFixed(2)} °C' : '--';
      final d = distance != null ? '${distance!.toStringAsFixed(2)} cm' : '--';
      return 'Temp: $t — Dist: $d';
    }
    if (rawLine != null) return rawLine!;
    if (rawPayload != null) return rawPayload.toString();
    return 'No data';
  }
}
