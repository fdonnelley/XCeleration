import 'package:flutter/material.dart';

class TimingData with ChangeNotifier {
  final List<Map<String, dynamic>> _records = [];
  final List<TextEditingController> _controllers = [];
  DateTime? _startTime;

  //  List<TextEditingController> controllers = [];

  // TimingData() {
  //   records = _records; // Initialize in constructor
  //   startTime = _startTime; // Initialize in constructor
  //   controllers = _controllers; // Initialize in constructor
  // }


  // set startTime(DateTime? value) {
  //   _startTime = value;
  // }

  List<Map<String, dynamic>> get records => _records;
  DateTime? get startTime => _startTime;
  List<TextEditingController> get controllers => _controllers;
  // List<Map<String, dynamic>> records; // Add this line
  // DateTime? startTime; // Add this line
  // List<TextEditingController> controllers; // Add this line

  void addRecord(Map<String, dynamic> record) {
    _records.add(record);
    notifyListeners();
  }
  
  void addController(TextEditingController controller) {
    _controllers.add(controller);
    notifyListeners();
  }

  void changeStartTime(DateTime? time) {
    _startTime = time;
    notifyListeners();
  }

  void clearRecords() {
    _records.clear();
    notifyListeners();
  }
}