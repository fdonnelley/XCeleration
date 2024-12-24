import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img; // Add this import

Future<Map<String, dynamic>> predictDigitsFromPicture(XFile picture) async {
  final url = Uri.parse('http://192.168.1.121:5001/run-find_digits');
  
  // // Rotate the image 90 degrees clockwise
  // final rotatedImage = img.copyRotate(img.decodeImage(await picture.readAsBytes())!, angle: 90);
  // final rotatedBytes = Uint8List.fromList(img.encodeJpg(rotatedImage));
  


  // Read the file as bytes
  final bytes = await picture.readAsBytes();
  
  // Get the width and height of the image
  final imgImage = img.decodeImage(bytes);
  if (imgImage == null) {
    throw Exception('Failed to decode image');
  }
  final width = imgImage.width;
  final height = imgImage.height;

  print("width: $width, height: $height");
  // print("bytes type: ${bytes.runtimeType}");
  
  // // Convert the bytes to PNG format using the same method as in _getImageBytesFromInputImage
  // final imgImage = img.decodeImage(bytes);
  // if (imgImage == null) {
  //   throw Exception('Failed to decode image');
  // }
  
  // // Encode as PNG
  // final pngBytes = img.encodePng(imgImage);
  // print("pngBytes type: ${pngBytes.runtimeType}");

  // Create a multipart request
  var request = http.MultipartRequest('POST', url);
  request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'image.png'));
  request.fields['width'] = width.toString();
  request.fields['height'] = height.toString();

  // Send the request
  var response = await request.send();

  // Read and process the response
  if (response.statusCode == 200) {
    final responseBody = await response.stream.bytesToString();
    final data = jsonDecode(responseBody);
    print('Result from Python: $data');
    return data;
  } else {
    print('Failed to call Python function: ${response.statusCode}');
  }
  return {'number': '', 'confidences': <double>[]};
}

Future<List<List<double>>> getDigitBoundingBoxes(Uint8List pictureBytes, int width, int height) async {
  final url = Uri.parse('http://192.168.1.121:5001/run-get_boxes');

  // Create a multipart request
  var request = http.MultipartRequest('POST', url);
  request.files.add(http.MultipartFile.fromBytes('image', pictureBytes, filename: 'image.png'));
  request.fields['width'] = width.toString();
  request.fields['height'] = height.toString();
  
  // Send the request
  final stopwatch = Stopwatch()..start();
  var response = await request.send();
  stopwatch.stop(); // Stop timing
  print('Request took: ${stopwatch.elapsedMilliseconds} ms');

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