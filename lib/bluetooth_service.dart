import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothService {
  // final FlutterBluePlus _flutterBlue = FlutterBluePlus();

  Future<bool> isBluetoothOn() async {
    try {
      // Use FlutterBluePlus.adapterState instead of deprecated members
      final state = await FlutterBluePlus.adapterState.first;
      checkBluetoothState();
      // Check if the adapter state is "on"
      return state == BluetoothAdapterState.on;
    } catch (e) {
      throw Exception('Failed to check Bluetooth state: $e');
    }
  }

  Future<void> checkBluetoothState() async {
    try {
      final state = await FlutterBluePlus.adapterState.first;
      print('Bluetooth State on macOS: $state');
      if (state == BluetoothAdapterState.unavailable) {
        print('Bluetooth hardware is unavailable on this macOS device.');
      } else if (state == BluetoothAdapterState.off) {
        print('Bluetooth is off. Please turn it on.');
      } else if (state == BluetoothAdapterState.on) {
        print('Bluetooth is on.');
      }
    } catch (e) {
      print('Error checking Bluetooth state: $e');
    }
  }

  Stream<List<BluetoothDevice>> getAvailableDevices() async* {
    // Start scanning with a timeout of 10 seconds
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    await for (final scanResult in FlutterBluePlus.scanResults) {
      final devices = scanResult.map((result) => result.device).toList();
      if (devices.isNotEmpty) {
        yield devices;
      } else {
        yield []; // Yield empty if no devices found
      }
    }

    // Optionally, you can also stop the scan here if necessary, in case no devices are found
    // FlutterBluePlus.stopScan();
  }


  Future<BluetoothDevice> connectToDevice(BluetoothDevice device) async {
    await device.connect();
    return device;
  }

  Future<void> disconnectDevice(BluetoothDevice device) async {
    await device.disconnect();
  }

  Future<void> sendData(BluetoothDevice device, List<int> data) async {
    final services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.write) {
          await characteristic.write(data);
          return;
        }
      }
    }
    throw Exception('No writable characteristic found');
  }

  Future<List<int>> receiveData(BluetoothDevice device) async {
    final services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.read) {
          return await characteristic.read();
        }
      }
    }
    throw Exception('No readable characteristic found');
  }
}
