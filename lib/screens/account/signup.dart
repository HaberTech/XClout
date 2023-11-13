import 'dart:io';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:xclout/backend/main_api.dart';
import 'package:xclout/backend/widgets.dart';
import 'package:xclout/screens/chat/chat.dart';

Map<String, TextEditingController> _formTextValues = {
  "username": TextEditingController(),
  "email": TextEditingController(),
  "phoneNumber": TextEditingController(),
  "password": TextEditingController(),
  "confirmPassword": TextEditingController(),
  "fullName": TextEditingController(),
};
Map<String, String> _formImageValues = {};
String _selectedSchool = "";

class SignUpScreen extends StatelessWidget {
  final Widget formToShow;

  const SignUpScreen({super.key, required this.formToShow});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign Up"),
      ),
      body: formToShow,
    );
  }
}

class SignUpForm extends StatelessWidget {
  const SignUpForm({super.key});

  @override
  Widget build(BuildContext context) {
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
                      controller: _formTextValues["phoneNumber"],
                      decoration: const InputDecoration(
                        labelText: "Phone Number",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: TextFormField(
                      controller: _formTextValues["email"],
                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        String pattern =
                            r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+';
                        RegExp regex = RegExp(pattern);
                        if (!regex.hasMatch(value!)) {
                          return 'Enter a valid email address';
                        } else {
                          return null;
                        }
                      },
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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: TextFormField(
                      controller: _formTextValues["confirmPassword"],
                      decoration: const InputDecoration(
                        labelText: "Confirm Password",
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                  ),
                  ElevatedButton(
                    style: myButtonStyle(),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(
                              formToShow: SignUpFormSchoolDetails()),
                        ),
                      );
                    },
                    child: const Text("Continue"),
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

class SignUpFormSchoolDetails extends StatelessWidget {
  const SignUpFormSchoolDetails({super.key});

  @override
  Widget build(BuildContext context) {
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
                      controller: _formTextValues["fullName"],
                      decoration: const InputDecoration(
                        labelText: "Your Full Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: FutureBuilder<DropdownButtonFormField<String>>(
                      future: _schoolPicker(),
                      builder: (BuildContext context,
                          AsyncSnapshot<DropdownButtonFormField<String>>
                              snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator(); // Show a loading spinner while waiting
                        } else if (snapshot.hasError) {
                          return Text(
                              'Error: ${snapshot.error}'); // Show error message if something went wrong
                        } else {
                          return snapshot
                              .data!; // Show the dropdown menu when data is loaded
                        }
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: SelectImage(
                      header: "Picture of School Id",
                      button1Text: "Take Picture",
                      button2Text: "Pick Image from Gallery",
                      valueIndex: "schoolId",
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: SelectImage(
                      header: "Your Selfie For Verification",
                      button1Text: "Take Picture",
                      valueIndex: "userPhoto",
                    ),
                  ),
                  ElevatedButton(
                    style: myButtonStyle(),
                    onPressed: () {
                      developer.log(_formTextValues.toString());
                      signUpUser(context);
                    },
                    child: const Text("Sign Up"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<DropdownButtonFormField<String>> _schoolPicker() async {
    final List<dynamic> response =
        await MainApiCall().callEndpoint("getListOfSchools", null);
    final List<Map<String, String>> schools =
        response.map<Map<String, String>>((item) {
      final Map<String, dynamic> dynamicMap = item as Map<String, dynamic>;
      return dynamicMap.map((key, value) => MapEntry(key, value.toString()));
    }).toList();

    return DropdownButtonFormField<String>(
      value: schools[0]['SchoolId'],
      items:
          schools.map<DropdownMenuItem<String>>((Map<String, String> school) {
        return DropdownMenuItem<String>(
          value: school['SchoolId'],
          child: Text(school['SchoolName']!),
        );
      }).toList(),
      onChanged: (String? newValue) {
        // Do something with the selected school
        final selectedSchool =
            schools.firstWhere((school) => school['SchoolId'] == newValue);
        developer.log("Real value is $selectedSchool");
        _selectedSchool = selectedSchool['SchoolId']!;
      },
      decoration: const InputDecoration(
        labelText: "Select an option",
        border: OutlineInputBorder(),
      ),
    );
  }
}

class SelectImage extends StatefulWidget {
  final String header;
  final String button1Text;
  final String? button2Text;
  final String valueIndex;

  const SelectImage({
    super.key,
    required this.header,
    required this.button1Text,
    required this.valueIndex,
    this.button2Text,
  });

  @override
  State<SelectImage> createState() => _SelectImageState();
}

class _SelectImageState extends State<SelectImage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;

  Future<void> getImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);

    if (image == null) return;
    setState(() {
      _image = image;
      _formImageValues[widget.valueIndex] = _image!.path;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get image from camera or gallery
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white, // Set border color
          width: 1.0, // Set border width
        ),
        borderRadius: const BorderRadius.all(
            Radius.circular(10.0)), // Set rounded corner radius
      ),
      child: Column(
        children: [
          Text(widget.header),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            ElevatedButton(
              onPressed: () => getImage(ImageSource.camera),
              style: myButtonStyle(),
              child: Text(widget.button1Text),
            ),
            if (widget.button2Text != null)
              ElevatedButton(
                onPressed: () => getImage(ImageSource.gallery),
                style: myButtonStyle(),
                child: Text(widget.button2Text!),
              ),
          ]),
          if (_image != null)
            Image.file(
              File(_image!.path),
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          // ...
        ],
      ),
    );
  }
}

void signUpUser(BuildContext context) async {
  final Map<String, String> fields = {};

  fields["userName"] = _formTextValues["username"]!.text;
  fields["email"] = _formTextValues["email"]!.text;
  fields["phoneNumber"] = _formTextValues["phoneNumber"]!.text;
  fields["password"] = _formTextValues["password"]!.text;
  fields["confirmPassword"] = _formTextValues["confirmPassword"]!.text;
  fields["fullName"] = _formTextValues["fullName"]!.text;
  fields["schoolId"] = _selectedSchool;

  final String schoolIdImage = _formImageValues["schoolId"]!;
  final String userPhoto = _formImageValues["userPhoto"]!;

  final bool accountCreated = await MainApiCall().signUpUser(
    fields: fields,
    schoolIdPhotoPath: schoolIdImage,
    verificationPhotoPath: userPhoto,
  );

  if (accountCreated) {
    // Navigate to the next screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatScreen(),
      ),
    );
  } else {
    // Show an error message
  }
}
