import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/foundation.dart';

import '../l10n/gen/app_localizations.dart';

/// Builds the all-day calendar event for one collection day. [labels] are
/// the waste types collected that day, as shown on the schedule.
@visibleForTesting
Event collectionDayEvent({
  required DateTime date,
  required List<String> labels,
  required String address,
  required AppLocalizations l10n,
}) {
  final day = DateTime(date.year, date.month, date.day);
  return Event(
    title: l10n.calendarEventTitle(labels.join(', ')),
    description: l10n.calendarEventDescription,
    location: address,
    startDate: day,
    endDate: DateTime(day.year, day.month, day.day + 1),
    allDay: true,
  );
}

/// Opens the phone's calendar app (Google Calendar on most Android phones)
/// with the collection day prefilled, so the user only has to tap Save.
/// Returns false when no calendar app can take the event.
Future<bool> addCollectionDayToCalendar({
  required DateTime date,
  required List<String> labels,
  required String address,
  required AppLocalizations l10n,
}) => Add2Calendar.addEvent2Cal(
  collectionDayEvent(date: date, labels: labels, address: address, l10n: l10n),
);
