import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:harmono_pattume/models/collection.dart';
import 'package:harmono_pattume/services/reminders.dart';
import 'package:harmono_pattume/sources/kiedyodpady_source.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _address = SavedAddress(
  source: KiedyOdpadySource.sourceId,
  municipality: 'wieliczka',
  localityId: 'loc-1',
  localityName: 'Śledziejowice',
  streetId: 'str-1',
  streetName: 'Śledziejowice',
  number: '558',
);

http.Response _json(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  late List<http.Request> requests;

  KiedyOdpadySource source() => KiedyOdpadySource(
    client: MockClient((request) async {
      requests.add(request);
      switch (request.url.path) {
        case '/public/territory/localities':
          return _json([
            {'id': 'loc-2', 'extendedName': 'Wieliczka (miasto)'},
            {'id': 'loc-1', 'extendedName': 'Śledziejowice'},
          ]);
        case '/public/territory/localities/loc-1/addresses/str-1':
          return _json(['558', 'pozostałe']);
        case '/public/waste-types':
          return _json([
            {'id': 'w-bio', 'name': 'Bioodpady', 'icon': 'bio'},
            {'id': 'w-mix', 'name': 'Zmieszane', 'icon': 'mixed'},
            {'id': 'w-odd', 'name': 'Popiół', 'icon': 'ash'},
          ]);
        case '/public/schedules/find':
          return _json({
            'occurrences': [
              {'when': '2026-10-02', 'what': 'w-mix'},
              {'when': '2026-10-01T00:00:00', 'what': 'w-bio'},
              {'when': '2026-10-02', 'what': 'w-odd'},
            ],
          });
      }
      return http.Response('not found', 404);
    }),
  );

  setUp(() => requests = []);

  test('sends the municipality as Origin and sorts localities', () async {
    final localities = await source().localities('wieliczka');

    expect(localities.map((l) => l.name), [
      'Śledziejowice',
      'Wieliczka (miasto)',
    ]);
    expect(
      requests.single.headers['Origin'],
      'https://wieliczka.kiedyodpady.pl',
    );
  });

  test('lists house numbers for a street', () async {
    expect(await source().numbers('wieliczka', 'loc-1', 'str-1'), [
      '558',
      'pozostałe',
    ]);
  });

  test('fetches the schedule and maps waste types', () async {
    final events = await source().schedule(
      _address,
      from: DateTime(2026, 9, 29),
      to: DateTime(2027, 9, 29),
    );

    final find = requests.last;
    expect(find.method, 'POST');
    expect(jsonDecode(find.body), {
      'from': '2026-09-29',
      'to': '2027-09-29',
      'queries': [
        {
          'localityId': 'loc-1',
          'streetId': 'str-1',
          'number': '558',
          'propertyType': '',
          'buildingType': '',
        },
      ],
    });

    expect(events.first.date, DateTime(2026, 10, 1));
    expect(events.first.wasteType.kind, WasteKind.bio);
    expect(events.map((e) => e.wasteType.kind), [
      WasteKind.bio,
      WasteKind.mixed,
      WasteKind.other,
    ]);
    expect(events.last.wasteType.name, 'Popiół');
  });

  test('reports HTTP errors', () {
    final failing = KiedyOdpadySource(
      client: MockClient((_) async => http.Response('', 403)),
    );
    expect(failing.localities('wieliczka'), throwsA(isA<Exception>()));
  });

  test('groups events by day without duplicates', () {
    const bio = WasteType(id: 'b', name: 'Bio', kind: WasteKind.bio);
    const glass = WasteType(id: 'g', name: 'Szkło', kind: WasteKind.glass);
    final grouped = groupByDay([
      CollectionEvent(date: DateTime(2026, 10, 3), wasteType: glass),
      CollectionEvent(date: DateTime(2026, 10, 1), wasteType: bio),
      CollectionEvent(date: DateTime(2026, 10, 1), wasteType: bio),
      CollectionEvent(date: DateTime(2026, 10, 1), wasteType: glass),
    ]);

    expect(grouped.keys, [DateTime(2026, 10, 1), DateTime(2026, 10, 3)]);
    expect(grouped[DateTime(2026, 10, 1)]!.map((t) => t.id), ['b', 'g']);
  });

  test('saved address survives a JSON round trip', () {
    final copy = SavedAddress.fromJson(_address.toJson());
    expect(copy.toJson(), _address.toJson());
    expect(copy.label, 'Śledziejowice, Śledziejowice, 558');
  });
}
