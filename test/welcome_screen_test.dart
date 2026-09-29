import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmono_pattume/l10n/gen/app_localizations.dart';
import 'package:harmono_pattume/ui/welcome_screen.dart';

Widget _app(Locale locale, VoidCallback onDone) => MaterialApp(
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: WelcomeScreen(onDone: onDone),
);

void main() {
  testWidgets('moves on by itself after 3 seconds', (tester) async {
    var done = 0;
    await tester.pumpWidget(_app(const Locale('it'), () => done++));

    expect(find.text('Benvenuto!'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2900));
    expect(done, 0);
    await tester.pump(const Duration(milliseconds: 200));
    expect(done, 1);
  });

  testWidgets('shows the welcome in Polish', (tester) async {
    await tester.pumpWidget(_app(const Locale('pl'), () {}));
    expect(find.text('Witaj!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('a tap skips ahead only once', (tester) async {
    var done = 0;
    await tester.pumpWidget(_app(const Locale('en'), () => done++));
    await tester.tap(find.text('Welcome!'));
    await tester.pump(const Duration(seconds: 4));
    expect(done, 1);
  });
}
