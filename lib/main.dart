import 'package:flutter/material.dart';
import 'helpers/session.dart';
import 'services/auth_service.dart';
import 'services/session.dart' as app_session;
import 'ui/bottom_navigation.dart';
import 'ui/home/chat_page.dart';
import 'ui/home/home_page.dart';
import 'ui/rencana_page.dart';
import 'ui/user_page.dart';
import 'ui/welcome_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final loggedIn = await app_session.Session.isLoggedIn();
  Session.isLoggedIn = loggedIn;

  if (loggedIn) {
    try {
      await AuthService.syncActivePlan();
    } catch (_) {
      // Tetap lanjut membuka aplikasi meski server sedang offline
    }
  }

  runApp(MyApp(isLoggedIn: loggedIn));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.isLoggedIn = false});

  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'wedding+',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Montserrat'),
      home: isLoggedIn ? const HomePage() : const WelcomePage(),
      routes: {
        AppRoutes.home: (context) => const HomePage(),
        AppRoutes.rencana: (context) => const RencanaPage(),
        AppRoutes.chat: (context) => const ChatPage(),
        AppRoutes.user: (context) => const UserPage(),
      },
    );
  }
}