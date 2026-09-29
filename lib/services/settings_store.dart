import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/collection.dart';

/// User settings, persisted with shared_preferences. Widgets listen to it to
/// rebuild when the address, language or reminder settings change.
class SettingsStore extends ChangeNotifier {
  SettingsStore(this._prefs);

  static Future<SettingsStore> load() async =>
      SettingsStore(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const _addressKey = 'address';
  static const _localeKey = 'locale';
  static const _remindersKey = 'reminders';
  static const _reminderMinutesKey = 'reminderMinutes';

  SavedAddress? get address {
    final raw = _prefs.getString(_addressKey);
    if (raw == null) return null;
    return SavedAddress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> setAddress(SavedAddress value) async {
    await _prefs.setString(_addressKey, jsonEncode(value.toJson()));
    notifyListeners();
  }

  /// Null means "follow the system language".
  Locale? get locale {
    final code = _prefs.getString(_localeKey);
    return code == null ? null : Locale(code);
  }

  Future<void> setLocale(Locale? value) async {
    if (value == null) {
      await _prefs.remove(_localeKey);
    } else {
      await _prefs.setString(_localeKey, value.languageCode);
    }
    notifyListeners();
  }

  bool get remindersEnabled => _prefs.getBool(_remindersKey) ?? true;

  Future<void> setRemindersEnabled(bool value) async {
    await _prefs.setBool(_remindersKey, value);
    notifyListeners();
  }

  /// Time of day for the evening-before reminder. Defaults to 19:00.
  TimeOfDay get reminderTime {
    final minutes = _prefs.getInt(_reminderMinutesKey) ?? 19 * 60;
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  Future<void> setReminderTime(TimeOfDay value) async {
    await _prefs.setInt(_reminderMinutesKey, value.hour * 60 + value.minute);
    notifyListeners();
  }
}
