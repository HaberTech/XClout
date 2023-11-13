import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

String mainApiHostUrl = "http://192.168.43.66:8000";

class MainApiCall {
  Future<List<dynamic>> callEndpoint(String endpoint, String? fields) async {
    final Uri uri = Uri.parse("$mainApiHostUrl/$endpoint");
    final http.Response response = await http.get(uri);
    List<dynamic> queryResponse = [];
    if (response.statusCode == 200) {
      queryResponse = jsonDecode(response.body);
    } else {
      throw Exception("Failed to load Response");
    }
    print(response.body);
    return queryResponse;
  }

  Future<bool> signUpUser(
      {required Map<String, String> fields,
      required String schoolIdPhotoPath,
      required String verificationPhotoPath}) async {
    var uri = Uri.parse("$mainApiHostUrl/signUp");

    var request = http.MultipartRequest('POST', uri)
      ..fields.addAll(fields)
      ..files.addAll([
        await http.MultipartFile.fromPath(
          'schoolIdPhoto', // consider using a unique name or id here
          schoolIdPhotoPath,
          contentType: MediaType('application', 'x-tar'),
        ),
        await http.MultipartFile.fromPath(
          'verificationPhoto', // consider using a unique name or id here
          verificationPhotoPath,
          contentType: MediaType('application', 'x-tar'),
        )
      ]);

    var response = await request.send();

    if (response.statusCode == 200) {
      print('Account Created');
      return true;
    } else {
      print('Failed');
      return false;
    }
  }
}
