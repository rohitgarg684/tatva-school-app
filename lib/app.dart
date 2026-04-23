import 'package:flutter/material.dart';
import 'shared/theme/theme.dart';
import 'features/splash/splash_screen.dart';

class TatvaApp extends StatelessWidget {
  const TatvaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tatva Academy',
      debugShowCheckedModeBanner: false,
      theme: TatvaTheme.light,
      darkTheme: TatvaTheme.dark,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
