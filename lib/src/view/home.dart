import 'dart:typed_data';

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
  late bool isBusy;

  Vision vision = GoogleMlKit.vision;
  late ObjectDetector objectDetector;
  List<Face> faces = [];

  @override
  void initState() {
    super.initState();
    isLandscape = false;
    isToggle = false;
    detected = false;
    isBusy = false;

    objectDetector = ObjectDetector(
        options: ObjectDetectorOptions(
            mode: DetectionMode.stream,
            classifyObjects: true,
            multipleObjects: true));
  }

  @override
  void dispose() {
    super.dispose();
    widget.channel.sink.close();
    objectDetector.close();
    super.dispose();
  }

  void detectFaces(Uint8List bytes) async {
    int bytesPerRow = videoWidth.toInt();
    isBusy = true;
    // Android에서 흔히 사용되는 이미지 포맷으로 설정
    objectDetector
        .processImage(InputImage.fromBytes(
            bytes: bytes,
            metadata: InputImageMetadata(
                size: Size(videoWidth, videoHeight),
                rotation: InputImageRotation.rotation0deg,
                format: InputImageFormat.bgra8888,
                bytesPerRow: bytesPerRow)))
        .then((objects) {
      if (objects.isEmpty) {
        print("얼굴아님");
        setState(() {
          detected = false;
        });
      } else {
        print("얼굴임");
        setState(() {
          detected = true;
        });
      }
      isBusy = false;
    });
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

        return StreamBuilder(
          stream: widget.channel.stream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            } else {
              detectFaces(snapshot.data);
              return Stack(
                children: [
                  (detected)
                      ? const Positioned(
                          bottom: 200,
                          right: 10,
                          child: Text(
                            "객체가 나타났어요 ~~",
                            style: TextStyle(fontSize: 40),
                          ))
                      : Container(),
                  Image.memory(
                    snapshot.data,
                    gaplessPlayback: true,
                    width: newVideoSizeWidth,
                    height: newVideoSizeHeight,
                  ),
                ],
              );
            }
          },
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
