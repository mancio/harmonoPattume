import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/gen/app_localizations.dart';
import 'services/reminders.dart';
import 'services/settings_store.dart';
import 'ui/address_setup_screen.dart';
import 'ui/schedule_screen.dart';
import 'ui/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsStore.load();
  await Reminders.instance.init();
  runApp(HarmonoPattumeApp(settings: settings));
}

class HarmonoPattumeApp extends StatefulWidget {
  const HarmonoPattumeApp({super.key, required this.settings});

  final SettingsStore settings;

  @override
  State<HarmonoPattumeApp> createState() => _HarmonoPattumeAppState();
}

class _HarmonoPattumeAppState extends State<HarmonoPattumeApp> {
  bool _welcomeDone = false;

  SettingsStore get settings => widget.settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        theme: ThemeData(colorSchemeSeed: Colors.green),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.green,
          brightness: Brightness.dark,
        ),
        locale: settings.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // The backdrop keeps the cross-fade from showing black in between.
        home: Builder(
          builder: (context) => ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: !_welcomeDone
                  ? WelcomeScreen(
                      onDone: () => setState(() {
                        _welcomeDone = true;
                      }),
                    )
                  : settings.address == null
                  ? AddressSetupScreen(settings: settings)
                  : ScheduleScreen(settings: settings),
            ),
          ),
        ),
      ),
    );
  }
}
