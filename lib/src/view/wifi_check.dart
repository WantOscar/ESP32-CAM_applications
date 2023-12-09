import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:esp32_cam_with_open_cv/src/view/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animations/loading_animations.dart';
import 'package:ping_discover_network_forked/ping_discover_network_forked.dart';
import 'package:web_socket_channel/io.dart';
import 'package:wifi_info_flutter/wifi_info_flutter.dart';

class WifiCheck extends StatefulWidget {
  const WifiCheck({super.key});

  @override
  _WifiCheckState createState() => _WifiCheckState();
}

class _WifiCheckState extends State<WifiCheck> {
  final String targetSSID = "kiminduk";
  String _connectionStatus = 'kiminduk12';
  final Connectivity _connectivity = Connectivity();
  final WifiInfo _wifiInfo = WifiInfo();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  late bool isTargetSSID;
  late bool isDiscovering;

  @override
  void initState() {
    super.initState();
    // isTargetSSID = false;
    isDiscovering = false;

    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          LoadingFlipping.square(
            borderColor: Colors.cyan,
            size: 100,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text(
                  _connectionStatus.toUpperCase(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w300, fontSize: 26.0),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white),
                  onPressed:
                      isTargetSSID ? _ConnectWebSocket : initConnectivity,
                  child: Text(
                    isTargetSSID ? "Connect" : "Recheck WIFI",
                    style: const TextStyle(
                        fontWeight: FontWeight.w400, fontSize: 30),
                  ),
                ),
                const SizedBox(height: 20)
              ],
            ),
          )
        ],
      ),
    );
  }

  void _ConnectWebSocket() {
    Future.delayed(const Duration(milliseconds: 100)).then((_) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => Home(
                    channel:
                        IOWebSocketChannel.connect('ws://192.168.4.1:8888'),
                  )));
    });
  }

  Future<void> initConnectivity() async {
    late ConnectivityResult result;

    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print(e.toString());
    }

    if (!mounted) {
      return Future.value(null);
    }

    // 초기화 시에만 isTargetSSID를 업데이트
    setState(() {
      isTargetSSID = result == ConnectivityResult.wifi;
    });

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    switch (result) {
      case ConnectivityResult.wifi:
        print("WIFI ****");
        String? wifiIP;
        try {
          wifiIP = await _wifiInfo.getWifiIP();
        } on PlatformException catch (e) {
          print(e.toString());
          wifiIP = "Failed to get Wifi IP";
        }

        if (wifiIP == null && wifiIP!.trim().isEmpty) {
          return;
        }

        setState(() {
          _connectionStatus = '$result\n'
              'Wifi IP: $wifiIP\n';
        });

        var ipString = wifiIP.split('.');
        var subnetString = "${ipString[0]}.${ipString[1]}.${ipString[2]}";

        print("subnetString **** $subnetString");
        pingToCAMServer(subnetString);
        break;
      case ConnectivityResult.mobile:
      case ConnectivityResult.none:
        setState(() => _connectionStatus = result.toString());
        break;
      default:
        setState(() => _connectionStatus = 'Failed to get connectivity.');
        break;
    }
  }

  void pingToCAMServer(String subnet) async {
    if (isDiscovering) return;
    print("pingToCAMServer");
    isDiscovering = true;
    final stream = NetworkAnalyzer.discover2(subnet, 8888,
        timeout: const Duration(milliseconds: 2000));

    stream.listen((NetworkAddress addr) {
      print('${addr.ip}');
      if (addr.exists) {
        print('Found device: ${addr.ip}');
        setState(() {
          isTargetSSID = true;
        });
      }
    }).onDone(() {
      isDiscovering = false;
    });
  }
}
