import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart'; // Add this import


Future<String> predictDigitsFromPicture(XFile picture) async {
  final url = Uri.parse('http://192.168.1.121:5001/run-predict_digits_from_picture');

  // Create a multipart request
  var request = http.MultipartRequest('POST', url);
  request.files.add(await http.MultipartFile.fromPath('image', picture.path));

  // Send the request
  var response = await request.send();

  // Read and process the response
  if (response.statusCode == 200) {
    final responseBody = await response.stream.bytesToString();
    final data = jsonDecode(responseBody);
    print('Result from Python: $data');
    return data['number'];
  } else {
    print('Failed to call Python function: ${response.statusCode}');
  }
  return '';
}

Future<List<List<int>>> get_digit_bounding_boxes(Uint8List pictureBytes) async {
  final url = Uri.parse('http://192.168.1.121:5001/run-get_boxes');

  // Create a multipart request
  var request = http.MultipartRequest('POST', url);
  request.files.add(http.MultipartFile.fromBytes('image', pictureBytes, filename: 'image.png'));

  // Send the request
  var response = await request.send();

  // Read and process the response
  if (response.statusCode == 200) {
    final responseBody = await response.stream.bytesToString();
    final data = jsonDecode(responseBody);
    print('Result from Python: $data');
    
    final coordinatesList = (data['coordinates'] as List<dynamic>)
      .map((e) => (e as List<dynamic>).map((i) => i as int).toList())
      .toList();
    return coordinatesList;
  } else {
    print('Failed to call Python function: ${response.statusCode}');
  }
  return [];
}