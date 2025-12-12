import 'dart:convert';
import 'dart:io';

class TcpService {
  Socket? _socket;

  Future<bool> connect(String host, int port) async {
    try {
      _socket = await Socket.connect(host, port);
      print("Connected to Java server");
      return true;
    } catch (e) {
      print("Connection failed: $e");
      return false;
    }
  }

  void send(String jsonData) {
    if (_socket != null) {
      _socket!.write(jsonData + "\n");
    }
  }

  void disconnect() {
    _socket?.close();
  }
}
