import '../models/collection.dart';
import 'kiedyodpady_source.dart';

/// A provider of waste collection schedules. Each data platform (or city
/// with its own format) gets one implementation; the rest of the app only
/// talks to this interface.
abstract class ScheduleSource {
  String get id;

  Future<List<PlaceOption>> localities(String municipality);

  Future<List<PlaceOption>> streets(String municipality, String localityId);

  /// House numbers accepted for a street. May contain a catch-all entry
  /// such as `pozostałe` ("all other numbers").
  Future<List<String>> numbers(
    String municipality,
    String localityId,
    String streetId,
  );

  Future<List<CollectionEvent>> schedule(
    SavedAddress address, {
    required DateTime from,
    required DateTime to,
  });
}

/// A municipality the app offers in the picker.
class Municipality {
  const Municipality({
    required this.source,
    required this.slug,
    required this.name,
  });

  final String source;
  final String slug;
  final String name;
}

const supportedMunicipalities = [
  Municipality(
    source: KiedyOdpadySource.sourceId,
    slug: 'wieliczka',
    name: 'Gmina Wieliczka',
  ),
];

ScheduleSource sourceFor(String id) {
  switch (id) {
    case KiedyOdpadySource.sourceId:
      return KiedyOdpadySource();
  }
  throw ArgumentError.value(id, 'id', 'Unknown schedule source');
}

const _polishLetters = {
  'ą': 'a~',
  'ć': 'c~',
  'ę': 'e~',
  'ł': 'l~',
  'ń': 'n~',
  'ó': 'o~',
  'ś': 's~',
  'ź': 'z~',
  'ż': 'z~~',
};

/// Sort key that orders Polish names alphabetically (Ś right after S, not
/// after Z as plain code-unit comparison would).
String polishSortKey(String name) =>
    name.toLowerCase().split('').map((c) => _polishLetters[c] ?? c).join();

const _plainLetters = {
  'ą': 'a',
  'ć': 'c',
  'ę': 'e',
  'ł': 'l',
  'ń': 'n',
  'ó': 'o',
  'ś': 's',
  'ź': 'z',
  'ż': 'z',
};

/// Lowercase text without Polish diacritics, so searching "sledz" finds
/// "Śledziejowice" on keyboards without Polish letters.
String foldForSearch(String text) =>
    text.toLowerCase().split('').map((c) => _plainLetters[c] ?? c).join();

class ScheduleSourceException implements Exception {
  ScheduleSourceException(this.message);

  final String message;

  @override
  String toString() => message;
}
