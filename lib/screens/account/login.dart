import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import 'package:xclout/backend/main_api.dart';
import 'package:xclout/backend/widgets.dart';
import 'package:xclout/screens/account/signup.dart';
import 'package:xclout/screens/homescreen/homescreen.dart';

import 'package:xclout/backend/universal_imports.dart';
import 'package:xclout/backend/globals.dart' as globals;

Map<String, TextEditingController> _formTextValues = {
  "username": TextEditingController(),
  "password": TextEditingController(),
};

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Center build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: TextFormField(
                      controller: _formTextValues["username"],
                      decoration: const InputDecoration(
                        labelText: "Username",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: TextFormField(
                      controller: _formTextValues["password"],
                      decoration: const InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                  ),
                  ElevatedButton(
                    style: myButtonStyle(),
                    onPressed: (() => _loginUser(context, navigatorKey)),
                    child: const Text("LOGIN"),
                  ),
                  TextButton(
                    child: const Text(
                      'Sign Up Instead',
                      style: TextStyle(color: Colors.blueGrey),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(
                            formToShow: SignUpForm(),
                            title: 'Sign Up',
                          ),
                        ),
                      );
                    },
                  ),
                  // Forgot login details
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'If you forgot your login details, please contact support.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _loginUser(
    BuildContext context, GlobalKey<NavigatorState> navigatorKey) async {
  final String username = _formTextValues["username"]!.text;
  final String password = _formTextValues["password"]!.text;

  final http.Response response =
      await MainApiCall().callPostEndpoint(endpoint: 'loginUser', fields: {
    "username": username,
    "password": password,
  });

  if (response.statusCode == 200) {
    // Successful login

    // Store Cookie
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? rawCookie = response.headers['set-cookie'];
    developer.log(response.headers.toString());
    if (rawCookie != null) {
      int index = rawCookie.indexOf(';');
      // Store Cookie
      await prefs.setString(
          'cookie', (index == -1) ? rawCookie : rawCookie.substring(0, index));
    }
    developer.log('New Cookie => ');
    developer.log(prefs.getString('cookie').toString());

    //Log the login Event
    FirebaseAnalytics.instance.logLogin();
    globals.isLoggedIn = true; // Set global isLoggedIn variable to true
    // Navigate to Feeds pages
    navigatorKey.currentState!.pushReplacement(
      MaterialPageRoute(
        builder: (context) => const FeedPage(title: 'XClout'),
      ),
    );
  } else if (response.statusCode == 400) {
    // Failed login
  } else {
    // Something went wrong -- major Error
    throw Exception("Failed to load Response");
  }
}
