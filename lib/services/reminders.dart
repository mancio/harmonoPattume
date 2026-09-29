import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/gen/app_localizations.dart';
import '../models/collection.dart';
import '../ui/waste_style.dart';

/// Schedules one local notification the evening before each collection day.
class Reminders {
  Reminders._();

  static final instance = Reminders._();

  final _plugin = FlutterLocalNotificationsPlugin();
  late final tz.Location _warsaw;
  bool _ready = false;

  /// All supported municipalities are in Poland, so reminders are computed
  /// in Polish time regardless of the phone's time zone.
  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    _warsaw = tz.getLocation('Europe/Warsaw');
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, sound: true);
  }

  /// Replaces all pending reminders with ones for [events]. iOS keeps at
  /// most 64 pending notifications, so only the nearest days are scheduled;
  /// the list is refreshed every time the app loads the schedule.
  Future<void> reschedule(
    List<CollectionEvent> events, {
    required bool enabled,
    required TimeOfDay time,
    required AppLocalizations l10n,
  }) async {
    await init();
    await _plugin.cancelAll();
    if (!enabled) return;

    final byDay = groupByDay(events);
    final primaryIds = primaryTypeIds(events);
    final now = tz.TZDateTime.now(_warsaw);
    var id = 0;
    for (final entry in byDay.entries) {
      final day = entry.key.subtract(const Duration(days: 1));
      final at = tz.TZDateTime(
        _warsaw,
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
      );
      if (!at.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        id: id++,
        scheduledDate: at,
        title: l10n.reminderTitle,
        body: entry.value
            .map((t) => wasteLabelIn(l10n, t, primaryIds))
            .join(', '),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'collections',
            l10n.reminderChannel,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        // An inexact alarm is fine for an evening reminder and needs no
        // exact-alarm permission.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      if (id >= 60) break;
    }
  }
}

/// Groups events by calendar day, preserving date order and dropping
/// duplicate waste types on the same day.
Map<DateTime, List<WasteType>> groupByDay(List<CollectionEvent> events) {
  final sorted = [...events]..sort((a, b) => a.date.compareTo(b.date));
  final result = <DateTime, List<WasteType>>{};
  for (final e in sorted) {
    final list = result.putIfAbsent(e.date, () => []);
    if (!list.any((t) => t.id == e.wasteType.id)) list.add(e.wasteType);
  }
  return result;
}
