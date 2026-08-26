import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/backend/firebase_backend.dart';
import 'core/constants/app_colors.dart';
import 'core/storage/settings_store.dart';
import 'models/submission_outcome.dart';
import 'models/tracking_outcome.dart';
import 'l10n/app_localizations.dart';
import 'providers/report_provider.dart';
import 'views/components/foreground_update_banner.dart';
import 'views/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Le paysage était autorisé sans être dessiné : la mise en page vise le
  // portrait, et laisser tourner l'écran offrait une version qu'on n'a jamais
  // soignée plutôt que rien.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  // Before the first frame: the wizard needs to know where a report goes the
  // moment it can be filled in. In debug this may come back `null`, which runs
  // the app on its local simulation — see `initializeBackend`.
  final backend = await initializeBackend();

  runApp(
    EMCHelplineApp(
      settings: await SettingsStore.open(),
      submitter: backend.submitter,
      lookup: backend.lookup,
      updates: backend.updates,
    ),
  );
}

class EMCHelplineApp extends StatelessWidget {
  const EMCHelplineApp({
    super.key,
    required this.settings,
    this.submitter,
    this.lookup,
    this.updates,
  });

  final SettingsStore settings;

  /// How a report leaves the device, and how one is read back. `null` uses the
  /// built-in simulation, which is what the widget tests run on — they must not
  /// touch the network.
  final ReportSubmitter? submitter;
  final ReportLookup? lookup;

  /// Messages arriving while the app is open. `null` in tests and when no
  /// backend is configured — nothing then listens, and nothing breaks.
  final Stream<void>? updates;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          ReportProvider(settings, submitter: submitter, lookup: lookup),
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
            // Autour de l'application entière : une mise à jour peut arriver
            // quoi que fasse l'utilisateur, y compris en plein signalement.
            builder: (context, child) => ForegroundUpdateBanner(
              updates: updates ?? const Stream<void>.empty(),
              child: child ?? const SizedBox.shrink(),
            ),
            home: const SplashGate(),
          );
        },
      ),
    );
  }
}
