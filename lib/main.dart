import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'services/ai_service.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const AuraAIApp());
}

class AuraAIApp extends StatelessWidget {
  const AuraAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => ChatService()),
        Provider(create: (_) => AIService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'AuraAI',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
