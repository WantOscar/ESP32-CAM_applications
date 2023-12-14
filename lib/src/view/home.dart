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

  Vision vision = GoogleMlKit.vision;
  FaceDetector faceDetector = GoogleMlKit.vision.faceDetector();
  List<Face> faces = [];

  late StreamController _streamController;
  late Stream _broadcastStream;

  @override
  void initState() {
    super.initState();
    isLandscape = false;
    isToggle = false;
    detected = false;
    faceDetector = GoogleMlKit.vision.faceDetector();

    // StreamController를 초기화합니다. 이것은 브로드캐스트 스트림을 만듭니다.
    _streamController = StreamController.broadcast();

    // 원래 스트림에서 오는 데이터를 새로운 브로드캐스트 스트림으로 전달합니다.
    widget.channel.stream.listen((data) {
      _streamController.add(data);
    });

    // 브로드캐스트 스트림을 할당합니다.
    _broadcastStream = _streamController.stream;
  }

  @override
  void dispose() {
    super.dispose();
    widget.channel.sink.close();
    faceDetector.close();
    _streamController.close(); // StreamController도 닫아야 합니다.
    super.dispose();
  }

  Future<List<Face>> detectFaces(ui.Image image) async {
    final byteData = await image.toByteData();
    if (byteData == null) {
      return []; // 널 데이터 처리
    }

    final detectedFaces =
        await faceDetector.processImage(byteData as InputImage);
    return detectedFaces;
  }

  void startFaceDetection() async {
    final imageBytes = await widget.channel.stream.first;
    widget.channel.sink.close(); // 이전 스트림 닫기

    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    // 얼굴 인식 수행
    final byteData = await image.toByteData();
    final detectedFaces =
        await faceDetector.processImage(byteData as InputImage);

    setState(() {
      faces = detectedFaces;
      detected = true; // 얼굴 인식 완료 상태 업데이트
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

        if (!detected) {
          startFaceDetection(); // 얼굴 인식 시작
        }

        return Container(
          color: Colors.black,
          child: StreamBuilder(
            stream: _broadcastStream,
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
