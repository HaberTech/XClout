import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class MyCORSImage {
  static const String _corsProxy = "https://corsproxy.io/?";

  const MyCORSImage();

  static Image network({required String url}) {
    final String entireUrl = _corsProxy + url;
    // if platform is web

    if (kIsWeb) {
      return Image.network(entireUrl, headers: const {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, HEAD",
        "X-REQUESTED-WITH": "*",
      });
    } else {
      return Image.network(url);
    }
  }
}

ButtonStyle myButtonStyle() {
  return ButtonStyle(
    backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
    foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
  );
}
