import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/token_entry.dart';
import '../services/totp_service.dart';
import '../state/app_providers.dart';
import '../widgets/countdown_ring.dart';

class TokenDetailScreen extends ConsumerStatefulWidget {
  const TokenDetailScreen({super.key, required this.entry});

  final TokenEntry entry;

  @override
  ConsumerState<TokenDetailScreen> createState() => _TokenDetailScreenState();
}

class _TokenDetailScreenState extends ConsumerState<TokenDetailScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ticker;
  final ValueNotifier<DateTime> _now = ValueNotifier<DateTime>(DateTime.now());

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController.unbounded(vsync: this)
      ..addListener(() => _now.value = DateTime.now())
      ..repeat(period: const Duration(milliseconds: 1000));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _now.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totpService = ref.watch(totpServiceProvider);
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry.issuer),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.entry.account,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                ValueListenableBuilder<DateTime>(
                  valueListenable: _now,
                  builder: (context, now, _) {
                    final otp = totpService.generate(widget.entry, time: now);
                    final progress = totpService.progress(widget.entry, now);
                    final remaining = totpService.remaining(widget.entry, now);
                    return Column(
                      children: [
                        Text(
                          otp.replaceAllMapped(
                            RegExp(r'(.{3})'),
                            (match) => '${match.group(0)} ',
                          ).trimRight(),
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 4,
                              ),
                        ),
                        const SizedBox(height: 12),
                        CountdownRing(
                          progress: progress,
                          remainingSeconds: remaining,
                          size: 64,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () async {
                    final otp = totpService.generate(widget.entry);
                    await ref
                        .read(clipboardServiceProvider)
                        .copyOtp(otp, autoClear: settings.clipboardAutoClear);
                    HapticFeedback.lightImpact();
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy code'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete token'),
        content: const Text('This token will be removed from your device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (result != true) return;
    await ref.read(tokensProvider.notifier).remove(widget.entry.id);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }
}
