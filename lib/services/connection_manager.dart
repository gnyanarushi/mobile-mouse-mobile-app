import '../models/connection_info.dart';
import 'tcp_service.dart';

/// Singleton to manage the active connection state across the app
class ConnectionManager {
  static final ConnectionManager _instance = ConnectionManager._internal();
  factory ConnectionManager() => _instance;
  ConnectionManager._internal();

  TcpService? _activeTcpService;
  ConnectionInfo? _activeConnection;

  /// Get the currently active TCP service
  TcpService? get activeTcpService => _activeTcpService;

  /// Get the currently active connection info
  ConnectionInfo? get activeConnection => _activeConnection;

  /// Check if there's an active connection
  bool get hasActiveConnection =>
      _activeTcpService != null &&
      _activeTcpService!.isConnected &&
      _activeConnection != null;

  /// Set the active connection
  void setActiveConnection(TcpService tcpService, ConnectionInfo connection) {
    _activeTcpService = tcpService;
    _activeConnection = connection;
  }

  /// Clear the active connection
  void clearActiveConnection() {
    _activeTcpService?.disconnect();
    _activeTcpService = null;
    _activeConnection = null;
  }
}
