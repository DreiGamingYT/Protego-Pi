// lib/services/socket_service.dart
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static IO.Socket? _socket;

  static void connect(String serverUrl, Function(dynamic) onTelemetry) {
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket!.on('connect', (_) {
      print('socket connected: ${_socket!.id}');
    });

    _socket!.on('telemetry', (data) {
      print('socket telemetry: $data');
      onTelemetry(data);
    });

    // optional: if Pi emits telemetry via 'telemetry_from_pi' server will broadcast 'telemetry'
    _socket!.on('disconnect', (_) => print('socket disconnected'));
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
