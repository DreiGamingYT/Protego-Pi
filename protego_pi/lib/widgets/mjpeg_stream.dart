// lib/widgets/mjpeg_stream.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Simple MJPEG stream viewer - no external dependencies.
/// Usage:
///   MjpegStream(url: 'http://<pi-ip>:8080/?action=stream')
class MjpegStream extends StatefulWidget {
  final String url;
  final double height;
  final BoxFit fit;
  const MjpegStream({
    required this.url,
    this.height = 240,
    this.fit = BoxFit.contain,
    super.key,
  });

  @override
  State<MjpegStream> createState() => _MjpegStreamState();
}

class _MjpegStreamState extends State<MjpegStream> {
  HttpClient? _client;
  HttpClientRequest? _request;
  HttpClientResponse? _response;
  final List<int> _buffer = <int>[];
  Uint8List? _currentFrame;
  StreamSubscription<List<int>>? _sub;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant MjpegStream oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _stop().then((_) => _start());
    }
  }

  Future<void> _start() async {
    _running = true;
    _client = HttpClient();
    try {
      final uri = Uri.parse(widget.url);
      _request = await _client!.getUrl(uri);
      // you can set timeouts or headers here if necessary
      _response = await _request!.close();
      _sub = _response!.listen(_onData, onDone: _onDone, onError: _onError, cancelOnError: true);
    } catch (e) {
      // ignore connection errors - show nothing
      debugPrint('MJPEG: connection error: $e');
      _cleanup();
    }
  }

  void _onData(List<int> chunk) {
    if (!_running) return;
    _buffer.addAll(chunk);
    _processBuffer();
  }

  void _processBuffer() {
    // Find JPEG SOI (0xFF 0xD8) and EOI (0xFF 0xD9)
    while (true) {
      final int start = _indexOf(_buffer, [0xFF, 0xD8], 0);
      if (start < 0) {
        // no start yet
        if (_buffer.length > 1024 * 1024) {
          // prevent unbounded buffer (drop old data)
          _buffer.removeRange(0, _buffer.length - 1024 * 512);
        }
        break;
      }
      final int end = _indexOf(_buffer, [0xFF, 0xD9], start + 2);
      if (end < 0) {
        // wait for more data
        break;
      }
      final int eoi = end + 2; // include EOI bytes
      final frameBytes = Uint8List.fromList(_buffer.sublist(start, eoi));
      // remove consumed bytes
      _buffer.removeRange(0, eoi);
      // update frame
      setState(() {
        _currentFrame = frameBytes;
      });
      // continue loop in case multiple frames buffered
    }
  }

  static int _indexOf(List<int> data, List<int> pattern, int start) {
    final int dlen = data.length;
    final int plen = pattern.length;
    if (plen == 0 || dlen < plen) return -1;
    for (int i = start; i <= dlen - plen; i++) {
      bool ok = true;
      for (int j = 0; j < plen; j++) {
        if (data[i + j] != pattern[j]) {
          ok = false;
          break;
        }
      }
      if (ok) return i;
    }
    return -1;
  }

  void _onDone() {
    debugPrint('MJPEG: stream done');
    _cleanup();
    // try reconnect after short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _start();
    });
  }

  void _onError(Object e) {
    debugPrint('MJPEG: stream error: $e');
    _cleanup();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _start();
    });
  }

  Future<void> _stop() async {
    _running = false;
    try {
      await _sub?.cancel();
    } catch (_) {}
    _cleanup();
  }

  void _cleanup() {
    try {
      _response = null;
      _request = null;
      _sub = null;
      _client?.close(force: true);
    } catch (_) {}
    _client = null;
  }

  @override
  void dispose() {
    _running = false;
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: _currentFrame == null
            ? const Center(child: CircularProgressIndicator())
            : Image.memory(
          _currentFrame!,
          gaplessPlayback: true,
          fit: widget.fit,
          width: double.infinity,
        ),
      ),
    );
  }
}
