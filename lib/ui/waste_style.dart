import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/collection.dart';

/// Localized label for a waste type; falls back to the source's own name.
String wasteLabel(AppLocalizations l10n, WasteType type) => switch (type.kind) {
  WasteKind.mixed => l10n.wasteMixed,
  WasteKind.bio => l10n.wasteBio,
  WasteKind.paper => l10n.wastePaper,
  WasteKind.plastics => l10n.wastePlastics,
  WasteKind.glass => l10n.wasteGlass,
  WasteKind.bulky => l10n.wasteBulky,
  WasteKind.hazardous => l10n.wasteHazardous,
  WasteKind.ewaste => l10n.wasteEwaste,
  WasteKind.garden => l10n.wasteGarden,
  WasteKind.tree => l10n.wasteTree,
  WasteKind.textile => l10n.wasteTextile,
  WasteKind.metal => l10n.wasteMetal,
  WasteKind.other => type.name,
};

/// Bin colours follow the Polish national sorting scheme (JSSO).
Color wasteColor(WasteKind kind) => switch (kind) {
  WasteKind.mixed => const Color(0xFF424242),
  WasteKind.bio => const Color(0xFF795548),
  WasteKind.paper => const Color(0xFF1E88E5),
  WasteKind.plastics || WasteKind.metal => const Color(0xFFFBC02D),
  WasteKind.glass => const Color(0xFF43A047),
  WasteKind.garden || WasteKind.tree => const Color(0xFF689F38),
  WasteKind.hazardous => const Color(0xFFE53935),
  WasteKind.ewaste => const Color(0xFF8E24AA),
  WasteKind.bulky ||
  WasteKind.textile ||
  WasteKind.other => const Color(0xFF78909C),
};

IconData wasteIcon(WasteKind kind) => switch (kind) {
  WasteKind.mixed => Icons.delete_outline,
  WasteKind.bio => Icons.eco_outlined,
  WasteKind.paper => Icons.description_outlined,
  WasteKind.plastics => Icons.local_drink_outlined,
  WasteKind.glass => Icons.wine_bar_outlined,
  WasteKind.bulky => Icons.chair_outlined,
  WasteKind.hazardous => Icons.warning_amber_outlined,
  WasteKind.ewaste => Icons.devices_other_outlined,
  WasteKind.garden => Icons.grass_outlined,
  WasteKind.tree => Icons.park_outlined,
  WasteKind.textile => Icons.checkroom_outlined,
  WasteKind.metal => Icons.hardware_outlined,
  WasteKind.other => Icons.recycling,
};

class WasteChip extends StatelessWidget {
  const WasteChip({super.key, required this.type});

  final WasteType type;

  @override
  Widget build(BuildContext context) {
    final color = wasteColor(type.kind);
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    return Chip(
      avatar: Icon(wasteIcon(type.kind), size: 18, color: onColor),
      label: Text(wasteLabel(AppLocalizations.of(context), type)),
      labelStyle: TextStyle(color: onColor),
      backgroundColor: color,
      side: BorderSide.none,
    );
  }
}
