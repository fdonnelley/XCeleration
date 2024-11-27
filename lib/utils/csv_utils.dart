import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

class CsvUtils {
  
  // Generate CSV content based on the provided data
  static String generateCsvContent({
    required bool isHeadToHead,
    required List<Map<String, dynamic>> teamResults,
    required List<Map<String, dynamic>> individualResults,
  }) {
    List<List<String>> rows = [];
    if (isHeadToHead) {
      // Head-to-Head Results
      rows.add(['Team 1', 'Score', 'Time', 'Team 2', 'Score', 'Time']);
      for (var matchup in teamResults) {
        rows.add([
          matchup['team1']['school'],
          '${matchup['team1']['score']}',
          matchup['team1']['times'],
          matchup['team2']['school'],
          '${matchup['team2']['score']}',
          matchup['team2']['times'],
        ]);
      }
    } else {
      // Overall Results
      rows.add(['Place', 'School', 'Score', 'Scorers', 'Times']);
      for (var team in teamResults) {
        rows.add([
          '${team['place']}',
          team['school'],
          '${team['score']}',
          team['scorers'],
          team['times'],
        ]);
      }
    }
    // Individual Results
    rows.add(['Place', 'Name', 'Grade', 'School', 'Time']);
    for (var runner in individualResults) {
      rows.add([
        '${runner['position']}',
        runner['name'],
        '${runner['grade']}',
        runner['school'],
        runner['formatted_time'],
      ]);
    }
    return const ListToCsvConverter().convert(rows);
  }

  // Save the generated CSV content using file_saver (cross-platform)
  static Future<String> saveCsvWithFileSaver(String filename, String csvContent) async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      
      if (selectedDirectory != null) {
        // Create the file in the selected directory
        final file = File('$selectedDirectory/$filename');
        
        // Write the content to the file
        await file.writeAsString(csvContent);

        print('File saved at: ${file.path}');
        return file.path;
      } else {
        print('Directory selection was canceled.');
        return '';
      }
    } catch (e) {
      throw Exception('Failed to save CSV with FileSaver: $e');
    }
  }
}
