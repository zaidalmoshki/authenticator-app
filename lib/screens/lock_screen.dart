import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_providers.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    ref.read(appLockProvider.notifier).refreshBiometricsAvailability();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _unlockWithBiometrics() async {
    final success = await ref.read(appLockProvider.notifier).tryBiometricUnlock();
    if (success) {
      HapticFeedback.lightImpact();
      return;
    }
    setState(() => _error = 'Biometric unlock failed. Use your PIN.');
  }

  Future<void> _submitPin() async {
    final pin = _controller.text.trim();
    final backoff = ref.read(appLockProvider.notifier).currentBackoff();
    if (backoff != null) {
      setState(() => _error = 'Try again in ${backoff.inSeconds}s.');
      return;
    }
    final success = await ref.read(appLockProvider.notifier).verifyPin(pin);
    if (success) {
      HapticFeedback.lightImpact();
      _controller.clear();
      setState(() => _error = null);
      return;
    }
    setState(() => _error = 'Incorrect PIN.');
    HapticFeedback.heavyImpact();
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockProvider);
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
                    'Unlock',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your PIN or use biometrics.',
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
                      labelText: 'PIN',
                      errorText: _error,
                      counterText: '',
                    ),
                    onSubmitted: (_) => _submitPin(),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _submitPin,
                    child: const Text('Unlock'),
                  ),
                  const SizedBox(height: 12),
                  if (lockState.biometricsAvailable)
                    TextButton.icon(
                      onPressed: _unlockWithBiometrics,
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: const Text('Use biometrics'),
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
