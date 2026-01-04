import 'package:flutter_test/flutter_test.dart';
import 'package:authenticator_app/services/app_lock_policy.dart';

void main() {
  test('backoff increases exponentially', () {
    expect(AppLockPolicy.backoffForAttempts(1).inSeconds, 2);
    expect(AppLockPolicy.backoffForAttempts(2).inSeconds, 4);
    expect(AppLockPolicy.backoffForAttempts(3).inSeconds, 8);
    expect(AppLockPolicy.backoffForAttempts(6).inSeconds, 64);
  });
}
