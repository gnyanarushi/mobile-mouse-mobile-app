import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

class GyroService {
  final _gyroController = StreamController<GyroscopeEvent>.broadcast();

  Stream<GyroscopeEvent> get gyroStream => _gyroController.stream;

  GyroService() {
    _startListening();
  }

  void _startListening() {
    gyroscopeEventStream().listen((event) {
      _gyroController.add(event);
    });
  }

  void dispose() {
    _gyroController.close();
  }
}
