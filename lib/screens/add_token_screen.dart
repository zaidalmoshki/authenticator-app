import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/token_entry.dart';
import '../state/app_providers.dart';
import '../utils/otpauth_parser.dart';

class AddTokenScreen extends ConsumerStatefulWidget {
  const AddTokenScreen({super.key});

  @override
  ConsumerState<AddTokenScreen> createState() => _AddTokenScreenState();
}

class _AddTokenScreenState extends ConsumerState<AddTokenScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;
  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add token'),
        bottom: TabBar(
          controller: _controller,
          tabs: const [
            Tab(text: 'Scan QR'),
            Tab(text: 'Manual'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: [
          _buildScanner(context),
          _ManualEntryForm(onSave: _saveToken),
        ],
      ),
    );
  }

  Widget _buildScanner(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            if (capture.barcodes.isEmpty) return;
            final value = capture.barcodes.first.rawValue;
            if (value == null || value.isEmpty) return;
            _handleScanned(value);
          },
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              color: Colors.black.withOpacity(0.6),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Align the QR code within the frame.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleScanned(String value) async {
    try {
      await _scannerController.stop();
      final parsed = OtpAuthParser.parse(value);
      await _saveToken(
        issuer: parsed.issuer,
        account: parsed.account,
        secretBase32: parsed.secretBase32,
        digits: parsed.digits,
        periodSeconds: parsed.period,
        algorithm: parsed.algorithm,
      );
    } on FormatException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR code')),
      );
      await _scannerController.start();
    }
  }

  Future<void> _saveToken({
    required String issuer,
    required String account,
    required String secretBase32,
    required int digits,
    required int periodSeconds,
    required OtpAlgorithm algorithm,
  }) async {
    final entry = TokenEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      issuer: issuer.trim().isEmpty ? 'Unknown' : issuer.trim(),
      account: account.trim().isEmpty ? 'Account' : account.trim(),
      secretBase32: secretBase32.trim(),
      digits: digits,
      periodSeconds: periodSeconds,
      algorithm: algorithm,
      createdAt: DateTime.now(),
    );
    await ref.read(tokensProvider.notifier).add(entry);
    if (!mounted) return;
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }
}

class _ManualEntryForm extends ConsumerStatefulWidget {
  const _ManualEntryForm({required this.onSave});

  final Future<void> Function({
    required String issuer,
    required String account,
    required String secretBase32,
    required int digits,
    required int periodSeconds,
    required OtpAlgorithm algorithm,
  }) onSave;

  @override
  ConsumerState<_ManualEntryForm> createState() => _ManualEntryFormState();
}

class _ManualEntryFormState extends ConsumerState<_ManualEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _issuerController = TextEditingController();
  final _accountController = TextEditingController();
  final _secretController = TextEditingController();
  int _digits = 6;
  int _period = 30;
  OtpAlgorithm _algorithm = OtpAlgorithm.sha1;

  @override
  void dispose() {
    _issuerController.dispose();
    _accountController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _issuerController,
            decoration: const InputDecoration(labelText: 'Issuer'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _accountController,
            decoration: const InputDecoration(labelText: 'Account'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _secretController,
            decoration: const InputDecoration(labelText: 'Secret (Base32)'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter a secret';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _digits,
                  decoration: const InputDecoration(labelText: 'Digits'),
                  items: const [
                    DropdownMenuItem(value: 6, child: Text('6 digits')),
                    DropdownMenuItem(value: 8, child: Text('8 digits')),
                  ],
                  onChanged: (value) => setState(() => _digits = value ?? 6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _period,
                  decoration: const InputDecoration(labelText: 'Period'),
                  items: const [
                    DropdownMenuItem(value: 30, child: Text('30s')),
                    DropdownMenuItem(value: 60, child: Text('60s')),
                  ],
                  onChanged: (value) => setState(() => _period = value ?? 30),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<OtpAlgorithm>(
            value: _algorithm,
            decoration: const InputDecoration(labelText: 'Algorithm'),
            items: const [
              DropdownMenuItem(value: OtpAlgorithm.sha1, child: Text('SHA1')),
              DropdownMenuItem(value: OtpAlgorithm.sha256, child: Text('SHA256')),
              DropdownMenuItem(value: OtpAlgorithm.sha512, child: Text('SHA512')),
            ],
            onChanged: (value) =>
                setState(() => _algorithm = value ?? OtpAlgorithm.sha1),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              await widget.onSave(
                issuer: _issuerController.text,
                account: _accountController.text,
                secretBase32: _secretController.text,
                digits: _digits,
                periodSeconds: _period,
                algorithm: _algorithm,
              );
            },
            child: const Text('Save token'),
          ),
        ],
      ),
    );
  }
}
