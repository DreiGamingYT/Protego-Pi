import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/telemetry.dart';

class ApiService {
  static const String baseUrl = 'https://surveillance-robot.onrender.com';

  // Send telemetry data
  static Future<bool> sendTelemetry(String robotId, Telemetry telemetry) async {
    final url = Uri.parse('$baseUrl/telemetry');
    final response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'robotId': robotId,
          'payload': telemetry.toJson(),
        }));
    return response.statusCode == 200;
  }

  // Send robot command
  static Future<bool> sendCommand(String robotId, Map<String, dynamic> command) async {
    final url = Uri.parse('$baseUrl/telemetry');
    final response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'robotId': robotId, 'command': command}));
    return response.statusCode == 200;
  }
}
