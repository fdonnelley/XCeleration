import 'dart:async';
import 'package:camerawesome/camerawesome_plugin.dart';
// import 'package:excel/excel.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../server/digit_recognition.dart';
import 'dart:typed_data';
import 'package:camerawesome/camerawesome_plugin.dart' as camerawesome;
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  camerawesome.Preview? _preview;
  List<List<double>>? _greenSquareCoordinates; // Add a variable to hold the coordinates

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {
    super.dispose();
  }
  Future<List<List<double>>> _getGreenSquareCoordinates(Uint8List image) async {
    return await getDigitBoundingBoxes(image);
    // return list_of_coordinates.map((coordinates) => [
    //   Offset(coordinates[0].toDouble(), coordinates[1].toDouble()),
    //   Offset(coordinates[2].toDouble(), coordinates[3].toDouble())
    // ]).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Page')),
      body: camerawesome.CameraAwesomeBuilder.awesome(
        saveConfig: SaveConfig.photo(
          pathBuilder: (sensors) async {
            final Directory extDir = await getTemporaryDirectory();
            final testDir = await Directory('${extDir.path}/camerawesome').create(recursive: true);

            if (sensors.length == 1) {
              final String filePath =
                  '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
              return SingleCaptureRequest(filePath, sensors.first);
            } else {
              return MultipleCaptureRequest(
                {
                  for (final sensor in sensors)
                    sensor:
                        '${testDir.path}/${sensor.position == SensorPosition.front ? 'front_' : "back_"}${DateTime.now().millisecondsSinceEpoch}.jpg',
                },
              );
            }
          },
        ),
        previewFit: camerawesome.CameraPreviewFit.contain,
        sensorConfig: camerawesome.SensorConfig.single(
          sensor: camerawesome.Sensor.position(camerawesome.SensorPosition.back),
          aspectRatio: camerawesome.CameraAspectRatios.ratio_1_1,
        ),
        onImageForAnalysis: (img) => _analyzeImage(img),
        imageAnalysisConfig: camerawesome.AnalysisConfig(
          androidOptions: const camerawesome.AndroidAnalysisOptions.nv21(
            width: 250,
          ),
          autoStart: true,
          cupertinoOptions: const CupertinoAnalysisOptions.bgra8888(),
          maxFramesPerSecond: 10,
        ),
        previewDecoratorBuilder: (state, preview) {
          _preview = preview;
          // This will be shown above the preview (in a Stack)
          // It could be used in combination with MLKit to draw filters on faces for example
          return _MyPreviewDecoratorWidget(
                cameraState: state,
                greenSquareCoordinates: _greenSquareCoordinates,
                preview: _preview!,
              );
        },
        bottomActionsBuilder: (state) {
          return AwesomeBottomActions(
            state: state,
            onMediaTap: (mediaCapture) async {
              final XFile image = await mediaCapture.captureRequest.when(
                single: (SingleCaptureRequest request) async {
                  final XFile img = request.file!; // Ensure you get the image from the request and assert it's not null
                  return img;
                },
              );
              final digits = predictDigitsFromPicture(image);
              print('digits: $digits');
              OpenFile.open(mediaCapture.captureRequest.path); // Open the captured media
            },
          );
        },
        topActionsBuilder: (state) {
          return Column(
            children: [
              AwesomeCameraSwitchButton(
                state: state,
                scale: 1.5,
                theme: AwesomeTheme(
                  buttonTheme: AwesomeButtonTheme(
                    iconSize: 28,
                    padding: const EdgeInsets.all(8),
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                  ),
                ),
                onSwitchTap: (state) {
                  state.switchCameraSensor(
                    aspectRatio: state.sensorConfig.aspectRatio,
                  );
                },
                iconBuilder: () {
                  return Icon(Icons.camera_alt);
                },
              ),
              AwesomeTopActions(state: state), // Keep existing top actions
            ],
          );
        },
        // builder: (state, preview) {
        //   _preview = preview;
        //   return Stack(
        //     children: [
        //       Positioned(
        //         top: 16,
        //         right: 16,
        //         child: AwesomeCameraSwitchButton(
        //           state: state,
        //           scale: 1.5,
        //           theme: AwesomeTheme(
        //             buttonTheme: AwesomeButtonTheme(
        //               iconSize: 28,
        //               padding: const EdgeInsets.all(8),
        //               foregroundColor: Colors.black,
        //               backgroundColor: Colors.white,
        //             ),
        //           ),
        //           onSwitchTap: (state) {
        //             state.switchCameraSensor(
        //               aspectRatio: state.sensorConfig.aspectRatio,
        //             );
        //           },
        //           iconBuilder: () {
        //             return Icon(Icons.camera_alt);
        //           },
        //         ),
        //       ),
        //     ],
        //   );
        // },
        // onMediaTap: (mediaCapture) async {
        //   print('predicting image1');
        //   final XFile image = await mediaCapture.captureRequest.when(
        //     single: (SingleCaptureRequest request) async {
        //       final XFile img = request.file!; // Ensure you get the image from the request and assert it's not null
        //       return img;
        //     },
        //   );
        //   print('predicting image2');
        //   final digits = predictDigitsFromPicture(image);
        //   print('digits: $digits');
        //   OpenFile.open(mediaCapture.captureRequest.path); // Open the captured media
        // },
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _captureImage, // Call the capture function
      //   child: Icon(Icons.camera), // Button icon
      // ),
    );
  }

  // Future<void> _captureImage() async {
  //   if (_preview != null) {
  //     final img = await _preview!.takePicture(); // Capture the image
  //     final Uint8List imageBytes = await _getImageBytesFromInputImage(img);
      
  //     // Stop the AR overlay
  //     setState(() async {
  //       _greenSquareCoordinates = await _getGreenSquareCoordinates(imageBytes); // Get coordinates
  //       // Optionally, you can set a flag to indicate the AR is stopped
  //     });

  //     // Call your function with the captured image
  //     yourFunctionWithImage(imageBytes);
  //   }
  // }

  // // Function to handle the captured image
  // void yourFunctionWithImage(Uint8List image) {
  //   // Process the captured image as needed
  // }

  Future _analyzeImage(camerawesome.AnalysisImage img) async {
    // final inputImage = img.toInputImage();

    // try {
      
      final Uint8List imageBytes = await _getImageBytesFromInputImage(img);
      // print('type: ${imageBytes.runtimeType}');
      // Get the green square coordinates
      final greenSquares = await _getGreenSquareCoordinates(imageBytes);

      setState(() {
        _greenSquareCoordinates = greenSquares;
      });
  }
}

