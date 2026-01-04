import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../state/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final lockState = ref.watch(appLockProvider);
    final lockController = ref.read(appLockProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(title: 'Security', children: [
            SwitchListTile.adaptive(
              value: settings.appLockEnabled,
              title: const Text('App Lock'),
              subtitle: const Text('Require biometrics or PIN to unlock'),
              onChanged: (enabled) async {
                if (enabled && !lockState.hasPin) {
                  final pin = await _showPinSetup(context);
                  if (pin == null) return;
                  await lockController.setPin(pin);
                }
                final updated = settings.copyWith(appLockEnabled: enabled);
                await ref.read(settingsProvider.notifier).update(updated);
                HapticFeedback.selectionClick();
              },
            ),
            SwitchListTile.adaptive(
              value: settings.biometricsEnabled,
              title: const Text('Biometrics'),
              subtitle: const Text('Use Face ID or fingerprint when available'),
              onChanged: lockState.biometricsAvailable
                  ? (enabled) async {
                      final updated =
                          settings.copyWith(biometricsEnabled: enabled);
                      await ref.read(settingsProvider.notifier).update(updated);
                      HapticFeedback.selectionClick();
                    }
                  : null,
            ),
            ListTile(
              title: const Text('Change PIN'),
              subtitle: const Text('Update your app lock PIN'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                final pin = await _showPinSetup(context);
                if (pin == null) return;
                await lockController.setPin(pin);
                HapticFeedback.lightImpact();
              },
            ),
          ]),
          const SizedBox(height: 12),
          _Section(title: 'Privacy', children: [
            SwitchListTile.adaptive(
              value: settings.clipboardAutoClear,
              title: const Text('Auto-clear clipboard'),
              subtitle: const Text('Remove copied OTPs after 30 seconds'),
              onChanged: (value) async {
                final updated = settings.copyWith(clipboardAutoClear: value);
                await ref.read(settingsProvider.notifier).update(updated);
                HapticFeedback.selectionClick();
              },
            ),
            SwitchListTile.adaptive(
              value: settings.screenshotProtection,
              title: const Text('Screenshot protection'),
              subtitle: const Text('Block screenshots on sensitive screens'),
              onChanged: (value) async {
                final updated = settings.copyWith(screenshotProtection: value);
                await ref.read(settingsProvider.notifier).update(updated);
                HapticFeedback.selectionClick();
              },
            ),
          ]),
          const SizedBox(height: 12),
          _Section(title: 'Appearance', children: [
            ListTile(
              title: const Text('Theme'),
              subtitle: Text(_themeLabel(settings.themeMode)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showThemePicker(context, ref, settings),
            ),
          ]),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      _ => 'System',
    };
  }

  Future<void> _showThemePicker(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeOption(mode: ThemeMode.system, label: 'System'),
            _ThemeOption(mode: ThemeMode.light, label: 'Light'),
            _ThemeOption(mode: ThemeMode.dark, label: 'Dark'),
          ].map((option) {
            final isSelected = option.mode == settings.themeMode;
            return ListTile(
              title: Text(option.label),
              trailing: isSelected
                  ? const Icon(Icons.check_rounded)
                  : const SizedBox.shrink(),
              onTap: () => Navigator.of(context).pop(option.mode),
            );
          }).toList(),
        ),
      ),
    );
    if (selected == null) return;
    await ref
        .read(settingsProvider.notifier)
        .update(settings.copyWith(themeMode: selected));
  }

  Future<String?> _showPinSetup(BuildContext context) async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(labelText: 'PIN'),
              ),
              TextField(
                controller: confirmController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(labelText: 'Confirm PIN'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final pin = controller.text.trim();
                final confirm = confirmController.text.trim();
                if (pin.length < 4 || pin != confirm) {
                  HapticFeedback.heavyImpact();
                  return;
                }
                Navigator.of(context).pop(pin);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    confirmController.dispose();
    return result;
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).hintColor,
                    ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ThemeOption {
  const _ThemeOption({required this.mode, required this.label});

  final ThemeMode mode;
  final String label;
}
