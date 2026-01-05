import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/token_entry.dart';
import '../l10n/app_localizations.dart';
import '../state/app_providers.dart';
import '../utils/otpauth_parser.dart';

class AddTokenScreen extends StatefulWidget {
  const AddTokenScreen({super.key});

  @override
  State<AddTokenScreen> createState() => _AddTokenScreenState();
}

class _AddTokenScreenState extends State<AddTokenScreen>
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addToken),
        bottom: TabBar(
          controller: _controller,
          tabs: [
            Tab(text: l10n.scanQr),
            Tab(text: l10n.manual),
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
    final l10n = AppLocalizations.of(context);
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
                  l10n.qrHint,
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
        SnackBar(content: Text(AppLocalizations.of(context).invalidQr)),
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
    await context.read<TokensCubit>().addToken(entry);
    if (!mounted) return;
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }
}

class _ManualEntryForm extends StatefulWidget {
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
  State<_ManualEntryForm> createState() => _ManualEntryFormState();
}

class _ManualEntryFormState extends State<_ManualEntryForm> {
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
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _issuerController,
            decoration: InputDecoration(labelText: l10n.issuer),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _accountController,
            decoration: InputDecoration(labelText: l10n.account),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _secretController,
            decoration: InputDecoration(labelText: l10n.secret),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.secretError;
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
                  decoration: InputDecoration(labelText: l10n.digits),
                  items: [
                    DropdownMenuItem(value: 6, child: Text(l10n.digits6)),
                    DropdownMenuItem(value: 8, child: Text(l10n.digits8)),
                  ],
                  onChanged: (value) => setState(() => _digits = value ?? 6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _period,
                  decoration: InputDecoration(labelText: l10n.period),
                  items: [
                    DropdownMenuItem(value: 30, child: Text(l10n.period30)),
                    DropdownMenuItem(value: 60, child: Text(l10n.period60)),
                  ],
                  onChanged: (value) => setState(() => _period = value ?? 30),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<OtpAlgorithm>(
            value: _algorithm,
            decoration: InputDecoration(labelText: l10n.algorithm),
            items: [
              DropdownMenuItem(value: OtpAlgorithm.sha1, child: Text(l10n.sha1)),
              DropdownMenuItem(value: OtpAlgorithm.sha256, child: Text(l10n.sha256)),
              DropdownMenuItem(value: OtpAlgorithm.sha512, child: Text(l10n.sha512)),
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
            child: Text(l10n.addToken),
          ),
        ],
      ),
    );
  }
}
