import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/collection.dart';
import 'schedule_source.dart';

/// Unofficial JSON API behind kiedyodpady.pl (mOdpady / mMieszkaniec by
/// Rekord Mobile). The `Origin` header selects the municipality, e.g.
/// `https://wieliczka.kiedyodpady.pl`. Same calls as the Home Assistant
/// "Waste Collection Schedule" source `kiedyodpady_pl`.
class KiedyOdpadySource implements ScheduleSource {
  KiedyOdpadySource({http.Client? client}) : _client = client ?? http.Client();

  static const sourceId = 'kiedyodpady';
  static final _base = Uri.parse('https://api.kiedyodpady.pl/public/');

  final http.Client _client;
  final _wasteTypes = <String, Map<String, WasteType>>{};

  @override
  String get id => sourceId;

  Map<String, String> _headers(String municipality) => {
    'Origin': 'https://$municipality.kiedyodpady.pl',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<dynamic> _get(String municipality, String path) async {
    final response = await _client.get(
      _base.resolve(path),
      headers: _headers(municipality),
    );
    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode != 200) {
      throw ScheduleSourceException(
        'kiedyodpady.pl answered ${response.statusCode}',
      );
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  List<PlaceOption> _places(dynamic json) => [
    for (final item in json as List)
      PlaceOption(
        id: item['id'] as String,
        name: (item['extendedName'] ?? item['name'] ?? item['id']) as String,
      ),
  ]..sort((a, b) => polishSortKey(a.name).compareTo(polishSortKey(b.name)));

  @override
  Future<List<PlaceOption>> localities(String municipality) async =>
      _places(await _get(municipality, 'territory/localities'));

  @override
  Future<List<PlaceOption>> streets(
    String municipality,
    String localityId,
  ) async => _places(
    await _get(
      municipality,
      'territory/localities/${Uri.encodeComponent(localityId)}/streets',
    ),
  );

  @override
  Future<List<String>> numbers(
    String municipality,
    String localityId,
    String streetId,
  ) async {
    final json = await _get(
      municipality,
      'territory/localities/${Uri.encodeComponent(localityId)}'
      '/addresses/${Uri.encodeComponent(streetId)}',
    );
    return [for (final n in json as List) n.toString()];
  }

  Future<Map<String, WasteType>> _types(String municipality) async {
    final cached = _wasteTypes[municipality];
    if (cached != null) return cached;
    final json = await _get(municipality, 'waste-types') as List;
    final types = {
      for (final item in json)
        if (item['id'] != null)
          item['id'] as String: WasteType(
            id: item['id'] as String,
            name: (item['name'] ?? item['id']) as String,
            kind: kindForIcon(item['icon'] as String?),
          ),
    };
    return _wasteTypes[municipality] = types;
  }

  @override
  Future<List<CollectionEvent>> schedule(
    SavedAddress address, {
    required DateTime from,
    required DateTime to,
  }) async {
    final types = await _types(address.municipality);
    final response = await _client.post(
      _base.resolve('schedules/find'),
      headers: _headers(address.municipality),
      body: jsonEncode({
        'from': _day(from),
        'to': _day(to),
        'queries': [
          {
            'localityId': address.localityId,
            'streetId': address.streetId,
            'number': address.number,
            'propertyType': '',
            'buildingType': '',
          },
        ],
      }),
    );
    final json = _decode(response) as Map<String, dynamic>;
    final events = <CollectionEvent>[];
    for (final occurrence in (json['occurrences'] as List? ?? const [])) {
      final what = occurrence['what'] as String? ?? '';
      final when = DateTime.parse(occurrence['when'] as String);
      events.add(
        CollectionEvent(
          date: DateTime(when.year, when.month, when.day),
          wasteType:
              types[what] ??
              WasteType(id: what, name: what, kind: WasteKind.other),
        ),
      );
    }
    events.sort((a, b) => a.date.compareTo(b.date));
    return events;
  }

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Maps the platform's icon slug to a [WasteKind].
  static WasteKind kindForIcon(String? icon) => switch (icon) {
    'mixed' => WasteKind.mixed,
    'bio' => WasteKind.bio,
    'paper' => WasteKind.paper,
    'plastics' => WasteKind.plastics,
    'glass' => WasteKind.glass,
    'bulky' || 'constructionWaste' => WasteKind.bulky,
    'hazardous' || 'battery' => WasteKind.hazardous,
    'ewaste' => WasteKind.ewaste,
    'garden' => WasteKind.garden,
    'tree' => WasteKind.tree,
    'textile' => WasteKind.textile,
    'metal' => WasteKind.metal,
    _ => WasteKind.other,
  };
}
