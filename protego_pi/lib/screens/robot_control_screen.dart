import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/telemetry_provider.dart';

class RobotControlScreen extends StatelessWidget {
  const RobotControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TelemetryProvider>();
    const robotId = 'pi-001';

    return Scaffold(
      appBar: AppBar(title: const Text('Robot Control')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => provider.sendCommand(robotId, {'action': 'forward', 'speed': 0.4}),
              child: const Text('Move Forward'),
            ),
            ElevatedButton(
              onPressed: () => provider.sendCommand(robotId, {'action': 'backward', 'speed': 0.4}),
              child: const Text('Move Backward'),
            ),
            ElevatedButton(
              onPressed: () => provider.sendCommand(robotId, {'action': 'stop'}),
              child: const Text('Stop'),
            ),
          ],
        ),
      ),
    );
  }
}
