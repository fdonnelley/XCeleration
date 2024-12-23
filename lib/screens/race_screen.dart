// import 'dart:io';
import 'package:flutter/material.dart';
import 'timing_screen.dart';
import '../runners_management.dart';
// import 'bib_number_screen.dart';
// import 'package:provider/provider.dart';
import '../database_helper.dart';
import '../models/race.dart';
import 'race_info_screen.dart';
import 'results_screen.dart';

class RaceScreen extends StatefulWidget {
  final Race race;

  const RaceScreen({
    Key? key, 
    required this.race,
  }) : super(key: key);

  @override
  _RaceScreenState createState() => _RaceScreenState();
}

class _RaceScreenState extends State<RaceScreen> {
  late Race race;

  @override
  void initState() {
    super.initState();
    race = widget.race;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: DatabaseHelper.instance.getRaceResults(race.race_id),
      builder: (context, snapshot) {
        final showResults = snapshot.hasData && snapshot.data!.isNotEmpty && snapshot.data!.every((runner) => runner['bib_number'] != null);
        List<Tab> tabs = showResults ? [
            Tab(icon: Icon(Icons.info_outline), text: 'Race Info'),
            Tab(icon: Icon(Icons.timer), text: 'Results'),
            Tab(icon: Icon(Icons.person), text: 'Runner Data'),
          ] : [
            Tab(icon: Icon(Icons.info_outline), text: 'Race Info'),
            Tab(icon: Icon(Icons.timer), text: 'Time Race'),
            Tab(icon: Icon(Icons.person), text: 'Runner Data'),
          ];
        return DefaultTabController(
          length: tabs.length, 
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Race Timing App'),
              bottom: TabBar(
                tabs: tabs,
              ),
            ),
            body: TabBarView(
                children: [
                    RaceInfoScreen(raceId: race.race_id),
                    if (showResults) ResultsScreen(raceId: race.race_id) else TimingScreen(raceId: race.race_id),
                    // BibNumberScreen (),
                    RunnersManagement(raceId: race.race_id),
                ],
            ),
          ),
        );
      } 
    );
  }
}
