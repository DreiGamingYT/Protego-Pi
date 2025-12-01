// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/telemetry_provider.dart';
import '../providers/auth_provider.dart';
import 'robot_control_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const socketUrl = 'https://surveillance-robot.onrender.com';

  @override
  void initState() {
    super.initState();
    final telProvider = Provider.of<TelemetryProvider>(context, listen: false);
    telProvider.startRealtime(socketUrl);
  }

  @override
  void dispose() {
    final telProvider = Provider.of<TelemetryProvider>(context, listen: false);
    telProvider.stopRealtime();
    super.dispose();
  }

  Widget _buildTelemetryTile(TelemetryPoint p) {
    final t = p.telemetry;
    final lines = <String>[];

    if (t.points != null) {
      final st = t.scanTime != null ? ' is ${t.scanTime!.toStringAsFixed(3)}s' : '';
      lines.add('Scan: ${t.points}$st');
    }

    if (t.rangesSampled != null && t.rangesSampled!.isNotEmpty) {
      final first = t.rangesSampled!.take(8).map((v) => v == null ? 'inf' : v.toString()).join(', ');
      lines.add('Ranges (first ${t.rangesSampled!.take(8).length}): $first');
    }

    if (t.temp != null || t.distance != null) {
      final temp = t.temp != null ? '${t.temp!.toStringAsFixed(2)} °C' : '--';
      final dist = t.distance != null ? '${t.distance!.toStringAsFixed(2)} cm' : '--';
      lines.add('Temp: $temp — Dist: $dist');
    }

    if (t.rawLine != null) lines.add('Raw: ${t.rawLine}');

    if (lines.isEmpty && t.rawPayload != null) lines.add('Payload: ${t.rawPayload}');

    return ListTile(
      title: Text(t.summary()),
      subtitle: Text(lines.join('\n')),
      isThreeLine: lines.length > 1,
      trailing: Text('${p.createdAt.split('T').first}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TelemetryProvider>();
    final auth = context.read<AuthProvider>();
    final points = provider.points;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Protego Pi Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          const SizedBox(height: 6),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                  child: Text(
                    provider.telemetry?.summary() ?? 'No telemetry yet',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RobotControlScreen())),
                  child: const Text('Control Robot'),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const Align(alignment: Alignment.centerLeft, child: Text('Telemetry data points (most recent):', style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          Expanded(
            child: points.isEmpty
                ? const Center(child: Text('No telemetry yet'))
                : ListView.builder(
              itemCount: points.length,
              itemBuilder: (ctx, i) {
                final p = points[i];
                return Card(child: _buildTelemetryTile(p));
              },
            ),
          ),
        ]),
      ),
    );
  }
}