import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

/// Enhanced TCP service for desktop control connection.
/// Manages line-delimited JSON communication with the server.
class TcpService {
  Socket? _socket;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<ConnectionStatus>.broadcast();

  /// Stream of parsed JSON messages received from the server
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// Stream of connection status changes
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  bool get isConnected => _socket != null;

  /// Connect to the desktop server
  Future<bool> connect(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_socket != null) {
      log('Already connected');
      return false;
    }

    try {
      _statusController.add(ConnectionStatus.connecting);
      _socket = await Socket.connect(host, port, timeout: timeout);
      log('Connected to server at $host:$port');

      // Listen for incoming data
      _socket!.listen(
        _onData,
        onDone: () {
          log('TCP connection closed');
          _statusController.add(ConnectionStatus.disconnected);
          _cleanup();
        },
        onError: (error) {
          log('TCP error: $error');
          _statusController.add(ConnectionStatus.error);
          _cleanup();
        },
      );

      _statusController.add(ConnectionStatus.connected);
      return true;
    } catch (e) {
      log('Connection failed: $e');
      _statusController.add(ConnectionStatus.error);
      _cleanup();
      return false;
    }
  }

  void _onData(List<int> data) {
    try {
      final message = utf8.decode(data).trim();
      if (message.isNotEmpty) {
        log('Received from server: $message');
        try {
          final json = jsonDecode(message) as Map<String, dynamic>;
          _messageController.add(json);
        } catch (e) {
          log('Failed to parse JSON: $e');
        }
      }
    } catch (e) {
      log('Failed to decode message: $e');
    }
  }

  /// Send a JSON message (automatically appends newline)
  void send(String jsonData) {
    if (_socket != null) {
      log('Sending: $jsonData');
      _socket!.write(jsonData + '\n');
    } else {
      log('Cannot send - not connected');
    }
  }

  /// Send a JSON object (automatically encodes and appends newline)
  void sendJson(Map<String, dynamic> json) {
    send(jsonEncode(json));
  }

  void _cleanup() {
    _socket = null;
  }

  /// Disconnect from the server
  void disconnect() {
    if (_socket != null) {
      _socket!.destroy();
      _socket = null;
      _statusController.add(ConnectionStatus.disconnected);
      log('Disconnected from server');
    }
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _statusController.close();
  }
}

enum ConnectionStatus { disconnected, connecting, connected, error }
