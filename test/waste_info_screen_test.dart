import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmono_pattume/l10n/gen/app_localizations.dart';
import 'package:harmono_pattume/models/collection.dart';
import 'package:harmono_pattume/ui/waste_info_screen.dart';

void main() {
  testWidgets('explains Akcja Liść in Italian', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: WasteInfoScreen(
          type: const WasteType(
            id: 'l',
            name: 'Akcja Liść',
            kind: WasteKind.leaves,
          ),
          label: 'Raccolta foglie',
          upcoming: [DateTime(2026, 11, 9)],
        ),
      ),
    );

    expect(find.text('Nome nel calendario ufficiale: Akcja Liść'), findsOne);
    expect(find.text('Foglie cadute'), findsOne);
    expect(find.text('Cosa non ci va'), findsOne);
  });

  test('every waste kind has a description in every language', () async {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      for (final kind in WasteKind.values) {
        expect(wasteInfo(l10n, kind).description, isNotEmpty);
      }
    }
  });
}
