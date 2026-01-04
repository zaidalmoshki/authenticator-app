import 'package:flutter_test/flutter_test.dart';
import 'package:authenticator_app/models/token_entry.dart';
import 'package:authenticator_app/services/totp_service.dart';

void main() {
  test('generates expected TOTP for fixed time', () {
    final entry = TokenEntry(
      id: '1',
      issuer: 'Example',
      account: 'alice@example.com',
      secretBase32: 'JBSWY3DPEHPK3PXP',
      digits: 6,
      periodSeconds: 30,
      algorithm: OtpAlgorithm.sha1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
    final service = TotpService();
    final otp = service.generate(
      entry,
      time: DateTime.fromMillisecondsSinceEpoch(0),
    );

    expect(otp, '282760');
  });
}
