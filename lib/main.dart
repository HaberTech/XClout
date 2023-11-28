import 'package:xclout/backend/universal_imports.dart';
// import 'package:xclout/screens/chat/chat.dart';
import 'package:xclout/screens/homescreen/homescreen.dart';

void main() {
  runApp(const XClout());
}

class XClout extends StatelessWidget {
  const XClout({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'XClout',
      // home: const ChatsPage(),
      home: const HomeScreen(),
      // Use system theme
      themeMode: ThemeMode.dark,
      // themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,

      theme: CustomAppThemeData.lightTheme(),
      darkTheme: CustomAppThemeData.darkTheme(),
    );
  }
}
