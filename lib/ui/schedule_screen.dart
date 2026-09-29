import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/collection.dart';
import '../services/reminders.dart';
import '../services/settings_store.dart';
import '../sources/schedule_source.dart';
import 'settings_screen.dart';
import 'waste_style.dart';

/// Upcoming collections for the saved address, one card per day.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, required this.settings});

  final SettingsStore settings;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  Future<List<CollectionEvent>>? _events;
  List<CollectionEvent>? _loaded;
  String? _loadedFor;
  String? _remindersFor;

  @override
  void initState() {
    super.initState();
    if (widget.settings.remindersEnabled) {
      Reminders.instance.requestPermission();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncWithSettings();
  }

  @override
  void didUpdateWidget(ScheduleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncWithSettings();
  }

  /// Refetches when the address changes, and reschedules reminders when the
  /// reminder settings or the language change.
  void _syncWithSettings() {
    final key = widget.settings.address?.toJson().toString();
    if (key != _loadedFor) {
      _loadedFor = key;
      _load();
      return;
    }
    if (_loaded != null && _reminderKey() != _remindersFor) {
      _reschedule(_loaded!);
    }
  }

  String _reminderKey() => [
    widget.settings.remindersEnabled,
    widget.settings.reminderTime,
    Localizations.localeOf(context),
  ].join('|');

  void _reschedule(List<CollectionEvent> events) {
    _remindersFor = _reminderKey();
    Reminders.instance.reschedule(
      events,
      enabled: widget.settings.remindersEnabled,
      time: widget.settings.reminderTime,
      l10n: AppLocalizations.of(context),
    );
  }

  void _load() {
    final address = widget.settings.address!;
    final today = DateUtils.dateOnly(DateTime.now());
    final future = sourceFor(
      address.source,
    ).schedule(address, from: today, to: today.add(const Duration(days: 365)));
    future.then((events) {
      _loaded = events;
      if (mounted) _reschedule(events);
    }, onError: (_) {});
    setState(() {
      _events = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final address = widget.settings.address!;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/icon/icon_round.png', width: 36),
            ),
            const SizedBox(width: 12),
            Text(l10n.appTitle),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsScreen(settings: widget.settings),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _load();
          await _events?.catchError((_) => <CollectionEvent>[]);
        },
        child: FutureBuilder<List<CollectionEvent>>(
          future: _events,
          builder: (context, snapshot) {
            final header = ListTile(
              leading: const Icon(Icons.home_outlined),
              title: Text(address.label),
              subtitle: Text(l10n.upcoming),
            );
            if (snapshot.hasError) {
              return ListView(
                children: [
                  header,
                  ListTile(
                    leading: const Icon(Icons.error_outline),
                    title: Text(l10n.errorLoading),
                    trailing: TextButton(
                      onPressed: _load,
                      child: Text(l10n.retry),
                    ),
                  ),
                ],
              );
            }
            if (!snapshot.hasData) {
              return ListView(
                children: [
                  header,
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            }
            final days = groupByDay(snapshot.data!).entries.toList();
            final primaryIds = primaryTypeIds(snapshot.data!);
            return ListView.builder(
              itemCount: days.length + 2,
              itemBuilder: (context, i) {
                if (i == 0) return header;
                if (i == days.length + 1) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      days.isEmpty ? l10n.noCollections : l10n.dataSource,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }
                final day = days[i - 1];
                return _DayCard(
                  date: day.key,
                  types: day.value,
                  primaryIds: primaryIds,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.date,
    required this.types,
    required this.primaryIds,
  });

  final DateTime date;
  final List<WasteType> types;
  final Set<String> primaryIds;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = DateUtils.dateOnly(DateTime.now());
    final diff = date.difference(today).inDays;
    final relative = switch (diff) {
      0 => l10n.today,
      1 => l10n.tomorrow,
      _ => null,
    };
    final formatted = DateFormat.MMMMEEEEd(locale).format(date);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: diff <= 1 ? Theme.of(context).colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              relative == null ? formatted : '$relative · $formatted',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final t in types)
                  WasteChip(type: t, label: wasteLabelIn(l10n, t, primaryIds)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
