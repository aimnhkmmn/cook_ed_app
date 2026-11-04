import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CookEdApp());
}

class CookEdApp extends StatelessWidget {
  const CookEdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..initialize(),
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const MainNavigationScreen(),
      ),
    );
  }
}
