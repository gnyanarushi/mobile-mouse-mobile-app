import 'dart:async';

import 'package:flutter/material.dart';

import '../models/connection_info.dart';
import '../services/connection_manager.dart';
import '../services/connection_storage.dart';
import '../services/tcp_service.dart';
import 'control_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _storage = ConnectionStorage();
  final _hostController = TextEditingController();
  final _tcpPortController = TextEditingController(text: '5000');
  final _udpPortController = TextEditingController(text: '6000');
  final _nicknameController = TextEditingController();

  List<ConnectionInfo> _savedConnections = [];
  bool _isConnecting = false;
  bool _showNewConnectionForm = false;

  @override
  void initState() {
    super.initState();
    _loadConnections();
    _checkExistingConnection();
  }

  void _checkExistingConnection() {
    // Check if there's an active connection and navigate to control screen
    final manager = ConnectionManager();
    if (manager.hasActiveConnection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ControlScreen(
                tcpService: manager.activeTcpService!,
                connection: manager.activeConnection!,
              ),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _tcpPortController.dispose();
    _udpPortController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadConnections() async {
    final connections = await _storage.getConnections();
    setState(() {
      _savedConnections = connections;
    });
  }

  Future<void> _connectToDesktop(ConnectionInfo connection) async {
    setState(() => _isConnecting = true);

    try {
      final tcp = TcpService();
      final success = await tcp.connect(
        connection.host,
        connection.tcpPort,
        timeout: const Duration(seconds: 5),
      );

      if (!mounted) return;

      if (success) {
        // Update last used time and save
        final updatedConnection = connection.copyWith(lastUsed: DateTime.now());
        await _storage.saveConnection(updatedConnection);

        // Navigate to control screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                ControlScreen(tcpService: tcp, connection: updatedConnection),
          ),
        );
      } else {
        _showError('Connection failed. Check IP and port.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Connection error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Future<void> _connectWithNewConnection() async {
    final host = _hostController.text.trim();
    final tcpPort = int.tryParse(_tcpPortController.text.trim()) ?? 5000;
    final udpPort = int.tryParse(_udpPortController.text.trim()) ?? 6000;
    final nickname = _nicknameController.text.trim().isEmpty
        ? host
        : _nicknameController.text.trim();

    if (host.isEmpty) {
      _showError('Please enter a host IP address');
      return;
    }

    final connection = ConnectionInfo(
      host: host,
      tcpPort: tcpPort,
      udpPort: udpPort,
      nickname: nickname,
      lastUsed: DateTime.now(),
    );

    await _connectToDesktop(connection);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _deleteConnection(ConnectionInfo connection) async {
    await _storage.deleteConnection(connection);
    await _loadConnections();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${connection.nickname} deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Image.asset(
                        'assets/icon/icon.png',
                        height: 80,
                        width: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Mobile Mouse',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Connect to your desktop',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: _isConnecting
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                'Connecting...',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // New Connection Button
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _showNewConnectionForm =
                                        !_showNewConnectionForm;
                                  });
                                },
                                icon: Icon(
                                  _showNewConnectionForm
                                      ? Icons.close
                                      : Icons.add,
                                ),
                                label: Text(
                                  _showNewConnectionForm
                                      ? 'Cancel'
                                      : 'New Connection',
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                ),
                              ),

                              // New Connection Form
                              if (_showNewConnectionForm) ...[
                                const SizedBox(height: 16),
                                Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'New Connection',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller: _nicknameController,
                                          decoration: const InputDecoration(
                                            labelText: 'Nickname (optional)',
                                            prefixIcon: Icon(Icons.label),
                                            hintText: 'My Desktop',
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: _hostController,
                                          decoration: const InputDecoration(
                                            labelText: 'Desktop IP',
                                            prefixIcon: Icon(Icons.computer),
                                            hintText: '192.168.1.100',
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: _tcpPortController,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'TCP Port',
                                                      prefixIcon: Icon(
                                                        Icons
                                                            .settings_input_hdmi,
                                                      ),
                                                    ),
                                                keyboardType:
                                                    TextInputType.number,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: TextField(
                                                controller: _udpPortController,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'UDP Port',
                                                      prefixIcon: Icon(
                                                        Icons.router,
                                                      ),
                                                    ),
                                                keyboardType:
                                                    TextInputType.number,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: _connectWithNewConnection,
                                          child: const Text('Connect'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],

                              // Saved Connections
                              if (_savedConnections.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                Text(
                                  'Recent Connections',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                ..._savedConnections.map((connection) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Card(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: InkWell(
                                        onTap: () =>
                                            _connectToDesktop(connection),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.primary
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  Icons.computer,
                                                  color: colorScheme.primary,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      connection.nickname,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${connection.host}:${connection.tcpPort}',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                ),
                                                color: Colors.red.shade400,
                                                onPressed: () =>
                                                    _deleteConnection(
                                                      connection,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ] else if (!_showNewConnectionForm) ...[
                                const SizedBox(height: 48),
                                Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.history,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No saved connections',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap "New Connection" to get started',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
