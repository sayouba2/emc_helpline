import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'providers/report_provider.dart';
import 'providers/theme_provider.dart';
import 'views/main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const EMCHelplineApp());
} 

class EMCHelplineApp extends StatelessWidget {
  const EMCHelplineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'EMC Helpline',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primaryBlue,
                primary: AppColors.primaryBlue,
                secondary: AppColors.primaryOrange,
                surface: AppColors.bgLight,
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: AppColors.bgLight,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                elevation: 0,
                iconTheme: IconThemeData(color: AppColors.primaryBlue),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primaryBlue,
                primary: AppColors.accentCyan,
                secondary: AppColors.primaryOrange,
                surface: AppColors.bgDark,
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: AppColors.bgDark,
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.bgDark,
                elevation: 0,
                iconTheme: IconThemeData(color: AppColors.accentCyan),
              ),
            ),
            home: const MainNavigationScreen(),
          );
        },
      ),
    );
  }
}
