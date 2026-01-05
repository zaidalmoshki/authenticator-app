import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/app_settings.dart';
import '../models/token_entry.dart';
import '../l10n/app_localizations.dart';
import '../services/clipboard_service.dart';
import '../services/secure_window.dart';
import '../services/totp_service.dart';
import '../state/app_providers.dart';
import '../widgets/token_tile.dart';
import 'add_token_screen.dart';
import 'lock_screen.dart';
import 'settings_screen.dart';
import 'token_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? _ticker;
  final ValueNotifier<DateTime> _now = ValueNotifier<DateTime>(DateTime.now());
  StreamSubscription<AppSettings>? _settingsSub;
  bool? _secureWindowEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final initialSettings = context.read<SettingsCubit>().state;
    context.read<AppLockCubit>().updateSettings(initialSettings);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (initialSettings.appLockEnabled) {
        context.read<AppLockCubit>().lock();
      }
      _configureSecureWindow(initialSettings.screenshotProtection);
    });
    _settingsSub = context.read<SettingsCubit>().stream.listen((next) {
      context.read<AppLockCubit>().updateSettings(next);
      _configureSecureWindow(next.screenshotProtection);
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _now.value = DateTime.now();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settingsSub?.cancel();
    _ticker?.cancel();
    _now.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      context.read<AppLockCubit>().lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final List<TokenEntry> tokens = context.watch<TokensCubit>().state;
    final TotpService totpService = context.read<TotpService>();
    final AppSettings settings = context.watch<SettingsCubit>().state;
    final AppLockState lockState = context.watch<AppLockCubit>().state;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(l10n.appTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddTokenScreen()),
            ),
            label: Text(l10n.addToken),
            icon: const Icon(Icons.add_rounded),
          ),
          body: SafeArea(
            child: tokens.isEmpty
                ? _EmptyState(
                    onAdd: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddTokenScreen()),
                    );
                  },
                    title: l10n.emptyTitle,
                    subtitle: l10n.emptySubtitle,
                    buttonLabel: l10n.addToken,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final entry = tokens[index];
                      return TokenTile(
                        entry: entry,
                        totpService: totpService,
                        timeListenable: _now,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TokenDetailScreen(entry: entry),
                          ),
                        ),
                        onCopy: () async {
                          final otp = totpService.generate(entry);
                          await context
                              .read<ClipboardService>()
                              .copyOtp(otp, autoClear: settings.clipboardAutoClear);
                          HapticFeedback.lightImpact();
                        },
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: tokens.length,
                  ),
          ),
        ),
        if (settings.appLockEnabled && lockState.isLocked)
          const LockScreen(),
      ],
    );
  }

  Future<void> _configureSecureWindow(bool enabled) async {
    if (!mounted || _secureWindowEnabled == enabled || !Platform.isAndroid) {
      return;
    }
    _secureWindowEnabled = enabled;
    await SecureWindow.setSecureFlag(enabled);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onAdd,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
  });

  final VoidCallback onAdd;
  final String title;
  final String subtitle;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
