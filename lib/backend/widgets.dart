import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class MyCORSImage {
  static const String _corsProxy = "https://corsproxy.io/?";

  const MyCORSImage();

  static Image network({required String url}) {
    final String entireUrl = _corsProxy + url;
    // if platform is web

    if (url.startsWith('data:image')) {
      String base64String = url;
      String imageData = base64String.split(',')[1];
      return Image.memory(const Base64Decoder().convert(imageData));
    }

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

class UserNameAndPost extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserNameAndPost({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(user['Username']!),
        if (user['Verified'] == 1) ...[
          if (user['ShowPost'] == 1) ...[
            Text(" - ${user['SchoolPost']}"),
          ],
          if (user['VerificationType'] == 'executive') ...[
            Icon(Icons.verified, color: Colors.amber.shade700, size: 15),
          ]
          //else if (user['VerificationType'] == 'IgSchool') ...[
          //   Icon(Icons.verified, color: Colors.amber.shade700, size: 15),
          // ]
        ]
      ],
    );
  }
}
