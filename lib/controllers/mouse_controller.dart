import 'dart:convert';

import '../services/tcp_service.dart';

class MouseController {
  final TcpService tcpService;

  MouseController(this.tcpService);

  void sendMovement(double deltaX, double deltaY) {
    final payload = _basePayload(gyroX: deltaX, gyroY: deltaY);
    tcpService.send(jsonEncode(payload));
  }

  void sendLeftClick() {
    final payload = _basePayload(leftClick: true);
    tcpService.send(jsonEncode(payload));
  }

  void sendRightClick() {
    final payload = _basePayload(rightClick: true);
    tcpService.send(jsonEncode(payload));
  }

  Map<String, dynamic> _basePayload({
    double gyroX = 0,
    double gyroY = 0,
    bool leftClick = false,
    bool rightClick = false,
  }) {
    // Desktop listener expects legacy gyro field names for compatibility
    // with existing Java service; update both ends if this schema changes.
    return {
      'gyroX': gyroX,
      'gyroY': gyroY,
      'leftClick': leftClick,
      'rightClick': rightClick,
    };
  }
}
