import 'dart:async';
import 'package:camerawesome/camerawesome_plugin.dart';
import '../server/function.dart';
import 'dart:typed_data';
import 'package:camerawesome/camerawesome_plugin.dart' as camerawesome;
import 'package:flutter/material.dart';


class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  camerawesome.Preview? _preview;
  List<List<Offset>>? _greenSquareCoordinates; // Add a variable to hold the coordinates

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {
    super.dispose();
  }
  Future<List<List<Offset>>> _getGreenSquareCoordinates(Uint8List image) async {
    final list_of_coordinates = await get_digit_bounding_boxes(image);
    return list_of_coordinates.map((coordinates) => [
      Offset(coordinates[0].toDouble(), coordinates[1].toDouble()),
      Offset(coordinates[2].toDouble(), coordinates[3].toDouble())
    ]).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: camerawesome.CameraAwesomeBuilder.previewOnly(
        previewFit: camerawesome.CameraPreviewFit.contain,
        sensorConfig: camerawesome.SensorConfig.single(
          sensor: camerawesome.Sensor.position(camerawesome.SensorPosition.front),
          aspectRatio: camerawesome.CameraAspectRatios.ratio_1_1,
        ),
        onImageForAnalysis: (img) => _analyzeImage(img),
        imageAnalysisConfig: camerawesome.AnalysisConfig(
          androidOptions: const camerawesome.AndroidAnalysisOptions.nv21(
            width: 250,
          ),
          autoStart: true,
          cupertinoOptions: const CupertinoAnalysisOptions.bgra8888(),
          maxFramesPerSecond: 20,
        ),
        builder: (state, preview) {
          _preview = preview;
          return _MyPreviewDecoratorWidget(
            cameraState: state,
            greenSquareCoordinates: _greenSquareCoordinates,
            preview: _preview!,
          );
        },
      ),
    );
  }

  Future _analyzeImage(camerawesome.AnalysisImage img) async {
    // final inputImage = img.toInputImage();

    try {
      
      final Uint8List imageBytes = _getImageBytesFromInputImage(img);
      // Get the green square coordinates
      _greenSquareCoordinates = await _getGreenSquareCoordinates(imageBytes); // Call the new function

      // debugPrint("...sending image resulted with : ${faces?.length} faces");
    } catch (error) {
      debugPrint("...sending image resulted error $error");
    }
  }
}
_getImageBytesFromInputImage(camerawesome.AnalysisImage img) async {
  // Assuming img has a method to get the bytes directly
  // If not, you may need to adjust this based on the actual structure of AnalysisImage
  final bytes = img.when(jpeg: (JpegImage image) {
    return image.bytes;
  });
  return bytes;
}

class _MyPreviewDecoratorWidget extends StatelessWidget {
  final camerawesome.CameraState cameraState;
  final camerawesome.Preview preview;
  final List<List<Offset>>? greenSquareCoordinates; // Accept the coordinates

  const _MyPreviewDecoratorWidget({
    required this.cameraState,
    required this.preview,
    required this.greenSquareCoordinates, // Pass the coordinates in the constructor
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GreenSquarePainter(greenSquareCoordinates: greenSquareCoordinates, preview: preview),
        child: SizedBox.expand(), // Ensure the CustomPaint takes the full size
      ),
    );
  }
}

class _GreenSquarePainter extends CustomPainter {
  final List<List<Offset>>? greenSquareCoordinates;
  final camerawesome.Preview preview;

  _GreenSquarePainter({
    required this.greenSquareCoordinates,
    required this.preview,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (greenSquareCoordinates != null) {
      for (var coordinates in greenSquareCoordinates!) {
        if (coordinates.length == 2) {
          final topLeft = coordinates[0];
          final bottomRight = coordinates[1];
          final rect = Rect.fromPoints(topLeft, bottomRight);
          canvas.drawRect(
            rect,
            Paint()
              ..color = Colors.green
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_GreenSquarePainter oldDelegate) {
    return oldDelegate.greenSquareCoordinates != greenSquareCoordinates;
  }
}