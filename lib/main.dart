import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart' as sensors;

import 'controllers/mouse_controller.dart';
import 'services/tcp_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF2563EB);
    final colorScheme = ColorScheme.fromSeed(seedColor: seedColor);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: seedColor, width: 1.6),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: seedColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MouseControlScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white24),
                ),
                child: Image.asset(
                  'assets/icon/icon.png',
                  height: 120,
                  width: 120,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Mobile Mouse',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Turn your phone into a precise touchpad',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const SizedBox(
                height: 48,
                width: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MouseControlScreen extends StatefulWidget {
  const MouseControlScreen({super.key});

  @override
  State<MouseControlScreen> createState() => _MouseControlScreenState();
}

class _MouseControlScreenState extends State<MouseControlScreen> {
  final tcp = TcpService();
  late final MouseController mouseController;
  final TextEditingController _hostController = TextEditingController(
    text: '10.5.5.10',
  );
  final TextEditingController _portController = TextEditingController(
    text: '5000',
  );

  String status = 'Not connected';
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _gyroModeEnabled = false;
  StreamSubscription<sensors.GyroscopeEvent>? _gyroSub;

  @override
  void initState() {
    super.initState();
    mouseController = MouseController(tcp);
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    _hostController.dispose();
    _portController.dispose();
    tcp.disconnect();
    super.dispose();
  }

  Future<void> connectToPC() async {
    if (_isConnecting) return;
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 5000;

    setState(() {
      _isConnecting = true;
      status = 'Connecting to $host:$port...';
    });

    final ok = await tcp.connect(host, port);

    setState(() {
      _isConnecting = false;
      _isConnected = ok;
      status = ok
          ? 'Connected to $host:$port'
          : 'Connection failed for $host:$port';
    });

    if (!ok && _gyroModeEnabled) {
      _toggleGyroMode(false);
    }

    log(status);
  }

  void _handlePadUpdate(DragUpdateDetails details) {
    if (!_isConnected) return;
    mouseController.sendMovement(details.delta.dx, details.delta.dy);
  }

  void _handleLeftClick() {
    if (_isConnected) {
      mouseController.sendLeftClick();
    }
  }

  void _handleRightClick() {
    if (_isConnected) {
      mouseController.sendRightClick();
    }
  }

  void _toggleGyroMode(bool value) {
    if (value) {
      _gyroSub?.cancel();
      _gyroSub = sensors.gyroscopeEvents.listen((sensors.GyroscopeEvent event) {
        if (!_isConnected) return;
        mouseController.sendMovement(event.x, event.y);
      });
    } else {
      _gyroSub?.cancel();
      _gyroSub = null;
    }

    setState(() {
      _gyroModeEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Touchpad Controller'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFF), Color(0xFFE0EAFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Image.asset(
                                'assets/icon/icon.png',
                                height: 48,
                                width: 48,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mobile Mouse',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status: $status',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _hostController,
                                decoration: const InputDecoration(
                                  labelText: 'Laptop IP',
                                  prefixIcon: Icon(Icons.wifi_tethering),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 110,
                              child: TextField(
                                controller: _portController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Port',
                                  prefixIcon: Icon(Icons.usb),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isConnecting ? null : connectToPC,
                          child: Text(
                            _isConnecting ? 'Connecting...' : 'Connect',
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile.adaptive(
                          value: _gyroModeEnabled,
                          onChanged: _isConnected ? _toggleGyroMode : null,
                          title: const Text('Use Gyroscope Control'),
                          subtitle: const Text(
                            'Stream real-time phone motion as mouse input',
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Touchpad Surface',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 260,
                          child: GestureDetector(
                            onPanUpdate: _handlePadUpdate,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFEEF2FF),
                                    Color(0xFFE0E7FF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: _isConnected
                                      ? colorScheme.primary
                                      : Colors.grey.shade400,
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x22000000),
                                    offset: Offset(0, 12),
                                    blurRadius: 24,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'Swipe here to control the cursor',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isConnected
                                    ? _handleLeftClick
                                    : null,
                                icon: const Icon(Icons.mouse),
                                label: const Text('Left Click'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isConnected
                                    ? _handleRightClick
                                    : null,
                                icon: const Icon(Icons.mouse_outlined),
                                label: const Text('Right Click'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
