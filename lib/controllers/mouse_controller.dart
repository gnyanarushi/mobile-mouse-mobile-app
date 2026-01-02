import 'dart:convert';

import '../services/tcp_service.dart';

/// Manages mouse/cursor control and screen streaming commands
class MouseController {
  final TcpService tcpService;

  MouseController(this.tcpService);

  /// Send cursor movement based on gyro or touch delta values
  void sendMovement(double deltaX, double deltaY) {
    final payload = _basePayload(gyroX: deltaX, gyroY: deltaY);
    tcpService.send(jsonEncode(payload));
  }

  /// Send left mouse button click
  void sendLeftClick() {
    final payload = _basePayload(leftClick: true);
    tcpService.send(jsonEncode(payload));
  }

  /// Send right mouse button click
  void sendRightClick() {
    final payload = _basePayload(rightClick: true);
    tcpService.send(jsonEncode(payload));
  }

  /// Start UDP screen streaming from the desktop
  /// - [port]: UDP port to receive screen frames
  /// - [fps]: frames per second (default: 12)
  /// - [maxWidth]: maximum frame width in pixels (default: 1280)
  /// - [quality]: JPEG quality 0.0-1.0 (default: 0.7)
  void startScreenStream({
    required int port,
    int fps = 12,
    int maxWidth = 1280,
    double quality = 0.7,
  }) {
    final payload = {
      'stream': {
        'cmd': 'start',
        'port': port,
        'fps': fps,
        'maxWidth': maxWidth,
        'quality': quality,
      },
    };
    tcpService.send(jsonEncode(payload));
  }

  /// Stop UDP screen streaming
  void stopScreenStream() {
    final payload = {
      'stream': {'cmd': 'stop'},
    };
    tcpService.send(jsonEncode(payload));
  }

  /// Start WebSocket screen streaming from the desktop
  /// - [port]: WebSocket port to receive screen frames (e.g., 8080)
  /// - [fps]: frames per second (default: 12)
  /// - [maxWidth]: maximum frame width in pixels (default: 1280)
  /// - [quality]: JPEG quality 0.0-1.0 (default: 0.7)
  void startWebSocketStream({
    required int port,
    int fps = 12,
    int maxWidth = 1280,
    double quality = 0.7,
  }) {
    final payload = {
      'websocket': {
        'cmd': 'start',
        'port': port,
        'fps': fps,
        'maxWidth': maxWidth,
        'quality': quality,
      },
    };
    tcpService.send(jsonEncode(payload));
  }

  /// Stop WebSocket screen streaming
  void stopWebSocketStream() {
    final payload = {
      'websocket': {'cmd': 'stop'},
    };
    tcpService.send(jsonEncode(payload));
  }

  Map<String, dynamic> _basePayload({
    double gyroX = 0,
    double gyroY = 0,
    bool leftClick = false,
    bool rightClick = false,
  }) {
    return {
      'gyroX': gyroX,
      'gyroY': gyroY,
      'leftClick': leftClick,
      'rightClick': rightClick,
    };
  }
}
