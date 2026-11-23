/// منطق القفل الزمني: دالة صافية بلا واجهة، فتُختبر بدقة.
enum LockReason { none, dailyLimit, outsideHours, clockChanged }

class TimePolicy {
  /// 0 = بلا حد يومي.
  final int dailyLimitMinutes;

  /// الساعات المسموحة [fromHour, toHour). إذا تساويا فلا قيد على الوقت.
  final int fromHour;
  final int toHour;

  const TimePolicy({this.dailyLimitMinutes = 0, this.fromHour = 0, this.toHour = 0});

  bool get hasWindow => fromHour != toHour;

  bool insideWindow(DateTime now) {
    if (!hasWindow) return true;
    final h = now.hour;
    // نافذة تعبر منتصف الليل (مثلًا من 20 إلى 6) مدعومة أيضًا
    return fromHour < toHour ? (h >= fromHour && h < toHour) : (h >= fromHour || h < toHour);
  }
}

class TimeLock {
  /// أقصى رجوع مقبول لساعة الجهاز قبل اعتباره تلاعبًا (تصحيح الوقت التلقائي يكون بثوانٍ).
  static const clockTolerance = Duration(minutes: 10);

  static LockReason evaluate({
    required TimePolicy policy,
    required int usedSeconds,
    required int bonusSeconds,
    required DateTime now,
    DateTime? lastSeen,
  }) {
    if (lastSeen != null && now.isBefore(lastSeen.subtract(clockTolerance))) return LockReason.clockChanged;
    if (!policy.insideWindow(now)) return LockReason.outsideHours;
    if (policy.dailyLimitMinutes > 0 && usedSeconds >= policy.dailyLimitMinutes * 60 + bonusSeconds) {
      return LockReason.dailyLimit;
    }
    return LockReason.none;
  }

  static int remainingSeconds({required TimePolicy policy, required int usedSeconds, required int bonusSeconds}) {
    if (policy.dailyLimitMinutes <= 0) return -1;
    final r = policy.dailyLimitMinutes * 60 + bonusSeconds - usedSeconds;
    return r < 0 ? 0 : r;
  }
}
