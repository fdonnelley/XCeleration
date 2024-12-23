import 'package:flutter/material.dart';

toRace(Map<String, dynamic> race) {
    double distanceValue = race['distance'] is double 
      ? race['distance'] 
      : double.parse(race['distance'].toString());
    return Race(
        raceId: race['race_id'],
        raceName: race['race_name'],
        raceDate: DateTime.parse(race['race_date']),
        location: race['location'],
        distance: distanceValue,
    );
}

class Race {
  final int raceId;
  final String raceName;
  final DateTime raceDate;
  final String location;
  final double distance;

  Race({
    required this.raceId,
    required this.raceName,
    required this.raceDate,
    required this.location,
    required this.distance,
  });

  // You can add getters if needed
  String get race_name => raceName;
  String get race_location => location;
  DateTime get race_date => raceDate;
  double get race_distance => distance;
  int get race_id => raceId;
}