import 'dart:async';
import 'dart:convert';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/tcp_service.dart';

class MouseController {
  final TcpService tcpService;
  StreamSubscription? _gyroSub;

  MouseController(this.tcpService);

  void startSendingGyro() {
    _gyroSub = gyroscopeEvents.listen((event) {
      final data = {
        "gyroX": event.x,
        "gyroY": event.y,
        "leftClick": false,
        "rightClick": false
      };

      tcpService.send(jsonEncode(data));
    });
  }

  void sendLeftClick() {
    final data = {
      "gyroX": 0,
      "gyroY": 0,
      "leftClick": true,
      "rightClick": false
    };
    tcpService.send(jsonEncode(data));
  }

  void sendRightClick() {
    final data = {
      "gyroX": 0,
      "gyroY": 0,
      "leftClick": false,
      "rightClick": true
    };
    tcpService.send(jsonEncode(data));
  }

  void stop() {
    _gyroSub?.cancel();
  }
}
