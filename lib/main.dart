import 'package:flutter/material.dart';
import 'screens/timing_screen.dart';
import 'runners_management.dart';
import 'screens/bib_number_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Race Timing App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Race Timing App'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.timer), text: 'Time a Race'),
              Tab(icon: Icon(Icons.numbers), text: 'Record Bib Numbers'),
              Tab(icon: Icon(Icons.person), text: 'Runner Data'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TimingScreen(),
            BibNumberScreen(),
            RunnersManagement(),
          ],
        ),
      ),
    );
  }
}
