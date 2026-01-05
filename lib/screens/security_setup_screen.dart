import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../l10n/app_localizations.dart';
import '../state/app_providers.dart';

class SecuritySetupScreen extends StatefulWidget {
  const SecuritySetupScreen({super.key});

  @override
  State<SecuritySetupScreen> createState() => _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends State<SecuritySetupScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _savingPin = false;
  bool _enablingBiometrics = false;
  String? _pinError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppLockCubit>().refreshBiometricsAvailability();
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsCubit>().state;
    final lockState = context.watch<AppLockCubit>().state;

    final bool needsPin = !lockState.hasPin;
    final bool needsBiometrics =
        lockState.biometricsAvailable && !settings.biometricsEnabled;
    final bool needsAppLock = !settings.appLockEnabled;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(l10n.securitySetupTitle),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.securitySetupTitle,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.securitySetupSubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Theme.of(context).hintColor),
                      ),
                      const SizedBox(height: 20),
                      _RequirementChip(
                        icon: Icons.pin_rounded,
                        label: l10n.securitySetupPinRequirement,
                        satisfied: !needsPin,
                      ),
                      if (needsPin) ...[
                        const SizedBox(height: 12),
                        _buildPinFields(l10n),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _savingPin ? null : _savePin,
                          child: _savingPin
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2.4),
                                )
                              : Text(l10n.savePinAction),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _RequirementChip(
                        icon: Icons.lock_outline_rounded,
                        label: l10n.securitySetupAppLockRequirement,
                        satisfied: !needsAppLock,
                      ),
                      if (needsAppLock)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _enableAppLock,
                            child: Text(l10n.enableAppLock),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _RequirementChip(
                        icon: Icons.fingerprint_rounded,
                        label: lockState.biometricsAvailable
                            ? l10n.securitySetupBiometricRequirement
                            : l10n.securitySetupBiometricUnavailable,
                        satisfied: !needsBiometrics,
                      ),
                      if (needsBiometrics) ...[
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _enablingBiometrics ? null : _enableBiometrics,
                          icon: _enablingBiometrics
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.check_circle_rounded),
                          label: Text(l10n.enableBiometrics),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinFields(AppLocalizations l10n) {
    return Column(
      children: [
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: l10n.pin,
            counterText: '',
          ),
        ),
        TextField(
          controller: _confirmController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: l10n.confirmPin,
            counterText: '',
            errorText: _pinError,
          ),
          onSubmitted: (_) => _savePin(),
        ),
      ],
    );
  }

  Future<void> _savePin() async {
    final l10n = AppLocalizations.of(context);
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();
    if (pin.length < 4 || pin != confirm) {
      setState(() => _pinError = l10n.pinValidationError);
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() {
      _savingPin = true;
      _pinError = null;
    });
    await context.read<AppLockCubit>().setPin(pin);
    final settings = context.read<SettingsCubit>().state;
    if (!settings.appLockEnabled) {
      await context
          .read<SettingsCubit>()
          .update(settings.copyWith(appLockEnabled: true));
    }
    if (mounted) {
      _pinController.clear();
      _confirmController.clear();
      setState(() => _savingPin = false);
      HapticFeedback.lightImpact();
    }
    await _tryLockIfReady();
  }

  Future<void> _enableAppLock() async {
    final settings = context.read<SettingsCubit>().state;
    await context
        .read<SettingsCubit>()
        .update(settings.copyWith(appLockEnabled: true));
    await _tryLockIfReady();
  }

  Future<void> _enableBiometrics() async {
    setState(() => _enablingBiometrics = true);
    await context.read<AppLockCubit>().refreshBiometricsAvailability();
    final settings = context.read<SettingsCubit>().state;
    final lockState = context.read<AppLockCubit>().state;
    if (lockState.biometricsAvailable) {
      await context.read<SettingsCubit>().update(
            settings.copyWith(
              appLockEnabled: true,
              biometricsEnabled: true,
            ),
          );
    }
    if (mounted) {
      setState(() => _enablingBiometrics = false);
    }
    await _tryLockIfReady();
  }

  Future<void> _tryLockIfReady() async {
    final settings = context.read<SettingsCubit>().state;
    final lockState = context.read<AppLockCubit>().state;
    final ready = lockState.hasPin &&
        settings.appLockEnabled &&
        (!lockState.biometricsAvailable || settings.biometricsEnabled);
    if (ready) {
      context.read<AppLockCubit>().lock();
    }
  }
}

class _RequirementChip extends StatelessWidget {
  const _RequirementChip({
    required this.icon,
    required this.label,
    required this.satisfied,
  });

  final IconData icon;
  final String label;
  final bool satisfied;

  @override
  Widget build(BuildContext context) {
    final color = satisfied
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Icon(
          satisfied ? Icons.check_circle_rounded : Icons.error_outline_rounded,
          color: color,
        ),
      ],
    );
  }
}
