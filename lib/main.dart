import 'package:xclout/backend/universal_imports.dart';
// import 'package:xclout/screens/chat/chat.dart';
import 'package:xclout/screens/homescreen/homescreen.dart';

import 'package:firebase_core/firebase_core.dart';
// Firebse analytics
import 'package:firebase_analytics/firebase_analytics.dart';
// Firebase options
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const XClout());
}

class XClout extends StatelessWidget {
  const XClout({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XClout',
      // home: const ChatsPage(),
      home: const HomeScreen(),
      // Use system theme
      themeMode: ThemeMode.dark,
      // themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: CustomAppThemeData.lightTheme(),
      darkTheme: CustomAppThemeData.darkTheme(),
      navigatorKey: navigatorKey,
      navigatorObservers: <NavigatorObserver>[
        FirebaseAnalyticsObserver(
          analytics: FirebaseAnalytics.instance,
        )
      ],
    );
  }
}