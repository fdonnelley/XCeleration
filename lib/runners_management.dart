import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:race_timing_app/file_processing.dart';
import 'package:race_timing_app/database_helper.dart';

class RunnersManagement extends StatefulWidget {
  const RunnersManagement({super.key});

  @override
  State<RunnersManagement> createState() => _RunnersManagementState();
}

class _RunnersManagementState extends State<RunnersManagement> {
  final _nameController = TextEditingController();
  final _gradeController = TextEditingController();
  final _schoolController = TextEditingController();
  final _bibController = TextEditingController();
  final _deleteBibController = TextEditingController();


  List<Map<String, dynamic>> _runners = []; // To store runners fetched from the database.

  @override
  void initState() {
    super.initState();
    _loadRunners(); // Load runners when the widget is initialized.
  }

  Future<void> _loadRunners() async {
    // Fetch runners from the database
    final runners = await DatabaseHelper.instance.fetchAllRunners();
    setState(() {
      _runners = runners; // Update the state with the fetched runners
    });
  }

  Future<void> _addRunner() async {
    final name = _nameController.text;
    final grade = int.tryParse(_gradeController.text);
    final school = _schoolController.text;
    final bib = _bibController.text;

    if (name.isEmpty || grade == null || school.isEmpty || bib.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    await DatabaseHelper.instance.insertRunner(name, grade, school, bib);
    _nameController.clear();
    _gradeController.clear();
    _schoolController.clear();
    _bibController.clear();
    _loadRunners();
    Navigator.of(context).pop(); // Close the popup
  }

  Future<void> _deleteRunner() async {
    final bib = _deleteBibController.text;

    if (bib.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Bib Number')),
      );
      return;
    }

    await DatabaseHelper.instance.deleteRunner(bib);
    _deleteBibController.clear();
    _loadRunners();
    Navigator.of(context).pop(); // Close the popup
  }

  Future<void> _showAddRunnerPopup(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Runner'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(_nameController, 'Full Name'),
              _buildTextField(_gradeController, 'Grade', isNumeric: true),
              _buildTextField(_schoolController, 'School'),
              _buildTextField(_bibController, 'Bib Number', isNumeric: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addRunner,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteRunnerPopup(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Runner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(_deleteBibController, 'Enter Bib Number', isNumeric: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _deleteRunner,
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSpreadsheet() async {
    await processSpreadsheet();
    _loadRunners(); // Reload runners after processing spreadsheet
  }

  Future<void> confirmDeleteAllRunners(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete all runners?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper.instance.deleteAllRunners();
      _loadRunners();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Runners Management')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(5.0), // Padding around the button
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double fontSize = constraints.maxWidth * 0.12; // Scalable font size
                        return ElevatedButton(
                          onPressed: () => _showAddRunnerPopup(context),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(0, constraints.maxWidth * 0.5), // Button height scales
                            padding: EdgeInsets.symmetric(vertical: 5.0),
                          ),
                          child: Text('Add Runner',
                            style: TextStyle(fontSize: fontSize),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(5.0), // Padding around the button
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double fontSize = constraints.maxWidth * 0.12; // Scalable font size
                        return ElevatedButton(
                          onPressed: () => _showDeleteRunnerPopup(context),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(0, constraints.maxWidth * 0.5), // Button height scales
                            padding: EdgeInsets.symmetric(vertical: 5.0),
                          ),
                          child: Text('Delete Runner',
                            style: TextStyle(fontSize: fontSize),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(5.0), // Padding around the button
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double fontSize = constraints.maxWidth * 0.10;
                        return ElevatedButton(
                          onPressed: _loadSpreadsheet,
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(0, constraints.maxWidth * 0.5),
                            padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
                          ),
                          child: Text(
                            'Load Spreadsheet',
                            style: TextStyle(fontSize: fontSize),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //   children: [
            //     ElevatedButton(
            //       onPressed: () => _showAddRunnerPopup(context),
            //       child: const Text('Add Runner'),
            //     ),
            //     ElevatedButton(
            //       onPressed: () => _showDeleteRunnerPopup(context),
            //       child: const Text('Delete Runner'),
            //     ),
            //     ElevatedButton(
            //       onPressed: _loadSpreadsheet,
            //       child: const Text('Load Spreadsheet'),
            //     ),
            //   ],
            // ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _runners.length,
                itemBuilder: (context, index) {
                  final runner = _runners[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(runner['bib_number']),
                      ),
                      title: Text(runner['name']),
                      subtitle: Text(
                        'School: ${runner['school']} | Grade: ${runner['grade'].toString()}',
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

  Widget _buildTextField(TextEditingController controller, String hintText,
      {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Colors.blue, width: 2.0),
          ),
        ),
      ),
    );
  }
}