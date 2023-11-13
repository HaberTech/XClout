import 'package:xclout/backend/universal_imports.dart';
import 'package:xclout/screens/account/signup.dart';
import 'package:xclout/screens/chat/chat.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XClout',
      // home: const FeedPage(title: 'XClout'),
      home: const SignUpScreen(formToShow: SignUpForm()),
      // Use system theme
      themeMode: ThemeMode.system,
      // themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,

      theme: CustomAppThemeData.lightTheme(),
      darkTheme: CustomAppThemeData.darkTheme(),
    );
  }
}
