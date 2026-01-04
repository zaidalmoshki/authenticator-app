import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

import '../models/token_entry.dart';
import '../services/totp_service.dart';
import '../state/app_providers.dart';
import '../widgets/token_tile.dart';
import 'add_token_screen.dart';
import 'lock_screen.dart';
import 'settings_screen.dart';
import 'token_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _ticker;
  final ValueNotifier<DateTime> _now = ValueNotifier<DateTime>(DateTime.now());
  bool? _secureWindowEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        _now.value = DateTime.now();
      })
      ..repeat(period: const Duration(milliseconds: 1000));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      if (settings.appLockEnabled) {
        ref.read(appLockProvider.notifier).lock();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _now.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      ref.read(appLockProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(tokensProvider);
    final totpService = ref.watch(totpServiceProvider);
    final settings = ref.watch(settingsProvider);
    final lockState = ref.watch(appLockProvider);

    _configureSecureWindow(settings.screenshotProtection);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Authenticator'),
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
            label: const Text('Add token'),
            icon: const Icon(Icons.add_rounded),
          ),
          body: SafeArea(
            child: tokens.isEmpty
                ? _EmptyState(onAdd: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddTokenScreen()),
                    );
                  })
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
                          await ref
                              .read(clipboardServiceProvider)
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
    if (enabled) {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    } else {
      await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

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
              'No tokens yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first account to start generating secure codes.',
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
              label: const Text('Add token'),
            ),
          ],
        ),
      ),
    );
  }
}
