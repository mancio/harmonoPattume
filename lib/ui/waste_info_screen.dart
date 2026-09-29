import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/collection.dart';
import 'waste_style.dart';

/// Explains one waste type: what it is, what goes in and what doesn't, plus
/// its next collection dates for the saved address.
class WasteInfoScreen extends StatelessWidget {
  const WasteInfoScreen({
    super.key,
    required this.type,
    required this.label,
    required this.upcoming,
  });

  final WasteType type;

  /// The name shown on the schedule chip.
  final String label;

  /// Upcoming collection days for this type, in date order.
  final List<DateTime> upcoming;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final info = wasteInfo(l10n, type.kind);
    final color = wasteColor(type.kind);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: color,
                child: Icon(
                  wasteIcon(type.kind),
                  size: 34,
                  color:
                      ThemeData.estimateBrightnessForColor(color) ==
                          Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(label, style: text.headlineSmall)),
            ],
          ),
          if (type.name != label) ...[
            const SizedBox(height: 12),
            Text(
              l10n.infoScheduleName(type.name),
              style: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 16),
          Text(info.description, style: text.bodyLarge),
          if (info.goesIn.isNotEmpty)
            _Section(
              title: l10n.infoGoesIn,
              items: info.goesIn,
              icon: Icons.check_circle,
              iconColor: Colors.green.shade700,
            ),
          if (info.doesNotGoIn.isNotEmpty)
            _Section(
              title: l10n.infoDoesNotGoIn,
              items: info.doesNotGoIn,
              icon: Icons.cancel,
              iconColor: Colors.red.shade700,
            ),
          if (upcoming.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(l10n.infoNext, style: text.titleMedium),
            const SizedBox(height: 4),
            for (final day in upcoming.take(5))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(DateFormat.MMMMEEEEd(locale).format(day)),
              ),
          ],
          const SizedBox(height: 24),
          Text(l10n.infoDisclaimer, style: text.bodySmall),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final List<String> items;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 20, color: iconColor),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class WasteInfo {
  const WasteInfo(this.description, this.goesIn, this.doesNotGoIn);

  final String description;
  final List<String> goesIn;
  final List<String> doesNotGoIn;
}

WasteInfo wasteInfo(AppLocalizations l10n, WasteKind kind) {
  final (desc, yes, no) = switch (kind) {
    WasteKind.mixed => (l10n.infoMixed, l10n.infoMixedYes, l10n.infoMixedNo),
    WasteKind.bio => (l10n.infoBio, l10n.infoBioYes, l10n.infoBioNo),
    WasteKind.paper => (l10n.infoPaper, l10n.infoPaperYes, l10n.infoPaperNo),
    WasteKind.plastics => (
      l10n.infoPlastics,
      l10n.infoPlasticsYes,
      l10n.infoPlasticsNo,
    ),
    WasteKind.glass => (l10n.infoGlass, l10n.infoGlassYes, l10n.infoGlassNo),
    WasteKind.bulky => (l10n.infoBulky, l10n.infoBulkyYes, l10n.infoBulkyNo),
    WasteKind.hazardous => (
      l10n.infoHazardous,
      l10n.infoHazardousYes,
      l10n.infoHazardousNo,
    ),
    WasteKind.ewaste => (
      l10n.infoEwaste,
      l10n.infoEwasteYes,
      l10n.infoEwasteNo,
    ),
    WasteKind.garden => (
      l10n.infoGarden,
      l10n.infoGardenYes,
      l10n.infoGardenNo,
    ),
    WasteKind.tree => (l10n.infoTree, l10n.infoTreeYes, l10n.infoTreeNo),
    WasteKind.textile => (
      l10n.infoTextile,
      l10n.infoTextileYes,
      l10n.infoTextileNo,
    ),
    WasteKind.metal => (l10n.infoMetal, l10n.infoMetalYes, l10n.infoMetalNo),
    WasteKind.leaves => (
      l10n.infoLeaves,
      l10n.infoLeavesYes,
      l10n.infoLeavesNo,
    ),
    WasteKind.other => (l10n.infoOther, l10n.infoOtherYes, l10n.infoOtherNo),
  };
  List<String> lines(String s) =>
      s.split('\n').where((l) => l.trim().isNotEmpty).toList();
  return WasteInfo(desc, lines(yes), lines(no));
}
