import 'package:flutter/material.dart';
import 'package:race_timing_app/utils/time_formatter.dart';
import 'package:race_timing_app/utils/csv_utils.dart';

class ResultsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> runners;

    const ResultsScreen({super.key, required this.runners});

  @override
  ResultsScreenState createState() => ResultsScreenState();
}

class ResultsScreenState extends State<ResultsScreen> {
  bool _isHeadToHead = false;

  @override
  Widget build(BuildContext context) {
    final individualResults = _calculateIndividualResults();
    final teamResults = _isHeadToHead
        ? _calculateHeadToHeadTeamResults()
        : _calculateOverallTeamResults();

    return Scaffold(
      // appBar: AppBar(title: const Text('Team Results')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Team Results',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      const Text('Head-to-Head View'),
                      Switch(
                        value: _isHeadToHead,
                        onChanged: (value) {
                          setState(() {
                            _isHeadToHead = value;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),

              // Download Button
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => downloadCsv(teamResults, individualResults),
                  icon: const Icon(Icons.download),
                  label: const Text('Download CSV Results', style: TextStyle(fontSize: 20)),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              // Overall or Head-to-Head Results
              if (!_isHeadToHead) ...[
                const Text(
                  'Overall Team Results',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: teamResults.length,
                  itemBuilder: (context, index) {
                    final team = teamResults[index];
                    return _buildTeamResultCard(team);
                  },
                ),
              ] else ...[
                const Text(
                  'Head-to-Head Results',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: teamResults.length,
                  itemBuilder: (context, index) {
                    final matchup = teamResults[index];
                    return _buildHeadToHeadCard(matchup);
                  },
                ),
              ],
              const Divider(),
              // Individual Results Section
              const Text(
                'Individual Results',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: individualResults.length,
                itemBuilder: (context, index) {
                  final runner = individualResults[index];
                  return ListTile(
                    title: Text('${index + 1}. ${runner['name']} (${runner['school']})'),
                    subtitle: Text(
                      'Time: ${runner['formatted_time']} | Grade: ${runner['grade']} | Bib: ${runner['bib_number']}',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  // Card for Overall Results
  Widget _buildTeamResultCard(Map<String, dynamic> team) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${team['place']}. ${team['school']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${team['score']} Points',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Scorers: ${team['scorers']}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Times: ${team['times']}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Card for Head-to-Head Results
  Widget _buildHeadToHeadCard(Map<String, dynamic> matchup) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Matchup Header
            Text(
              '${matchup['team1']?['school'] ?? 'Unknown'} vs ${matchup['team2']?['school'] ?? 'Unknown'}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Team 1 Result
            _buildTeamComparison(
              rank: '1',
              team: matchup['team1'],
            ),

            const Divider(color: Colors.grey),

            // Team 2 Result
            _buildTeamComparison(
              rank: '2',
              team: matchup['team2'],
            ),
          ],
        ),
      ),
    );
  }

  // Shared Team Comparison Widget
  Widget _buildTeamComparison({required String rank, required Map<String, dynamic> team}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$rank. ${team['school']}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${team['score']} Points',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Scorers: ${team['scorers']}',
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          'Times: ${team['times']}',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
  
  Future<void> downloadCsv(List<Map<String, dynamic>> teamResults, List<Map<String, dynamic>> individualResults) async {
    try {
      // Generate CSV content
      final csvContent = CsvUtils.generateCsvContent(
        isHeadToHead: _isHeadToHead,
        teamResults: teamResults,
        individualResults: individualResults
      );

      // Define the filename
      final filename = 'race_results.csv';

      // Save CSV file
      final filepath = await CsvUtils.saveCsvWithFileSaver(filename, csvContent);

      if (filepath != '') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('CSV downloaded at $filepath'),
        ));
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No location selected for download'),
        ));
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to download CSV: $e'),
      ));
    }
  }

  List<Map<String, dynamic>> _calculateIndividualResults() {
    final sortedRunners = List<Map<String, dynamic>>.from(widget.runners);
    sortedRunners.sort((a, b) => a['time'].compareTo(b['time']));
    return sortedRunners;
  }

  List<Map<String, dynamic>> _calculateOverallTeamResults() {
    // Normal team scoring logic (all teams considered together)
    return _calculateTeamResults(widget.runners);
  }

  List<Map<String, dynamic>> _calculateHeadToHeadTeamResults() {
    final schools = widget.runners.map((r) => r['school']).toSet().toList();
    final headToHeadResults = <Map<String, dynamic>>[];

    for (int i = 0; i < schools.length; i++) {
      for (int j = i + 1; j < schools.length; j++) {
        final schoolA = schools[i];
        final schoolB = schools[j];
        final filteredRunners = widget.runners
            .where((r) => r['school'] == schoolA || r['school'] == schoolB)
            .toList();

        final teamResults = _calculateTeamResults(filteredRunners);

        // Add the results for the two teams being compared as a group
        final matchup = {
          'team1': teamResults.firstWhere((team) => team['school'] == schoolA, orElse: () => {}),
          'team2': teamResults.firstWhere((team) => team['school'] == schoolB, orElse: () => {}),
        };

        headToHeadResults.add(matchup);
      }
    }

    return headToHeadResults;
  }

  List<Map<String, dynamic>> _calculateTeamResults(List<Map<String, dynamic>> allRunners) {
    final Map<String, List<Map<String, dynamic>>> teams = {};

    // Group runners by school
    for (final runner in allRunners) {
      final school = runner['school'];
      if (!teams.containsKey(school)) {
        teams[school] = [];
      }
      teams[school]!.add(runner);
    }

    // Calculate scores for each team
    final teamScores = <Map<String, dynamic>>[];
    int place = 1;

    teams.forEach((school, runners) {
      if (runners.length < 5) return; // Skip teams with fewer than 5 runners

      // Sort runners by time
      runners.sort((a, b) => a['time'].compareTo(b['time']));

      // Calculate team score and other stats
      final top5 = runners.take(5).toList();
      final sixthRunner = runners.length > 5 ? allRunners.indexOf(runners[5]) + 1 : null;
      final seventhRunner = runners.length > 6 ? allRunners.indexOf(runners[6]) + 1 : null;
      final score = top5.fold<int>(0, (sum, runner) => sum + allRunners.indexOf(runner) + 1); // Calculate position based on time
      final scorers = '${top5.map((runner) => '${allRunners.indexOf(runner) + 1}').join('+')} ${sixthRunner != null ? '($sixthRunner' : ''}${seventhRunner != null ? '+$seventhRunner' : ''}${sixthRunner != null || seventhRunner != null ? ')' : ''}';
      // final times = runners.map((runner) => '${runner['time']}').toList();
      final split = top5.last['time'] - top5.first['time'];
      final formattedSplit = formatDuration(split);
      final avgTime = top5.fold(Duration.zero, (sum, runner) => sum + runner['time']) ~/ 5;
      String formattedAverage = formatDuration(avgTime);

      teamScores.add({
        'place': place++,
        'school': school,
        'score': score,
        'scorers': scorers,
        'times': '$formattedSplit 1-5 Split | $formattedAverage Avg',
        'sixth_runner': sixthRunner,
        'seventh_runner': seventhRunner,
      });
    });

    // Sort teams by score (and apply tiebreakers if necessary)
    teamScores.sort((a, b) {
      if (a['score'] != b['score']) return a['score'].compareTo(b['score']);
      if (a['sixth_runner'] != b['sixth_runner']) return a['sixth_runner']!.compareTo(b['sixth_runner']!);
      if (a['seventh_runner'] != b['seventh_runner']) return a['seventh_runner']!.compareTo(b['seventh_runner']!);
      return 0;
    });

    return teamScores;
  }
}
