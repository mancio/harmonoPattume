import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmono_pattume/l10n/gen/app_localizations.dart';
import 'package:harmono_pattume/services/calendar_export.dart';

void main() {
  test('collection day becomes an all-day event for that day', () {
    final event = collectionDayEvent(
      date: DateTime(2026, 10, 26),
      labels: ['Carta', 'Plastica e metalli'],
      address: 'Śledziejowice (wieś), 558',
      l10n: lookupAppLocalizations(const Locale('it')),
    );
    expect(event.title, 'Raccolta rifiuti: Carta, Plastica e metalli');
    expect(event.location, 'Śledziejowice (wieś), 558');
    expect(event.allDay, isTrue);
    expect(event.startDate, DateTime(2026, 10, 26));
    expect(event.endDate, DateTime(2026, 10, 27));
  });

  test('event title is translated', () {
    final event = collectionDayEvent(
      date: DateTime(2026, 12, 31),
      labels: ['Szkło'],
      address: 'x',
      l10n: lookupAppLocalizations(const Locale('pl')),
    );
    expect(event.title, 'Wywóz odpadów: Szkło');
    expect(event.endDate, DateTime(2027, 1, 1));
  });
}
