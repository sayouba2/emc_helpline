import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/storage/settings_store.dart';
import 'l10n/app_localizations.dart';
import 'providers/report_provider.dart';
import 'views/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(EMCHelplineApp(settings: await SettingsStore.open()));
}

class EMCHelplineApp extends StatelessWidget {
  const EMCHelplineApp({super.key, required this.settings});

  final SettingsStore settings;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportProvider(settings),
      child: Consumer<ReportProvider>(
        builder: (context, reportProvider, _) {
          return MaterialApp(
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            debugShowCheckedModeBanner: false,
            // `null` follows the device language; the first supported locale
            // (French) is the fallback. Setting the locale here also gives the
            // whole app — pushed routes included — the right text direction,
            // which a manual `Directionality` around the home screen did not.
            locale: reportProvider.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            // The app is light-only on purpose: a dark variant existed but was
            // unreachable and left two thirds of the screens unreadable.
            themeMode: ThemeMode.light,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primaryBlue,
                primary: AppColors.primaryBlue,
                secondary: AppColors.primaryOrange,
                surface: AppColors.bg,
              ),
              scaffoldBackgroundColor: AppColors.bg,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                elevation: 0,
                iconTheme: IconThemeData(color: AppColors.primaryBlue),
              ),
            ),
            home: const SplashGate(),
          );
        },
      ),
    );
  }
}
