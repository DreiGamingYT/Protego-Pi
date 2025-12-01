// lib/widgets/camera_overlay.dart
import 'package:flutter/material.dart';

class Detection {
  final double x, y, w, h;
  final bool normalized;
  final String label;
  Detection({required this.x, required this.y, required this.w, required this.h, this.normalized = true, this.label = ''});
}

class CameraOverlay extends StatelessWidget {
  final Widget camera;
  final List<Detection> detections;
  // If detections are normalized (0..1), set cameraWidth=1 and cameraHeight=1
  final double cameraWidth;
  final double cameraHeight;
  const CameraOverlay({
    required this.camera,
    required this.detections,
    required this.cameraWidth,
    required this.cameraHeight,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final scaleX = constraints.maxWidth / cameraWidth;
      final scaleY = constraints.maxHeight / cameraHeight;
      return Stack(
        children: [
          Positioned.fill(child: camera),
          Positioned.fill(
            child: CustomPaint(
              painter: _BoxPainter(
                detections.map((d) => _toLocalDetection(d)).toList(),
                scaleX,
                scaleY,
              ),
            ),
          ),
        ],
      );
    });
  }

  _LocalDetection _toLocalDetection(Detection d) {
    if (d.normalized) {
      return _LocalDetection(d.x, d.y, d.w, d.h, d.label, true);
    } else {
      return _LocalDetection(d.x, d.y, d.w, d.h, d.label, false);
    }
  }
}

class _LocalDetection {
  final double x, y, w, h;
  final String label;
  final bool normalized;
  _LocalDetection(this.x, this.y, this.w, this.h, this.label, this.normalized);
}

class _BoxPainter extends CustomPainter {
  final List<_LocalDetection> det;
  final double sx, sy;
  _BoxPainter(this.det, this.sx, this.sy);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..color = Colors.red;
    final fill = Paint()..style = PaintingStyle.fill..color = Colors.red.withOpacity(0.12);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var d in det) {
      double left = d.normalized ? d.x * size.width : d.x * sx;
      double top = d.normalized ? d.y * size.height : d.y * sy;
      double w = d.normalized ? d.w * size.width : d.w * sx;
      double h = d.normalized ? d.h * size.height : d.h * sy;

      final rect = Rect.fromLTWH(left, top, w, h);
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, fill);

      if (d.label.isNotEmpty) {
        final span = TextSpan(text: d.label, style: const TextStyle(color: Colors.white, fontSize: 12));
        textPainter.text = span;
        textPainter.layout();
        final tpOffset = Offset(left + 4, top - textPainter.height - 4);
        // background for text
        final bgRect = Rect.fromLTWH(tpOffset.dx - 2, tpOffset.dy - 2, textPainter.width + 4, textPainter.height + 4);
        canvas.drawRect(bgRect, Paint()..color = Colors.black54);
        textPainter.paint(canvas, tpOffset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoxPainter old) => true;
}
