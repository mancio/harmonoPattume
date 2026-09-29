/// Common model shared by every schedule source, so screens and reminders
/// don't depend on where the data comes from.
library;

/// Waste categories the app knows how to label and colour. Sources map their
/// own ids onto these; anything unknown becomes [WasteKind.other].
enum WasteKind {
  mixed,
  bio,
  paper,
  plastics,
  glass,
  bulky,
  hazardous,
  ewaste,
  garden,
  tree,
  textile,
  metal,
  leaves,
  other,
}

class WasteType {
  const WasteType({required this.id, required this.name, required this.kind});

  final String id;

  /// Name as given by the source (usually Polish). Shown when [kind] is
  /// [WasteKind.other].
  final String name;
  final WasteKind kind;
}

class CollectionEvent {
  const CollectionEvent({required this.date, required this.wasteType});

  /// Local calendar day of the pickup (time part is always midnight).
  final DateTime date;
  final WasteType wasteType;
}

/// An option in one of the address pickers (locality or street).
class PlaceOption {
  const PlaceOption({required this.id, required this.name});

  final String id;
  final String name;
}

/// The address the user picked, persisted between launches.
class SavedAddress {
  const SavedAddress({
    required this.source,
    required this.municipality,
    required this.localityId,
    required this.localityName,
    required this.streetId,
    required this.streetName,
    required this.number,
  });

  /// Id of the [ScheduleSource] that serves this address, e.g. `kiedyodpady`.
  final String source;

  /// Municipality slug inside the source, e.g. `wieliczka`.
  final String municipality;
  final String localityId;
  final String localityName;

  /// Empty when the locality has no named streets.
  final String streetId;
  final String streetName;
  final String number;

  String get label => [
    localityName,
    if (streetName.isNotEmpty) streetName,
    if (number.isNotEmpty) number,
  ].join(', ');

  Map<String, String> toJson() => {
    'source': source,
    'municipality': municipality,
    'localityId': localityId,
    'localityName': localityName,
    'streetId': streetId,
    'streetName': streetName,
    'number': number,
  };

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
    source: json['source'] as String,
    municipality: json['municipality'] as String,
    localityId: json['localityId'] as String,
    localityName: json['localityName'] as String,
    streetId: json['streetId'] as String? ?? '',
    streetName: json['streetName'] as String? ?? '',
    number: json['number'] as String? ?? '',
  );
}
