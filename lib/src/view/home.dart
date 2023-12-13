import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Home extends StatefulWidget {
  final WebSocketChannel channel;

  const Home({Key? key, required this.channel}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final double videoWidth = 640;
  final double videoHeight = 480;
  late bool isLandscape;
  late bool isToggle;
  late bool detected;

  GoogleMlKit vision = GoogleMlKit.vision as GoogleMlKit;
  late FaceDetector faceDetector;
  List<Face> faces = [];

  @override
  void initState() {
    super.initState();
    isLandscape = false;
    isToggle = false;
    detected = false;
    faceDetector = GoogleMlKit.vision.faceDetector();
  }

  @override
  void dispose() {
    widget.channel.sink.close();
    faceDetector.close();
    super.dispose();
  }

  Future<List<Face>> detectFaces(ui.Image image) async {
    final byteData = await image.toByteData();
    if (byteData == null) {
      // 널 데이터 처리
      return [];
    }

    final detectedFaces =
        await faceDetector.processImage(byteData as InputImage);
    return detectedFaces;
  }

  void startFaceDetection() async {
    final imageBytes = await widget.channel.stream.first;
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final byteData = await image.toByteData();
    final detectedFaces =
        await faceDetector.processImage(byteData as InputImage);

    setState(() {
      faces = detectedFaces;
      detected = true;
    });

    startFaceDetection(); // 계속해서 얼굴 인식을 수행하도록 재귀 호출
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrientationBuilder(builder: (context, orientation) {
        var screenWidth = MediaQuery.of(context).size.width;
        var screenHeight = MediaQuery.of(context).size.height;

        if (orientation == Orientation.portrait) {
          isLandscape = false;
        } else {
          isLandscape = true;
        }

        final newVideoSizeWidth =
            isLandscape ? screenWidth : videoWidth * screenWidth / videoWidth;
        final newVideoSizeHeight = isLandscape
            ? screenHeight
            : videoHeight * screenHeight / videoHeight;

        if (!detected) {
          startFaceDetection(); // 얼굴 인식 시작
        }

        return Container(
          color: Colors.black,
          child: StreamBuilder(
            stream: widget.channel.stream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                );
              } else {
                return CustomPaint(
                  foregroundPainter: FacePainter(faces),
                  child: Image.memory(
                    snapshot.data,
                    gaplessPlayback: true,
                    width: newVideoSizeWidth,
                    height: newVideoSizeHeight,
                  ),
                );
              }
            },
          ),
        );
      }),
    );
  }
}

class FacePainter extends CustomPainter {
  final List<Face> faces;

  FacePainter(this.faces);

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width;
    final double scaleY = size.height;

    for (Face face in faces) {
      final rect = Rect.fromLTRB(
        face.boundingBox.left * scaleX,
        face.boundingBox.top * scaleY,
        face.boundingBox.right * scaleX,
        face.boundingBox.bottom * scaleY,
      );

      canvas.drawRect(
        rect,
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.faces != faces;
  }
}
