import 'package:flutter_test/flutter_test.dart';
import 'package:authenticator_app/utils/otpauth_parser.dart';
import 'package:authenticator_app/models/token_entry.dart';

void main() {
  test('parses issuer and account from label', () {
    final data = OtpAuthParser.parse(
      'otpauth://totp/Example:alice@example.com?secret=JBSWY3DPEHPK3PXP',
    );

    expect(data.issuer, 'Example');
    expect(data.account, 'alice@example.com');
    expect(data.secretBase32, 'JBSWY3DPEHPK3PXP');
    expect(data.digits, 6);
    expect(data.period, 30);
    expect(data.algorithm, OtpAlgorithm.sha1);
  });

  test('prefers issuer query parameter when present', () {
    final data = OtpAuthParser.parse(
      'otpauth://totp/Label:account?secret=JBSWY3DPEHPK3PXP&issuer=Acme',
    );

    expect(data.issuer, 'Acme');
    expect(data.account, 'account');
  });
}
