import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img; // Add this import

Future<String> predictDigitsFromPicture(XFile picture) async {
  final url = Uri.parse('http://192.168.1.121:5001/run-find_digits');
  
  // Read the file as bytes
  final bytes = await picture.readAsBytes();
  
  // Convert the bytes to PNG format using the same method as in _getImageBytesFromInputImage
  final imgImage = img.decodeImage(bytes);
  if (imgImage == null) {
    throw Exception('Failed to decode image');
  }
  
  // Encode as PNG
  final pngBytes = img.encodePng(imgImage);

  // Create a multipart request
  var request = http.MultipartRequest('POST', url);
  request.files.add(http.MultipartFile.fromBytes('image', pngBytes, filename: 'image.png'));

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

Future<List<List<double>>> getDigitBoundingBoxes(Uint8List pictureBytes) async {
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
      .map((e) => (e as List<dynamic>).map((i) => i as double).toList())
      .toList();
    return coordinatesList;
  } else {
    print('Failed to call Python function: ${response.statusCode}');
  }
  return [];
}