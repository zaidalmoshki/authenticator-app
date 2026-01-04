class AppLockPolicy {
  static Duration backoffForAttempts(int attempts) {
    final clamped = attempts.clamp(1, 6);
    final seconds = 2 << (clamped - 1);
    return Duration(seconds: seconds);
  }

  static DateTime lockoutUntil(DateTime now, int attempts) {
    return now.add(backoffForAttempts(attempts));
  }
}
