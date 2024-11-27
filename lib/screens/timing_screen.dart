import 'package:race_timing_app/screens/results_screen.dart';
import 'package:race_timing_app/utils/time_formatter.dart';
import 'package:flutter/material.dart';
import 'bib_number_screen.dart';
import 'package:race_timing_app/bluetooth_service.dart' as app_bluetooth;
import 'package:race_timing_app/database_helper.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';


class TimingScreen extends StatefulWidget {
  const TimingScreen({super.key});

  @override
  State<TimingScreen> createState() => _TimingScreenState();
}

class _TimingScreenState extends State<TimingScreen> {
  final List<Map<String, dynamic>> _records = [];
  DateTime? _startTime;
  final List<TextEditingController> _controllers = [];
  List<BluetoothDevice> _availableDevices = [];
  BluetoothDevice? _connectedDevice;

  void _startRace() {
    if (_records.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Start a New Race'),
          content: const Text('Are you sure you want to start a new race? Doing so will clear the existing times.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                setState(() {
                  _records.clear();
                  _startTime = DateTime.now();
                });
              },
              child: const Text('Yes'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _records.clear();
        _startTime = DateTime.now();
      });
    }
  }

  void _stopRace() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop the Race'),
        content: const Text('Are you sure you want to stop the race?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              setState(() {
                _startTime = null;
              });
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _logTime() {
    if (_startTime == null) return;

    setState(() {
      final now = DateTime.now();
      final difference = now.difference(_startTime!);

      _records.add({
        'time': difference,
        'formatted_time': formatDuration(difference),
        'bib_number': null,
        'position': _records.length + 1, // Add position based on the order of logging
      });
    });

    // Add a new controller for the new record
    _controllers.add(TextEditingController());
  }

  void _updateBib(int index, String bib) async {
    // Update the bib in the record
    setState(() {
      _records[index]['bib_number'] = bib;
    });

    // Fetch runner details from the database
    final runner = await DatabaseHelper.instance.fetchRunnerByBibNumber(bib);

    // Update the record with runner details if found
    if (runner != null) {
      setState(() {
        _records[index]['name'] = runner['name'];
        _records[index]['grade'] = runner['grade'];
        _records[index]['school'] = runner['school'];
      });
    }
    else {
      setState(() {
        _records[index]['name'] = null;
        _records[index]['grade'] = null;
        _records[index]['school'] = null;
      });
    }
  }

  void _findDevices() async {
    final service = app_bluetooth.BluetoothService();
    try {
      // Check if Bluetooth is enabled
      final isOn = await service.isBluetoothOn();
      print(isOn);
      if (!isOn) {
        _showBluetoothOffDialog();
        return;
      }

      await for (final devices in service.getAvailableDevices()) {
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
    final service = app_bluetooth.BluetoothService();
    try {
      final connectedDevice = await service.connectToDevice(device);
      setState(() {
        _connectedDevice = connectedDevice;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect: $e')),
      );
    }
  }

  void _syncDataWithDevice() async {
    if (_connectedDevice == null) return;

    final service = app_bluetooth.BluetoothService();
    try {
      // Receive bib number data
      final rawData = await service.receiveData(_connectedDevice!);
      final bibData = String.fromCharCodes(rawData).split(';');

      // Match bib numbers with times
      for (int i = 0; i < bibData.length && i < _records.length; i++) {
        setState(() {
          _records[i]['bib_number'] = bibData[i];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    }
  }

  void _disconnectDevice() async {
    final bluetoothService = app_bluetooth.BluetoothService();
    if (_connectedDevice == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Disconnect'),
          content: const Text('Are you sure you want to disconnect?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Disconnect'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await bluetoothService.disconnectDevice(_connectedDevice!);
        setState(() {
          _connectedDevice = null; // Clear the connected device
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disconnected successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to disconnect: $e')),
        );
      }
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


  void _navigateToBibNumbers() {
    // Navigate to the BibNumberScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BibNumberScreen(),
      ),
    );
  }

  void _navigateToResults() {
    // Navigate to the results page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(runners: _records),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Race Timing')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Buttons for Race Control
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: _startTime == null ? _startRace : _stopRace,
                  child: Text(_startTime == null ? 'Start Race' : 'Stop Race'),
                ),
                ElevatedButton(
                  onPressed: _startTime != null ? _logTime : null,
                  child: const Text('Log Time'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _navigateToBibNumbers,
              icon: const Icon(Icons.numbers),
              label: const Text('Record Bib Numbers'),
            ),
            if (_startTime == null && _records.isNotEmpty) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _navigateToResults,
                icon: const Icon(Icons.bar_chart),
                label: const Text('Go to Results'),
              ),
            ],
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _findDevices,
              icon: const Icon(Icons.bluetooth),
              label: const Text('Connect via Bluetooth'),
            ),
            if (_connectedDevice != null) ...[
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _disconnectDevice, // Add disconnect button
                child: const Text('Disconnect'),
              ),
              if (_startTime == null && _records.isNotEmpty)
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _syncDataWithDevice,
                  child: const Text('Sync Data'),
                ),
            ],
            const SizedBox(height: 16),
            // Bluetooth Devices List
            if (_availableDevices.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _availableDevices.length,
                  itemBuilder: (context, index) {
                    final device = _availableDevices[index];
                    return Card(
                      child: ListTile(
                        title: Text(device.platformName.isNotEmpty
                            ? device.platformName
                            : 'Unknown Device'),
                        subtitle: Text(device.remoteId.toString()),
                        trailing: IconButton(
                          icon: const Icon(Icons.link),
                          onPressed: () {
                            _connectToDevice(device);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_connectedDevice != null)
              DropdownButton<BluetoothDevice>(
                value: _connectedDevice,
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
            // Records Section
            if (_records.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final record = _records[index];
                    final controller = _controllers[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Time: ${record['formatted_time']}',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: TextField(
                                    controller: controller,
                                    decoration: InputDecoration(
                                      labelText: 'Bib #',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onChanged: (value) =>
                                        _updateBib(index, value),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (record['name'] != null)
                              Text('Name: ${record['name']}',
                                  style: const TextStyle(fontSize: 14)),
                            if (record['grade'] != null)
                              Text('Grade: ${record['grade']}',
                                  style: const TextStyle(fontSize: 14)),
                            if (record['school'] != null)
                              Text('School: ${record['school']}',
                                  style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:race_timing_app/database_helper.dart';
// import 'package:race_timing_app/screens/results_screen.dart';
// import 'package:race_timing_app/utils/time_formatter.dart'; // 

// class TimingScreen extends StatefulWidget {
//   const TimingScreen({super.key});

//   @override
//   State<TimingScreen> createState() => _TimingScreenState();
// }

// class _TimingScreenState extends State<TimingScreen> {
//   final List<Map<String, dynamic>> _records = [];
//   DateTime? _startTime;
//   final List<TextEditingController> _controllers = [];
  
//   void _startRace() {
//     setState(() {
//       _startTime = DateTime.now();
//     });
//   }

//   void _stopRace() {
//     setState(() {
//       _startTime = null;
//     });
//   }

//   void _logTime() {
//     if (_startTime == null) return;

//     setState(() {
//       final now = DateTime.now();
//       final difference = now.difference(_startTime!);

//       _records.add({
//         'time': difference,
//         'formatted_time': formatDuration(difference),
//         'bib_number': null,
//         'position': _records.length + 1, // Add position based on the order of logging
//       });
//     });

//     // Add a new controller for the new record
//       _controllers.add(TextEditingController());
//   }

  // void _updateBib(int index, String bib) async {
  //   // Update the bib in the record
  //   setState(() {
  //     _records[index]['bib_number'] = bib;
  //   });

  //   // Fetch runner details from the database
  //   final runner = await DatabaseHelper.instance.fetchRunnerByBibNumber(bib);

  //   // Update the record with runner details if found
  //   if (runner != null) {
  //     setState(() {
  //       _records[index]['name'] = runner['name'];
  //       _records[index]['grade'] = runner['grade'];
  //       _records[index]['school'] = runner['school'];
  //     });
  //   }
  //   else {
  //     setState(() {
  //       _records[index]['name'] = null;
  //       _records[index]['grade'] = null;
  //       _records[index]['school'] = null;
  //     });
  //   }
  // }

//   void _navigateToResults() {
//     // Navigate to the results page
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ResultsScreen(runners: _records),
//       ),
//     );
//   }

//   @override
//   void initState() {
//     super.initState();
//     // Initialize controllers for each record
//     _initializeControllers();
//   }

//   void _initializeControllers() {
//     _controllers.clear();
//     _controllers.addAll(_records.map((_) => TextEditingController()));
//   }

//   @override
//   void dispose() {
//     // Dispose of all controllers
//     for (var controller in _controllers) {
//       controller.dispose();
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Race Timing')),
//       body: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               if (_startTime == null)
//                 ElevatedButton(
//                   onPressed: _startRace,
//                   child: const Text('Start Race'),
//                 )
//               else
//                 ElevatedButton(
//                   onPressed: _stopRace,
//                   child: const Text('Stop Race'),
//                 ),
//               const SizedBox(width: 16),
//               ElevatedButton(
//                 onPressed: _startTime != null ? _logTime : null,
//                 child: const Text('Log Time'),
//               ),
//             ],
//           ),
//           if (_startTime == null && _records.isNotEmpty)
//             ElevatedButton(
//               onPressed: _navigateToResults,
//               child: const Text('Go to Results'),
//             ),
//           const SizedBox(height: 16),
//           Expanded(
//             child: ListView.builder(
//               itemCount: _records.length,
//               itemBuilder: (context, index) {
//                 final record = _records[index];
//                 final controller = _controllers[index];

//                 return Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
//                   child: Card(
//                     elevation: 2,
//                     margin: const EdgeInsets.symmetric(vertical: 6.0),
//                     child: Padding(
//                       padding: const EdgeInsets.all(12.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 'Time: ${record['formatted_time']}',
//                                 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                               ),
//                               SizedBox(
//                                 width: 100,
//                                 child: TextField(
//                                   controller: controller,
//                                   decoration: InputDecoration(
//                                     hintText: controller.text.isEmpty ? 'Bib #' : null,
//                                     border: OutlineInputBorder(),
//                                   ),
//                                   onChanged: (value) => _updateBib(index, value),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 8),
//                           if (record['name'] != null)
//                             Text('Name: ${record['name']}', style: const TextStyle(fontSize: 14)),
//                           if (record['grade'] != null)
//                             Text('Grade: ${record['grade']}', style: const TextStyle(fontSize: 14)),
//                           if (record['school'] != null)
//                             Text('School: ${record['school']}', style: const TextStyle(fontSize: 14)),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
