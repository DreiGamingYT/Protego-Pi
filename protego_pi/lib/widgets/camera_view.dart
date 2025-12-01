// lib/widgets/camera_view.dart
import 'package:flutter/material.dart';
import 'mjpeg_stream.dart'; // ensure this file exists (the pure-Dart MJPEG widget you added earlier)

class CameraView extends StatelessWidget {
  final String streamUrl;
  final double height;
  const CameraView({required this.streamUrl, this.height = 240, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: MjpegStream(url: streamUrl, height: height, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
