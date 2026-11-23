/// مجمّع كائنات عام (Object Pool): يعيد استخدام الكائنات بدل إنشائها وحذفها
/// باستمرار، فيقل عمل جامع القمامة (GC) ولا يتقطع الإطار في الألعاب.
class ObjectPool<T> {
  final T Function() _create;
  final void Function(T)? _onRelease;
  final int maxFree;
  final List<T> _free = [];

  /// عدد الكائنات التي أُنشئت فعلًا منذ البداية (للقياس والاختبار).
  int created = 0;

  /// عدد مرات إعادة الاستخدام بدل الإنشاء.
  int reused = 0;

  ObjectPool({required T Function() create, void Function(T)? onRelease, this.maxFree = 32, int prewarm = 0})
      : _create = create,
        _onRelease = onRelease {
    for (var i = 0; i < prewarm; i++) {
      _free.add(_make());
    }
  }

  T _make() {
    created++;
    return _create();
  }

  int get available => _free.length;

  T acquire() {
    if (_free.isNotEmpty) {
      reused++;
      return _free.removeLast();
    }
    return _make();
  }

  void release(T obj) {
    _onRelease?.call(obj);
    if (_free.length < maxFree) _free.add(obj);
  }
}
