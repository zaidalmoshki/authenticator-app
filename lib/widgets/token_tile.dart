import 'package:flutter/material.dart';

import '../models/token_entry.dart';
import '../services/totp_service.dart';
import 'countdown_ring.dart';

class TokenTile extends StatelessWidget {
  const TokenTile({
    super.key,
    required this.entry,
    required this.totpService,
    required this.timeListenable,
    required this.onTap,
    required this.onCopy,
  });

  final TokenEntry entry;
  final TotpService totpService;
  final ValueListenable<DateTime> timeListenable;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.issuer,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.account,
                      style: textTheme.bodySmall?.copyWith(
                        color: textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<DateTime>(
                      valueListenable: timeListenable,
                      builder: (context, now, _) {
                        final otp = totpService.generate(entry, time: now);
                        return Text(
                          otp.replaceAllMapped(
                            RegExp(r'(.{3})'),
                            (match) => '${match.group(0)} ',
                          ).trimRight(),
                          style: textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ValueListenableBuilder<DateTime>(
                valueListenable: timeListenable,
                builder: (context, now, _) {
                  final progress = totpService.progress(entry, now);
                  final remaining = totpService.remaining(entry, now);
                  return Column(
                    children: [
                      CountdownRing(
                        progress: progress,
                        remainingSeconds: remaining,
                      ),
                      const SizedBox(height: 8),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded),
                        onPressed: onCopy,
                        tooltip: 'Copy code',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
