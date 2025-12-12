import 'package:flutter/material.dart';
import 'services/tcp_service.dart';
import 'controllers/mouse_controller.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MouseControlScreen(),
    );
  }
}

class MouseControlScreen extends StatefulWidget {
  @override
  State<MouseControlScreen> createState() => _MouseControlScreenState();
}

class _MouseControlScreenState extends State<MouseControlScreen> {
  final tcp = TcpService();
  late MouseController mouseController;

  @override
  void initState() {
    super.initState();
    mouseController = MouseController(tcp);
  }

  String status = "Not Connected";

  void connectToPC() async {
    bool ok = await tcp.connect("192.168.0.100", 5000); 
    if (ok) {
      setState(() => status = "Connected");
      mouseController.startSendingGyro();
    } else {
      setState(() => status = "Connection Failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Flutter Mouse Controller")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(status),
          ElevatedButton(
            onPressed: connectToPC,
            child: Text("Connect"),
          ),
          ElevatedButton(
            onPressed: mouseController.sendLeftClick,
            child: Text("Left Click"),
          ),
          ElevatedButton(
            onPressed: mouseController.sendRightClick,
            child: Text("Right Click"),
          ),
        ],
      ),
    );
  }
}
