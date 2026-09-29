import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../services/reminders.dart';
import '../services/settings_store.dart';
import 'address_setup_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settings});

  final SettingsStore settings;

  static const _languages = {'it': 'Italiano', 'pl': 'Polski', 'en': 'English'};

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          appBar: AppBar(title: Text(l10n.settings)),
          body: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: Text(l10n.changeAddress),
                subtitle: Text(settings.address?.label ?? ''),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddressSetupScreen(settings: settings),
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.language),
                trailing: DropdownButton<String?>(
                  value: settings.locale?.languageCode,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(child: Text(l10n.languageSystem)),
                    for (final e in _languages.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (code) =>
                      settings.setLocale(code == null ? null : Locale(code)),
                ),
              ),
              const Divider(),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: Text(l10n.reminderEnabled),
                value: settings.remindersEnabled,
                onChanged: (v) async {
                  if (v) await Reminders.instance.requestPermission();
                  await settings.setRemindersEnabled(v);
                },
              ),
              ListTile(
                enabled: settings.remindersEnabled,
                leading: const Icon(Icons.schedule),
                title: Text(l10n.reminderTime),
                trailing: Text(settings.reminderTime.format(context)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: settings.reminderTime,
                  );
                  if (picked != null) await settings.setReminderTime(picked);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