Future<void> saveImage(Uint8List imageBytes) async {
  try {
    img.Image image = img.decodeImage(Uint8List.fromList(imageBytes))!;
    List<int> pngBytes = img.encodePng(image); // Convert to PNG
    File('output_image.png').writeAsBytesSync(pngBytes); // Save locally
    // print('Image saved successfully as output_image.png');
  } catch (e) {
    print('Error while saving image: $e');
  }
}

Future<Uint8List> _getImageBytesFromInputImage(camerawesome.AnalysisImage analysisImg) async {
  // Handle different types of `AnalysisImage`
  final bytes = analysisImg.when(
    jpeg: (JpegImage image) {
      print('image is a jpeg');
      return Uint8List.fromList(image.bytes);
    },
    nv21: (Nv21Image image) {
      print('image is a Nv21Image');
      return Uint8List.fromList(image.planes[0].bytes);
    },
    bgra8888: (Bgra8888Image image) {
      return image.planes[0].bytes;
    },
  );

  if (bytes == null) {
    throw("Failed to extract bytes from the image.");
    // return Uint8List.fromList([]);
  }
  // saveImage(bytes);
  return bytes;
}

class _MyPreviewDecoratorWidget extends StatelessWidget {
  final camerawesome.CameraState cameraState;
  final camerawesome.Preview preview;
  final List<List<double>>? greenSquareCoordinates;

  const _MyPreviewDecoratorWidget({
    required this.cameraState,
    required this.preview,
    required this.greenSquareCoordinates,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final quarterWidth = constraints.maxWidth / 4;

        return Stack(
          children: [
            // Left blur
            Positioned(
              left: 0,
              top: 0,
              width: quarterWidth,
              height: constraints.maxHeight,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
            // Right blur
            Positioned(
              right: 0,
              top: 0,
              width: quarterWidth,
              height: constraints.maxHeight,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
            // Original green squares painter
            IgnorePointer(
              child: CustomPaint(
                painter: _GreenSquarePainter(
                  greenSquareCoordinates: greenSquareCoordinates,
                  preview: preview,
                  previewSize: [constraints.maxWidth, constraints.maxHeight],
                ),
                child: SizedBox.expand(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GreenSquarePainter extends CustomPainter {
  List<List<double>>? greenSquareCoordinates;
  final camerawesome.Preview preview;
  List<double> previewSize;

  _GreenSquarePainter({
    required this.greenSquareCoordinates,
    required this.preview,
    required this.previewSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // print('greenSquareCoordinates: $greenSquareCoordinates');
    // greenSquareCoordinates = [[Offset(0.0, 414.0), Offset(30.0, 46.0)]];
    if (greenSquareCoordinates != null) {
      for (var coordinates in greenSquareCoordinates!) {
        if (coordinates.length == 4) {
          final x = coordinates[0] * previewSize[0];
          final y = coordinates[1] * previewSize[1];
          final width = coordinates[2] * previewSize[0];
          final height = coordinates[3] * previewSize[1];
          // print('Drawing box with coordinates - x:$x, y:$y, width:$width, height:$height');
          final rect = Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble());
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