import 'dart:async';

import 'package:esp32_cam_with_open_cv/src/view/wifi_check.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Home extends StatefulWidget {
  final WebSocketChannel channel;

  const Home({super.key, required this.channel});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final double videoWidth = 640;
  final double videoHeight = 480;

  double newVideoSizeWidth = 640;
  double newVideoSizeHeight = 480;

  late bool isLandscape;
  late bool isToggle;
  late bool detected;
  // late ObjectDetector _detector;
  // late String _timeString;
  final _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // _detector = ObjectDetector(
    //     options: ObjectDetectorOptions(
    //         mode: DetectionMode.stream,
    //         classifyObjects: true,
    //         multipleObjects: true));
    isLandscape = false;
    // isToggle = false;
    // detected = false;
  }

  @override
  void dispose() {
    widget.channel.sink.close();
    super.dispose();
  }

  // void detect(Uint8List bytes) {
  //   if (isToggle) return;
  //   isToggle = true;
  //   _detector
  //       .processImage(InputImage.fromBytes(
  //           bytes: bytes,
  //           metadata: InputImageMetadata(
  //               size: Size(videoWidth, videoHeight),
  //               rotation: InputImageRotation.rotation0deg,
  //               format: InputImageFormat.yv12,
  //               bytesPerRow: 1000)))
  //       .then((result) {
  //     if (result.isNotEmpty) {
  //       setState(() {
  //         detected = true;
  //         debugPrint("사람얼굴 등장");
  //       });
  //     } else {
  //       setState(() {
  //         detected = false;
  //         debugPrint("사람이 아님");
  //       });
  //     }
  //     isToggle = false;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrientationBuilder(builder: (context, orientation) {
        var screenWidth = MediaQuery.of(context).size.width;
        var screenHeight = MediaQuery.of(context).size.height;

        if (orientation == Orientation.portrait) {
          //screenWidth < screenHeight

          isLandscape = false;
          newVideoSizeWidth = screenWidth;
          newVideoSizeHeight = videoHeight * newVideoSizeWidth / videoWidth;
        } else {
          isLandscape = true;
          newVideoSizeHeight = screenHeight;
          newVideoSizeWidth = videoWidth * newVideoSizeHeight / videoHeight;
        }

        return Container(
          color: Colors.black,
          child: StreamBuilder(
            stream: widget.channel.stream,
            builder: (context, snapshot) {
              // ConnectionState가 done일 때만 Navigator.pushReplacement 호출
              if (snapshot.connectionState == ConnectionState.done) {
                Future.delayed(const Duration(milliseconds: 100)).then((_) {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) =>
                              const WifiCheck()));
                });
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                );
              } else {
                // detect(snapshot.data);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        SizedBox(
                          height: isLandscape ? 0 : 30,
                        ),
                        Image.memory(
                          snapshot.data,
                          gaplessPlayback: true,
                          width: newVideoSizeWidth,
                          height: newVideoSizeHeight,
                        ),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        );
      }),
    );
  }
}
