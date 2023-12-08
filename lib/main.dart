import 'package:esp32_cam_with_open_cv/src/app.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(
        channel: IOWebSocketChannel.connect('ws://192.168.4.1:8080'),
      ),
    );
  }
}
