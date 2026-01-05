import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/app_settings.dart';
import '../l10n/app_localizations.dart';
import '../state/app_providers.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsCubit>().state;
    final lockState = context.watch<AppLockCubit>().state;
    final lockController = context.read<AppLockCubit>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(title: l10n.security, children: [
            SwitchListTile.adaptive(
              value: settings.appLockEnabled,
              title: Text(l10n.appLock),
              subtitle: Text(l10n.appLockSubtitle),
              onChanged: (enabled) async {
                if (enabled && !lockState.hasPin) {
                  final pin = await _showPinSetup(context);
                  if (pin == null) return;
                  await lockController.setPin(pin);
                }
                final updated = settings.copyWith(appLockEnabled: enabled);
                await context.read<SettingsCubit>().update(updated);
                HapticFeedback.selectionClick();
              },
            ),
            SwitchListTile.adaptive(
              value: settings.biometricsEnabled,
              title: Text(l10n.biometrics),
              subtitle: Text(l10n.biometricsSubtitle),
              onChanged: lockState.biometricsAvailable
                  ? (enabled) async {
                      final updated =
                          settings.copyWith(biometricsEnabled: enabled);
                      await context.read<SettingsCubit>().update(updated);
                      HapticFeedback.selectionClick();
                    }
                  : null,
            ),
            ListTile(
              title: Text(l10n.changePin),
              subtitle: Text(l10n.changePinSubtitle),
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
          _Section(title: l10n.privacy, children: [
            SwitchListTile.adaptive(
              value: settings.clipboardAutoClear,
              title: Text(l10n.clipboardAutoClear),
              subtitle: Text(l10n.clipboardAutoClearSubtitle),
              onChanged: (value) async {
                final updated = settings.copyWith(clipboardAutoClear: value);
                await context.read<SettingsCubit>().update(updated);
                HapticFeedback.selectionClick();
              },
            ),
            SwitchListTile.adaptive(
              value: settings.screenshotProtection,
              title: Text(l10n.screenshotProtection),
              subtitle: Text(l10n.screenshotProtectionSubtitle),
              onChanged: (value) async {
                final updated = settings.copyWith(screenshotProtection: value);
                await context.read<SettingsCubit>().update(updated);
                HapticFeedback.selectionClick();
              },
            ),
          ]),
          const SizedBox(height: 12),
          _Section(title: l10n.appearance, children: [
            ListTile(
              title: Text(l10n.theme),
              subtitle: Text(_themeLabel(l10n, settings.themeMode)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showThemePicker(context, settings),
            ),
          ]),
        ],
      ),
    );
  }

  String _themeLabel(AppLocalizations l10n, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => l10n.themeLight,
      ThemeMode.dark => l10n.themeDark,
      _ => l10n.themeSystem,
    };
  }

  Future<void> _showThemePicker(
    BuildContext context,
    AppSettings settings,
  ) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeOption(mode: ThemeMode.system, label: l10n.themeSystem),
            _ThemeOption(mode: ThemeMode.light, label: l10n.themeLight),
            _ThemeOption(mode: ThemeMode.dark, label: l10n.themeDark),
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
    await context
        .read<SettingsCubit>()
        .update(settings.copyWith(themeMode: selected));
  }

  Future<String?> _showPinSetup(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.setPin),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: InputDecoration(labelText: l10n.pin),
              ),
              TextField(
                controller: confirmController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: InputDecoration(labelText: l10n.confirmPin),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
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
              child: Text(l10n.save),
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
