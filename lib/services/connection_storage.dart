import 'dart:convert';
import 'dart:developer' as dev;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/connection_info.dart';

/// Service for storing and retrieving connection history
class ConnectionStorage {
  static const String _connectionsKey = 'saved_connections';
  static const int _maxConnections = 10;

  /// Get all saved connections
  Future<List<ConnectionInfo>> getConnections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_connectionsKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final connections = jsonList
          .map((json) => ConnectionInfo.fromJson(json as Map<String, dynamic>))
          .toList();

      // Sort by last used (most recent first)
      connections.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
      
      return connections;
    } catch (e) {
      dev.log('Error loading connections: $e');
      return [];
    }
  }

  /// Save a new connection or update existing one
  Future<void> saveConnection(ConnectionInfo connection) async {
    try {
      final connections = await getConnections();
      
      // Remove duplicate if exists (same host and ports)
      connections.removeWhere((c) =>
          c.host == connection.host &&
          c.tcpPort == connection.tcpPort &&
          c.udpPort == connection.udpPort);

      // Add new connection at the beginning
      connections.insert(0, connection);

      // Keep only the most recent connections
      if (connections.length > _maxConnections) {
        connections.removeRange(_maxConnections, connections.length);
      }

      // Save to storage
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(connections.map((c) => c.toJson()).toList());
      await prefs.setString(_connectionsKey, jsonString);
      
      dev.log('Connection saved: ${connection.nickname}');
    } catch (e) {
      dev.log('Error saving connection: $e');
    }
  }

  /// Delete a specific connection
  Future<void> deleteConnection(ConnectionInfo connection) async {
    try {
      final connections = await getConnections();
      
      connections.removeWhere((c) =>
          c.host == connection.host &&
          c.tcpPort == connection.tcpPort &&
          c.udpPort == connection.udpPort);

      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(connections.map((c) => c.toJson()).toList());
      await prefs.setString(_connectionsKey, jsonString);
      
      dev.log('Connection deleted: ${connection.nickname}');
    } catch (e) {
      dev.log('Error deleting connection: $e');
    }
  }

  /// Clear all saved connections
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_connectionsKey);
      dev.log('All connections cleared');
    } catch (e) {
      dev.log('Error clearing connections: $e');
    }
  }

  /// Get the most recently used connection
  Future<ConnectionInfo?> getLastConnection() async {
    final connections = await getConnections();
    return connections.isNotEmpty ? connections.first : null;
  }
}
