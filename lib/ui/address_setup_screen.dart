import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/collection.dart';
import '../services/settings_store.dart';
import '../sources/schedule_source.dart';

/// Step-by-step address picker: municipality, locality, street, number.
/// Mirrors the form on kiedyodpady.pl so users see the same names.
class AddressSetupScreen extends StatefulWidget {
  const AddressSetupScreen({super.key, required this.settings});

  final SettingsStore settings;

  @override
  State<AddressSetupScreen> createState() => _AddressSetupScreenState();
}

class _AddressSetupScreenState extends State<AddressSetupScreen> {
  Municipality _municipality = supportedMunicipalities.first;
  late ScheduleSource _source = sourceFor(_municipality.source);

  List<PlaceOption>? _localities;
  PlaceOption? _locality;
  List<PlaceOption>? _streets;
  PlaceOption? _street;
  List<String>? _numbers;
  String? _number;
  final _numberController = TextEditingController();

  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _numberController.addListener(() => setState(() {}));
    _run(() async {
      final localities = await _source.localities(_municipality.slug);
      setState(() => _localities = localities);
    });
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() task) async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      await task();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _pickMunicipality(Municipality m) {
    setState(() {
      _municipality = m;
      _source = sourceFor(m.source);
      _localities = null;
      _pickLocalityReset();
    });
    _run(() async {
      final localities = await _source.localities(m.slug);
      setState(() => _localities = localities);
    });
  }

  void _pickLocalityReset() {
    _locality = null;
    _streets = null;
    _street = null;
    _numbers = null;
    _number = null;
    _numberController.clear();
  }

  void _pickLocality(PlaceOption locality) {
    setState(() {
      _pickLocalityReset();
      _locality = locality;
    });
    _run(() async {
      final streets = await _source.streets(_municipality.slug, locality.id);
      setState(() => _streets = streets);
    });
  }

  void _pickStreet(PlaceOption street) {
    setState(() {
      _street = street;
      _numbers = null;
      _number = null;
    });
    _run(() async {
      final numbers = await _source.numbers(
        _municipality.slug,
        _locality!.id,
        street.id,
      );
      setState(() {
        _numbers = numbers;
        if (numbers.length == 1) _number = numbers.single;
      });
    });
  }

  bool get _noStreets => _streets != null && _streets!.isEmpty;

  String get _chosenNumber =>
      _noStreets ? _numberController.text.trim() : (_number ?? '');

  bool get _canSave =>
      _locality != null &&
      (_noStreets
          ? _chosenNumber.isNotEmpty
          : _street != null && _number != null);

  Future<void> _save() async {
    await widget.settings.setAddress(
      SavedAddress(
        source: _source.id,
        municipality: _municipality.slug,
        localityId: _locality!.id,
        localityName: _locality!.name,
        streetId: _street?.id ?? '',
        streetName: _street?.name ?? '',
        number: _chosenNumber,
      ),
    );
    if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.setupTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.setupIntro),
          const SizedBox(height: 16),
          DropdownButtonFormField<Municipality>(
            initialValue: _municipality,
            decoration: InputDecoration(labelText: l10n.municipality),
            items: [
              for (final m in supportedMunicipalities)
                DropdownMenuItem(value: m, child: Text(m.name)),
            ],
            onChanged: (m) => m == null ? null : _pickMunicipality(m),
          ),
          const SizedBox(height: 12),
          _PickerField(
            label: l10n.locality,
            value: _locality?.name,
            options: _localities,
            onPicked: _pickLocality,
          ),
          if (_locality != null && !_noStreets) ...[
            const SizedBox(height: 12),
            _PickerField(
              label: l10n.street,
              value: _street?.name,
              options: _streets,
              onPicked: _pickStreet,
            ),
          ],
          if (_street != null && _numbers != null) ...[
            const SizedBox(height: 12),
            _PickerField(
              label: l10n.houseNumber,
              value: _number,
              options: [for (final n in _numbers!) PlaceOption(id: n, name: n)],
              onPicked: (o) => setState(() => _number = o.id),
            ),
          ],
          if (_noStreets) ...[
            const SizedBox(height: 12),
            Text(l10n.noStreetsHint),
            TextField(
              controller: _numberController,
              decoration: InputDecoration(labelText: l10n.houseNumber),
            ),
          ],
          const SizedBox(height: 16),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_failed)
            ListTile(
              leading: const Icon(Icons.error_outline),
              title: Text(l10n.errorLoading),
              trailing: TextButton(
                onPressed: () => _locality == null
                    ? _pickMunicipality(_municipality)
                    : _street == null
                    ? _pickLocality(_locality!)
                    : _pickStreet(_street!),
                child: Text(l10n.retry),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _canSave ? _save : null,
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}

/// A read-only field that opens a searchable list of [options].
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.options,
    required this.onPicked,
  });

  final String label;
  final String? value;
  final List<PlaceOption>? options;
  final ValueChanged<PlaceOption> onPicked;

  @override
  Widget build(BuildContext context) {
    final enabled = options != null && options!.isNotEmpty;
    return InkWell(
      onTap: enabled
          ? () async {
              final picked = await showModalBottomSheet<PlaceOption>(
                context: context,
                isScrollControlled: true,
                builder: (_) => _SearchList(options: options!),
              );
              if (picked != null) onPicked(picked);
            }
          : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          enabled: enabled,
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(value ?? ''),
      ),
    );
  }
}

class _SearchList extends StatefulWidget {
  const _SearchList({required this.options});

  final List<PlaceOption> options;

  @override
  State<_SearchList> createState() => _SearchListState();
}

class _SearchListState extends State<_SearchList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final shown = widget.options
        .where((o) => o.name.toLowerCase().contains(q))
        .toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: AppLocalizations.of(context).search,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: shown.length,
                itemBuilder: (context, i) => ListTile(
                  title: Text(shown[i].name),
                  onTap: () => Navigator.of(context).pop(shown[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
