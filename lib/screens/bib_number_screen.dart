import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'camera_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../server/function.dart';
import 'test_camera.dart';
// import 'package:camera/camera.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:race_timing_app/bluetooth_service.dart' as app_bluetooth;

class BibNumberScreen extends StatefulWidget {
  const BibNumberScreen({super.key});

  @override
  State<BibNumberScreen> createState() => _BibNumberScreenState();
}

class _BibNumberScreenState extends State<BibNumberScreen> {
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  final List<Map<String, dynamic>> _bibRecords = [];
  // final ImagePicker _imagePicker = ImagePicker();
  // late CameraController _cameraController;
  // final app_bluetooth.BluetoothService _bluetoothService = app_bluetooth.BluetoothService();
  // BluetoothDevice? _connectedDevice;
  // List<BluetoothDevice> _availableDevices = [];

  void _addBibNumber() {
    setState(() {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
      _bibRecords.add({'bib_number': '', 'position': _bibRecords.length + 1});
    });

    // Automatically focus the last input box
    Future.delayed(Duration.zero, () {
      _focusNodes.last.requestFocus();
    });
  }

  void _updateBibNumber(int index, String bibNumber) {
    setState(() {
      _bibRecords[index]['bib_number'] = bibNumber;
    });
  }

  Future<void> _captureBibNumber(int index) async {
    // Navigate to the CameraScreen to capture an image
    final imagePath = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraPage()),
    );

    if (imagePath != null) {
      // Placeholder: Process the image to extract numbers
      String extractedBib = await _processImageToExtractNumber(imagePath);

      // Update the text field and record with the extracted number
      setState(() {
        _controllers[index].text = extractedBib;
        _bibRecords[index]['bib_number'] = extractedBib;
      });
    }
  }

  // Future<void> initCamera() async {
  //   final cameras = await availableCameras();
  //   _cameraController = CameraController(
  //     cameras.first, // Use the first available camera
  //     ResolutionPreset.high,
  //   );
  //   await _cameraController.initialize();
  // }

  // Future<void> _captureBibNumber(int index) async {
  //   // Use the ImagePicker to take a picture
  //   final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);

  //   // final image = await _cameraController.takePicture();
  //   // print('Photo captured at ${image.path}');
  //   print(image.runtimeType);

  //   if (image != null) {
  //     // Placeholder: Process the image to extract numbers
  //     String extractedBib = await _processImageToExtractNumber(image);

  //     // Update the text field and record with the extracted number
  //     setState(() {
  //       _controllers[index].text = extractedBib;
  //       _bibRecords[index]['bib_number'] = extractedBib;
  //     });
  //   }
  // }

  Future<void> _showQrCode() async {
    final data = _generateQrData(); // Ensure this returns a String
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Share Bib Numbers'),
          content: SizedBox(
            width: 200,
            height: 200,
            child: QrImageView(
              data: data,
              version: QrVersions.auto,
              errorCorrectionLevel: QrErrorCorrectLevel.M, // Adjust as needed
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _generateQrData() {
    return jsonEncode(_bibRecords.map((record) => record['bib_number']).toList());
  }

  // void _findDevices() async {
  //   try {
  //     // Check if Bluetooth is enabled
  //     final isOn = await _bluetoothService.isBluetoothOn();
  //     if (!isOn) {
  //       _showBluetoothOffDialog();
  //       return;
  //     }

  //     // Proceed to find devices if Bluetooth is on
  //     await for (final devices in _bluetoothService.getAvailableDevices()) {
  //       setState(() {
  //         _availableDevices = devices;
  //       });
  //     }
  //   } catch (e) {
  //     // Handle other exceptions (optional)
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to scan for devices: $e')),
  //     );
  //   }
  // }

  // void _disconnectDevice() async {
  //   final bluetoothService = app_bluetooth.BluetoothService();
  //   if (_connectedDevice == null) return;

  //   final confirm = await showDialog<bool>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Confirm Disconnect'),
  //         content: const Text('Are you sure you want to disconnect?'),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text('Cancel'),
  //             onPressed: () => Navigator.of(context).pop(false),
  //           ),
  //           TextButton(
  //             child: const Text('Disconnect'),
  //             onPressed: () => Navigator.of(context).pop(true),
  //           ),
  //         ],
  //       );
  //     },
  //   );

  //   if (confirm == true) {
  //     try {
  //       await bluetoothService.disconnectDevice(_connectedDevice!);
  //       setState(() {
  //         _connectedDevice = null; // Clear the connected device
  //       });
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Disconnected successfully')),
  //       );
  //     } catch (e) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Failed to disconnect: $e')),
  //       );
  //     }
  //   }
  // }

  // void _connectToDevice(BluetoothDevice device) async {
  //   try {
  //     final connectedDevice = await _bluetoothService.connectToDevice(device);
  //     setState(() {
  //       _connectedDevice = connectedDevice;
  //     });
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Connected successfully')),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to connect: $e')),
  //     );
  //   }
  // }

  // void _sendBibNumbers() async {
  //   if (_connectedDevice == null) return;

  //   try {
  //     final data = _bibRecords.join(';').codeUnits; // Serialize the bib numbers
  //     await _bluetoothService.sendData(_connectedDevice!, data);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Bib numbers sent successfully')),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to send bib numbers: $e')),
  //     );
  //   }
  // }

  // void _showBluetoothOffDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Bluetooth Off'),
  //       content: const Text('Please turn on Bluetooth to search for devices.'),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             Navigator.of(context).pop();
  //           },
  //           child: const Text('OK'),
  //         ),
  //       ],
  //     ),
  //   );
  // }


  Future<String> _processImageToExtractNumber(XFile image) async {
    try {
      return await predictDigitsFromPicture(image);
    }
    catch (e) {
      print('error proccessing image: $e');
    }
    // Placeholder function for OCR
    // You can integrate a package like Tesseract OCR or Google's ML Kit here
    return "123"; // Replace this with the actual extracted number
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Record Bib Numbers')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ElevatedButton(
                onPressed: _addBibNumber,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                ),
                child: const Text('Add Bib Number', style: TextStyle(fontSize: 20)),
              ),
            ),
            if (_bibRecords.isNotEmpty)
              ElevatedButton(
                onPressed: _showQrCode,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                ),
                child: const Text('Share Bib Numbers', style: TextStyle(fontSize: 20)),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _bibRecords.length,
                itemBuilder: (context, index) {
                  // final record = _bibRecords[index];
                  final controller = _controllers[index];
                  final focusNode = _focusNodes[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    child: Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                focusNode: focusNode,
                                controller: controller,
                                decoration: InputDecoration(
                                  hintText: 'Enter Bib #',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) => _updateBibNumber(index, value),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.camera_alt),
                              onPressed: () => _captureBibNumber(index),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // ElevatedButton(
            //   onPressed: _findDevices,
            //   child: const Text('Find Devices'),
            // ),
            // if (_connectedDevice == null)
            //   DropdownButton<BluetoothDevice>(
            //     hint: const Text('Select Device'),
            //     items: _availableDevices.map((device) {
            //       return DropdownMenuItem(
            //         value: device,
            //         child: Text(device.platformName),
            //       );
            //     }).toList(),
            //     onChanged: (device) {
            //       if (device != null) _connectToDevice(device);
            //     },
            //   ),
            // if (_connectedDevice != null)
            //   ElevatedButton(
            //     onPressed: _sendBibNumbers,
            //     child: const Text('Send Bib Numbers'),
            //   ),
            // if (_connectedDevice != null) ...[
            //     const SizedBox(height: 8),
            //     ElevatedButton(
            //       onPressed: _disconnectDevice, // Add disconnect button
            //       child: const Text('Disconnect'),
            //     ),
            // ],
          ],
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:race_timing_app/bluetooth_service.dart' as app_bluetooth;

