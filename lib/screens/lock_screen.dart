import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../l10n/app_localizations.dart';
import '../state/app_providers.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    context.read<AppLockCubit>().refreshBiometricsAvailability();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _unlockWithBiometrics() async {
    final success = await context.read<AppLockCubit>().tryBiometricUnlock();
    if (success) {
      HapticFeedback.lightImpact();
      return;
    }
    setState(() => _error = AppLocalizations.of(context).bioFailed);
  }

  Future<void> _submitPin() async {
    final pin = _controller.text.trim();
    final backoff = context.read<AppLockCubit>().currentBackoff();
    if (backoff != null) {
      setState(() => _error = AppLocalizations.of(context).pinBackoff(backoff.inSeconds));
      return;
    }
    final success = await context.read<AppLockCubit>().verifyPin(pin);
    if (success) {
      HapticFeedback.lightImpact();
      _controller.clear();
      setState(() => _error = null);
      return;
    }
    setState(() => _error = AppLocalizations.of(context).pinIncorrect);
    HapticFeedback.heavyImpact();
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lockState = context.watch<AppLockCubit>().state;
    return Material(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_rounded,
                    size: 52,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.unlock,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.unlockSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: l10n.pin,
                      errorText: _error,
                      counterText: '',
                    ),
                    onSubmitted: (_) => _submitPin(),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _submitPin,
                    child: Text(l10n.unlock),
                  ),
                  const SizedBox(height: 12),
                  if (lockState.biometricsAvailable)
                    TextButton.icon(
                      onPressed: _unlockWithBiometrics,
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: Text(l10n.useBiometrics),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
