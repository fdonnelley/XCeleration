import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'camera_screen.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:race_timing_app/bluetooth_service.dart' as app_bluetooth;

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
  final app_bluetooth.BluetoothService _bluetoothService = app_bluetooth.BluetoothService();
  BluetoothDevice? _connectedDevice;
  List<BluetoothDevice> _availableDevices = [];

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
      MaterialPageRoute(builder: (context) => CameraScreen()),
    );

    if (imagePath != null) {
      // Placeholder: Process the image to extract numbers
      String extractedBib = _processImageToExtractNumber(imagePath);

      // Update the text field and record with the extracted number
      setState(() {
        _controllers[index].text = extractedBib;
        _bibRecords[index]['bib_number'] = extractedBib;
      });
    }
  }

  void _findDevices() async {
    try {
      // Check if Bluetooth is enabled
      final isOn = await _bluetoothService.isBluetoothOn();
      if (!isOn) {
        _showBluetoothOffDialog();
        return;
      }

      // Proceed to find devices if Bluetooth is on
      await for (final devices in _bluetoothService.getAvailableDevices()) {
        setState(() {
          _availableDevices = devices;
        });
      }
    } catch (e) {
      // Handle other exceptions (optional)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to scan for devices: $e')),
      );
    }
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      final connectedDevice = await _bluetoothService.connectToDevice(device);
      setState(() {
        _connectedDevice = connectedDevice;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connected successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect: $e')),
      );
    }
  }

  void _sendBibNumbers() async {
    if (_connectedDevice == null) return;

    try {
      final data = _bibRecords.join(';').codeUnits; // Serialize the bib numbers
      await _bluetoothService.sendData(_connectedDevice!, data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bib numbers sent successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send bib numbers: $e')),
      );
    }
  }

  void _showBluetoothOffDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bluetooth Off'),
        content: const Text('Please turn on Bluetooth to search for devices.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }


  String _processImageToExtractNumber(XFile image) {
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
      appBar: AppBar(title: const Text('Record Bib Numbers')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _addBibNumber,
            child: const Text('Add Bib Number'),
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
          ElevatedButton(
            onPressed: _findDevices,
            child: const Text('Find Devices'),
          ),
          if (_connectedDevice == null)
            DropdownButton<BluetoothDevice>(
              hint: const Text('Select Device'),
              items: _availableDevices.map((device) {
                return DropdownMenuItem(
                  value: device,
                  child: Text(device.platformName),
                );
              }).toList(),
              onChanged: (device) {
                if (device != null) _connectToDevice(device);
              },
            ),
          if (_connectedDevice != null)
            ElevatedButton(
              onPressed: _sendBibNumbers,
              child: const Text('Send Bib Numbers'),
            ),
        ],
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
