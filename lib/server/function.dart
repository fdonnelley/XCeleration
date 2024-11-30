import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart'; // Add this import


Future<void> predict_digits_from_picture(XFile picture) async {
  final url = Uri.parse('http://127.0.0.1:5000/run-predict_digits_from_picture');
  final image = convertToCv2FromXFile(picture);
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'image': image}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print('Result from Python: ${data['result']}');
  } else {
    print('Failed to call Python function: ${response.statusCode}');
  }
}

convertToCv2FromXFile(XFile picture) {
  // do this later
  return picture;
}