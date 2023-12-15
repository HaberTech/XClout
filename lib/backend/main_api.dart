import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'dart:developer' as developer;

class MainApiCall {
  late final String mainApiHostUrl; //Declared in MainApiCall
  // String mainApiHostUrl = "growing-seemingly-monkfish.ngrok-free.app";

  // static const String serverEndpointPrefix = "/api/";
  static const String serverEndpointPrefix = "/api/";
  static const String mainApiHostScheme = "http";

  MainApiCall() {
    mainApiHostUrl =
        Uri.base.host.isNotEmpty ? Uri.base.host : "192.168.43.66:8000";
  }
  Future<String> loadCookies() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cookie = prefs.getString('cookie');
    if (cookie != null) {
      return cookie;
    }
    return '';
  }

  Future<String> callEndpoint(
      {required String endpoint, required Map<String, dynamic>? fields}) async {
    // final Uri uri = Uri.parse("$mainApiHostUrl/$endpoint");
    final String finalEndpoint =
        (serverEndpointPrefix + endpoint).replaceAll(RegExp(r'(?<!:)//'), '/');
    // Remove possible occurance of // from the final endpoint;
    final Uri uri = Uri.https(mainApiHostUrl, finalEndpoint, fields);
    final http.Response response = await http.get(
      uri,
      headers: {
        if (!kIsWeb) ...{'cookie': await loadCookies()},
      },
    );
    // List<dynamic> queryResponse = [];
    if (response.statusCode == 200) {
      // queryResponse = jsonDecode(response.body);
    } else {
      developer.log(response.body);
      throw Exception("Failed to load Response");
    }
    return response.body;
  }

// The post endpoints are for sending data to the server
  Future<http.Response> callPostEndpoint(
      {required String endpoint, required Map<String, dynamic>? fields}) async {
    final String finalEndpoint =
        (serverEndpointPrefix + endpoint).replaceAll(RegExp(r'(?<!:)//'), '/');
    // Remove possible occurance of // from the final endpoint
    final Uri uri = Uri.https(mainApiHostUrl, finalEndpoint);

    final http.Response response = await http.post(
      uri,
      body: fields,
      headers: {
        if (!kIsWeb) ...{'cookie': await loadCookies()},
      },
    );
    if (response.statusCode == 200) {
      // queryResponse = jsonDecode(response.body);
    } else {
      developer.log(response.toString());
      throw Exception("Failed to load Response");
    }
    return response;
  }

  Future<Map<String, String>> signUpUser(
      {required Map<String, String> fields,
      required Uint8List schoolIdPhotoBytes,
      required Uint8List verificationPhotoBytes}) async {
    final String finalEndpoint =
        ("$serverEndpointPrefix/signUp").replaceAll(RegExp(r'(?<!:)//'), '/');
    // Remove possible occurance of // from the final endpoint;
    var uri = Uri.https(mainApiHostUrl, finalEndpoint);
    developer.log(uri.toString());
    Map<String, String> response = {};

    final http.MultipartRequest request = http.MultipartRequest('POST', uri)
      ..fields.addAll(fields)
      ..files.addAll([
        http.MultipartFile.fromBytes(
            'schoolIdPhoto', // consider using a unique name or id here
            schoolIdPhotoBytes,
            contentType: MediaType('image', 'jpeg'),
            filename: 'schoolIdPhoto'),
        http.MultipartFile.fromBytes(
          'verificationPhoto', // consider using a unique name or id here
          verificationPhotoBytes,
          contentType: MediaType('image', 'jpeg'),
          filename: 'verificationPhoto',
        )
      ]);

    final http.StreamedResponse requestResponse = await request.send();
    final String message = await requestResponse.stream.bytesToString();

    if (requestResponse.statusCode == 200) {
      developer.log('Account Created');
      response['status'] = 'success';
      response['message'] = message;
    } else if (requestResponse.statusCode == 400) {
      developer.log('Failed');
      response['status'] = 'failed';
      response['message'] = message;
    }

    if (response == {}) {
      response['status'] = 'failed';
      response['message'] = 'Contact Support as soon as possible';
    }
    return response;
  }
}

class LastViewedPost {
  static Future<bool> setLastViewedPostIds(
      {required int newestViewedPostId,
      required int oldestViewedPostId}) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final bool setNewPost =
        await preferences.setInt('newestViewedPostId', newestViewedPostId);
    final bool setOldPost =
        await preferences.setInt('oldestViewedPostId', oldestViewedPostId);
    return setNewPost && setOldPost;
  }

  static Future<Map<String, int>> getLastViewedPostIds() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final int newestViewedPostid = preferences.getInt('newestViewedPostId') ?? 0;
    final int oldestViewedPostid = preferences.getInt('oldestViewedPostId') ?? 0;
    return {
      'newestViewedPostId': newestViewedPostid,
      'oldestViewedPostId': oldestViewedPostid
    };
  }
}
