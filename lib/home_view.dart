import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as dir;
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final String _language = 'en-US';
  late dir.Ink _ink;
  List<dir.StrokePoint> _points = [];
  String result = 'recognized text will be shown here';

  late DigitalInkRecognizerModelManager modelManager;
  @override
  void initState() {
    modelManager = DigitalInkRecognizerModelManager();
    super.initState();

    checkAndDownloadModel();
    _ink = dir.Ink();
  }

  dynamic digitalInkRecognizer;
  bool isModelDownloaded = false;

  // Checking and downloading the model
  checkAndDownloadModel() async {
    log("check model start");

    isModelDownloaded = await modelManager.isModelDownloaded(_language);

    if (!isModelDownloaded) {
      isModelDownloaded = await modelManager.downloadModel(_language);
    }

    if (isModelDownloaded) {
      digitalInkRecognizer = DigitalInkRecognizer(languageCode: _language);
    }

    log("check model end");
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Clear the drawing pad
  void _clearPad() {
    setState(() {
      _ink.strokes.clear();
      _points.clear();
      result = '';
    });
  }

  // Recognize the drawn text
  Future<void> _recogniseText() async {
    if (isModelDownloaded) {
      // Pass the _ink object, not the language code
      final List<RecognitionCandidate> candidates =
          await digitalInkRecognizer.recognize(_ink);

      result = '';
      for (final candidate in candidates) {
        final text = candidate.text;
        // ignore: unused_local_variable
        final score = candidate.score;
        result += '$text\n';
      }
      setState(() {
        result; // Update the recognized text
      });
    } else {
      setState(() {
        result = "Model is not downloaded yet";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Container(
                margin: const EdgeInsets.only(top: 60),
                child: const Text(
                  'Draw in the white box below',
                  style: TextStyle(color: Colors.white),
                )),
            Container(
              margin: const EdgeInsets.only(top: 10),
              color: Colors.black,
              width: 370,
              height: 400,
              child: GestureDetector(
                onPanStart: (DragStartDetails details) {
                  _ink.strokes.add(Stroke());
                  log("onPanStart");
                },
                onPanUpdate: (DragUpdateDetails details) {
                  log("onPanUpdate");
                  setState(() {
                    final RenderObject? object = context.findRenderObject();
                    final localPosition = (object as RenderBox?)
                        ?.globalToLocal(details.localPosition);
                    if (localPosition != null) {
                      _points = List.from(_points)
                        ..add(StrokePoint(
                          x: localPosition.dx,
                          y: localPosition.dy,
                          t: DateTime.now().millisecondsSinceEpoch,
                        ));
                    }
                    if (_ink.strokes.isNotEmpty) {
                      _ink.strokes.last.points = _points.toList();
                    }
                  });
                },
                onPanEnd: (DragEndDetails details) {
                  log("onPanEnd");
                  _points.clear();
                  setState(() {});
                },
                child: CustomPaint(
                  painter: Signature(ink: _ink),
                  size: Size.infinite,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _recogniseText,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    child: const Text(
                      'Read Text',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _clearPad,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    child: const Text(
                      'Clear Pad',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            if (result.isNotEmpty)
              Text(
                result,
                style: const TextStyle(fontSize: 18, color: Colors.black),
              ),
          ],
        ));
  }
}

class Signature extends CustomPainter {
  dir.Ink ink;

  Signature({required this.ink});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    for (final stroke in ink.strokes) {
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final p1 = stroke.points[i];
        final p2 = stroke.points[i + 1];
        canvas.drawLine(Offset(p1.x.toDouble(), p1.y.toDouble()),
            Offset(p2.x.toDouble(), p2.y.toDouble()), paint);
      }
    }
  }

  @override
  bool shouldRepaint(Signature oldDelegate) => true;
}
