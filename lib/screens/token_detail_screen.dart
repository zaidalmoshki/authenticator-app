import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

import '../models/token_entry.dart';
import '../l10n/app_localizations.dart';
import '../services/clipboard_service.dart';
import '../services/totp_service.dart';
import '../state/app_providers.dart';
import '../widgets/countdown_ring.dart';

class TokenDetailScreen extends StatefulWidget {
  const TokenDetailScreen({super.key, required this.entry});

  final TokenEntry entry;

  @override
  State<TokenDetailScreen> createState() => _TokenDetailScreenState();
}

class _TokenDetailScreenState extends State<TokenDetailScreen> {
  Timer? _ticker;
  final ValueNotifier<DateTime> _now = ValueNotifier<DateTime>(DateTime.now());

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _now.value = DateTime.now();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _now.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totpService = context.read<TotpService>();
    final settings = context.watch<SettingsCubit>().state;
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
                    await context
                        .read<ClipboardService>()
                        .copyOtp(otp, autoClear: settings.clipboardAutoClear);
                    HapticFeedback.lightImpact();
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: Text(l10n.copyCode),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteToken),
        content: Text(l10n.deleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteToken),
          ),
        ],
      ),
    );
    if (result != true) return;
    await context.read<TokensCubit>().removeToken(widget.entry.id);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }
}