// class BibNumberScreen extends StatefulWidget {
//   const BibNumberScreen({super.key});

//   @override
//   State<BibNumberScreen> createState() => _BibNumberScreenState();
// }

// class _BibNumberScreenState extends State<BibNumberScreen> {
//   List<String> _bibNumbers = [];
//   BluetoothDevice? _connectedDevice;
//   List<BluetoothDevice> _availableDevices = [];
//   final app_bluetooth.BluetoothService _bluetoothService = app_bluetooth.BluetoothService();

//   void _addBibNumber(String bibNumber) {
//     setState(() {
//       _bibNumbers.add(bibNumber);
//     });
//   }

//   void _findDevices() async {
//     await for (final devices in _bluetoothService.getAvailableDevices()) {
//       setState(() {
//         _availableDevices = devices;
//       });
//     }
//   }

//   void _connectToDevice(BluetoothDevice device) async {
//     try {
//       final connectedDevice = await _bluetoothService.connectToDevice(device);
//       setState(() {
//         _connectedDevice = connectedDevice;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Connected successfully')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to connect: $e')),
//       );
//     }
//   }

//   void _sendBibNumbers() async {
//     if (_connectedDevice == null) return;

//     try {
//       final data = _bibNumbers.join(';').codeUnits; // Serialize the bib numbers
//       await _bluetoothService.sendData(_connectedDevice!, data);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Bib numbers sent successfully')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to send bib numbers: $e')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Record Bib Numbers')),
//       body: Column(
//         children: [
//           TextField(
//             onSubmitted: (value) {
//               if (value.isNotEmpty) {
//                 _addBibNumber(value);
//               }
//             },
//             decoration: const InputDecoration(
//               labelText: 'Enter Bib Number',
//               border: OutlineInputBorder(),
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: _bibNumbers.length,
//               itemBuilder: (context, index) {
//                 return ListTile(
//                   title: Text('Bib Number: ${_bibNumbers[index]}'),
//                 );
//               },
//             ),
//           ),
//           ElevatedButton(
//             onPressed: _findDevices,
//             child: const Text('Find Devices'),
//           ),
//           if (_connectedDevice == null)
//             DropdownButton<BluetoothDevice>(
//               hint: const Text('Select Device'),
//               items: _availableDevices.map((device) {
//                 return DropdownMenuItem(
//                   value: device,
//                   child: Text(device.platformName),
//                 );
//               }).toList(),
//               onChanged: (device) {
//                 if (device != null) _connectToDevice(device);
//               },
//             ),
//           if (_connectedDevice != null)
//             ElevatedButton(
//               onPressed: _sendBibNumbers,
//               child: const Text('Send Bib Numbers'),
//             ),
//         ],
//       ),
//     );
//   }
// }
