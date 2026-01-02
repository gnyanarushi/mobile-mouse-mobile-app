import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';

/// Manages WebSocket connection for receiving JPEG screen frames from the desktop server.
/// Each WebSocket message contains a complete JPEG image as binary data.
class WebSocketService {
  WebSocket? _socket;
  final _frameController = StreamController<Uint8List>.broadcast();
  final _statusController = StreamController<WebSocketStatus>.broadcast();

  /// Stream of complete JPEG frames (ready to decode and display)
  Stream<Uint8List> get frameStream => _frameController.stream;

  /// Stream of connection status changes
  Stream<WebSocketStatus> get statusStream => _statusController.stream;

  bool get isConnected => _socket != null;

  /// Connect to the WebSocket server on the desktop
  /// URL format: ws://192.168.1.42:8080
  Future<bool> connect(String url) async {
    if (_socket != null) {
      dev.log('WebSocket already connected');
      return false;
    }

    try {
      _statusController.add(WebSocketStatus.connecting);
      dev.log('Connecting to WebSocket: $url');

      _socket = await WebSocket.connect(url);
      dev.log('WebSocket connected to $url');

      _socket!.listen(
        _onData,
        onDone: () {
          dev.log('WebSocket connection closed');
          _statusController.add(WebSocketStatus.disconnected);
          _cleanup();
        },
        onError: (error) {
          dev.log('WebSocket error: $error');
          _statusController.add(WebSocketStatus.error);
          _cleanup();
        },
      );

      _statusController.add(WebSocketStatus.connected);
      return true;
    } catch (e) {
      dev.log('WebSocket connection failed: $e');
      _statusController.add(WebSocketStatus.error);
      _cleanup();
      return false;
    }
  }

  void _onData(dynamic data) {
    try {
      if (data is List<int>) {
        // Binary message containing JPEG frame
        final frame = Uint8List.fromList(data);
        _frameController.add(frame);
      } else {
        dev.log('Received non-binary WebSocket message: ${data.runtimeType}');
      }
    } catch (e) {
      dev.log('Failed to process WebSocket frame: $e');
    }
  }

  void _cleanup() {
    _socket = null;
  }

  /// Disconnect from the WebSocket server
  void disconnect() {
    if (_socket != null) {
      try {
        _socket!.close();
      } catch (e) {
        dev.log('Error closing WebSocket: $e');
      }
      _socket = null;
      _statusController.add(WebSocketStatus.disconnected);
      dev.log('WebSocket disconnected');
    }
  }

  void dispose() {
    disconnect();
    _frameController.close();
    _statusController.close();
  }
}

enum WebSocketStatus { disconnected, connecting, connected, error }
