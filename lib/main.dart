import 'package:esp32_cam_with_open_cv/src/view/wifi_check.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      title: "Dash Cam App",
      home: const WifiCheck(),
    );
  }
}
