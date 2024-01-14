import 'dart:convert';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:xclout/backend/globals.dart' as globals;
import 'package:xclout/backend/universal_imports.dart' show navigatorKey;
import 'package:xclout/screens/account/signup.dart';

class MyCORSImage {
  static const String _corsProxy = "https://corsproxy.io/?";

  const MyCORSImage();

  static Image networkOrData({required String url, bool? useCors}) {
    if (url.startsWith('data:image')) {
      String base64String = url;
      String imageData = base64String.split(',')[1];
      return Image.memory(const Base64Decoder().convert(imageData));
    }

    if (kIsWeb && (useCors != null && useCors)) {
      // if platform is web and useCors is true
      final String entireUrl = _corsProxy + url;
      return Image.network(entireUrl, headers: const {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, HEAD",
        "X-REQUESTED-WITH": "*",
      });
    } else {
      // if platform is not web or useCors is false
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

// Dialog if user is not logged in
Future<void> notLoggedInDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title:
            const Text('You are not logged in', style: TextStyle(fontSize: 20)),
        content: const SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Please log in to continue'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('OK', style: TextStyle(fontSize: 20)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}


void continueElseLogin({required Function ifLoggedIn}) async {
  final BuildContext localContext = navigatorKey.currentState!.context;
  final bool isLoggedIn =
      globals.isLoggedIn; // Check if logged in using global file
  if (isLoggedIn) {
    ifLoggedIn();
  } else {
    if (localContext.mounted) {
      showDialog(
          context: localContext,
          builder: (context) {
            return AlertDialog(
              title: const Text('You are not logged in!',
                  style: TextStyle(fontSize: 20)),
              content: const Text(
                'Login to like, comment, share, give you opinion and be able to post and message others.',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Later!', style: TextStyle(fontSize: 20)),
                  onPressed: () {
                    FirebaseAnalytics.instance
                        .logEvent(name: 'dialog_dismiss_login');
                    Navigator.of(localContext).pop();
                  },
                ),
                TextButton(
                  child: const Text('LOGIN', style: TextStyle(fontSize: 20)),
                  onPressed: () {
                    FirebaseAnalytics.instance.logEvent(name: 'dialog_login');
                    Navigator.of(localContext).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const SignUpScreen(
                          formToShow: SignUpForm(),
                          title: "Sign Up",
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          });
    }
  }
}