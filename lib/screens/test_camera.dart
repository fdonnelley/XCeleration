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
              print('Creating single capture request with path: $filePath');
              return SingleCaptureRequest(filePath, sensors.first);
            } else {
              print('Creating multiple capture request');
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
          flashMode: camerawesome.FlashMode.auto,
        ),
        enablePhysicalButton: true,
        onImageForAnalysis: (img) => _analyzeImage(img),
        // imageAnalysisConfig: camerawesome.AnalysisConfig(
        //   androidOptions: const camerawesome.AndroidAnalysisOptions.nv21(
        //     width: 250,
        //   ),
        //   autoStart: true,
        //   cupertinoOptions: const CupertinoAnalysisOptions.bgra8888(),
        //   maxFramesPerSecond: 10,
        // ),
        onMediaCaptureEvent: (event) async {
          print('Media capture event: ${event.status}');
          switch ((event.status, event.isPicture, event.isVideo)) {
            case (MediaCaptureStatus.capturing, true, false):
              print('Taking picture...');
              break;
            case (MediaCaptureStatus.success, true, false):
              print('Picture taken successfully');
                event.captureRequest.when(
                  single: (SingleCaptureRequest request) async {
                    // print('Single capture request received');
                    // await photoState.takePhoto();
                    // print('Photo taken successfully');
                    final file = request.file;
                    if (file == null) {
                      print('Error: No file captured');
                      return null;
                    }
                    try {
                        final digits = await predictDigitsFromPicture(file);
                        print('Digit prediction successful! Predicted digits: $digits');
                      } catch (e) {
                        print('Error predicting digits: $e');
                      }
                      try {
                        print('Opening image file...');
                        await OpenFile.open(file.path);
                      } catch (e) {
                        print('Error opening file: $e');
                      }
                      return file;
                  },
                  // multiple: (MultipleCaptureRequest request) async {
                  //   print('Multiple capture request received');
                    // await photoState.takePhoto();
                    // print('Photo taken successfully');
                    // final file = request.fileBySensor.values.first;
                    // print('Multiple capture file path: ${file?.path}');
                    // return file;
                  // },
                );
              break;
            case (MediaCaptureStatus.failure, true, false):
              print('Failed to take picture: ${event.exception}');
              break;
            default:
              print('Unknown event: $event');
          }
        },
        previewDecoratorBuilder: (state, preview) {
          _preview = preview;
          _greenSquareCoordinates?.add([0, 0, 1, 1]);
          // This will be shown above the preview (in a Stack)
          // It could be used in combination with MLKit to draw filters on faces for example
          return _MyPreviewDecoratorWidget(
                cameraState: state,
                greenSquareCoordinates: _greenSquareCoordinates,
                preview: _preview!,
              );
        },
        // bottomActionsBuilder: (state) {
        //   // print('Building bottom actions with state: ${state.captureMode}');
        //   return AwesomeBottomActions(
        //     state: state,
        //     onMediaTap: (mediaCapture) async {
        //       print('Bottom actions onMediaTap called');
        //       try {
        //         print('Taking picture...');
        //         await state.when(
        //           onPhotoMode: (photoState) async {
        //             print('In photo mode, taking picture');
        //             try {
        //               print('Capture request type: ${mediaCapture.captureRequest.runtimeType}');
        //               final XFile? image = await mediaCapture.captureRequest.when(
        //                 single: (SingleCaptureRequest request) async {
        //                   print('Single capture request received');
        //                   await photoState.takePhoto();
        //                   print('Photo taken successfully');
        //                   final file = request.file;
        //                   if (file == null) {
        //                     print('Error: No file captured');
        //                     return null;
        //                   }
        //                   print('Single capture file path: ${file.path}');
        //                   try {
        //                     print('Attempting to predict digits...');
        //                     final digits = await predictDigitsFromPicture(file);
        //                     print('Digit prediction successful! Predicted digits: $digits');
        //                   } catch (e) {
        //                     print('Error predicting digits: $e');
        //                   }
        //                   try {
        //                     print('Opening image file...');
        //                     await OpenFile.open(file.path);
        //                   } catch (e) {
        //                     print('Error opening file: $e');
        //                   }
        //                   return file;
        //                 },
        //                 multiple: (MultipleCaptureRequest request) async {
        //                   print('Multiple capture request received');
        //                   await photoState.takePhoto();
        //                   print('Photo taken successfully');
        //                   final file = request.fileBySensor.values.first;
        //                   print('Multiple capture file path: ${file?.path}');
        //                   return file;
        //                 },
        //               );
        //               print('checking to see if code reached here. image: $image');
                      
        //               if (image != null) {
        //                 print('Image captured successfully: ${image.path}');
        //                 print('Starting digit prediction...');
        //                 try {
        //                   final digits = await predictDigitsFromPicture(image);
        //                   print('Digit prediction successful! Predicted digits: $digits');
        //                   print('Opening image file...');
        //                   await OpenFile.open(image.path);
        //                 } catch (e) {
        //                   print('Error during digit prediction or file opening: $e');
        //                 }
        //               } else {
        //                 print('Error: No image captured');
        //               }
        //             } catch (e) {
        //               print('Error taking photo: $e');
        //             }
        //           },
        //           onVideoMode: (videoState) {
        //             print('Error: In video mode, should be in photo mode');
        //           },
        //           onPreparingCamera: (preparingState) {
        //             print('Error: Camera is still preparing');
        //           },
        //         );
        //       } catch (e) {
        //         print('Error in onMediaTap: $e');
        //       }
        //     },
        //   );
        // },
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
      final bgraBytes = image.planes[0].bytes;
      final rgbaBytes = Uint8List(bgraBytes.length);

      // Convert BGRA to RGBA
      for (int i = 0; i < bgraBytes.length; i += 4) {
        rgbaBytes[i] = bgraBytes[i + 2];     // Red
        rgbaBytes[i + 1] = bgraBytes[i + 1]; // Green
        rgbaBytes[i + 2] = bgraBytes[i];     // Blue
        rgbaBytes[i + 3] = bgraBytes[i + 3]; // Alpha
      }

      // Create an image from RGBA bytes
      final imgImage = img.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: rgbaBytes.buffer,
        numChannels: 4,
      );

      // Encode as PNG
      return Uint8List.fromList(img.encodePng(imgImage));
    },
    // // Add other cases if necessary
    // unknown: () {
    //   print("Unknown image format");
    //   return null;
    // },
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
        // print("Preview screen size: $size");
        // print("Preview screen preview.previewSize: ${preview.previewSize}");
        // print("Preview screen preview.nativePreviewSize: ${preview.nativePreviewSize}");
        // print("Preview screen preview.nativePreviewSize (height, width): ${preview.rect.height}, ${preview.rect.width}");
        // print('constraints.maxWidth: ${constraints.maxWidth}');
        // print('constraints.maxHeight: ${constraints.maxHeight}');
        print("Preview screen size: $size");
        print("Preview screen preview.previewSize: ${preview.previewSize}");
        print("Preview screen preview.nativePreviewSize: ${preview.nativePreviewSize}");
        print("Preview screen preview.nativePreviewSize (height, width): ${preview.rect.height}, ${preview.rect.width}");
        print('constraints.maxWidth: ${constraints.maxWidth}');
        print('constraints.maxHeight: ${constraints.maxHeight}');
        final quarterWidth = constraints.maxWidth / 4;
        final blurAmount = 10.0;

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
                  filter: ui.ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
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
                  filter: ui.ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
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
          print('canvas size: $size');
          print('canvas size: ${canvas.getLocalClipBounds()}');
          print('previewSize: $previewSize');
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