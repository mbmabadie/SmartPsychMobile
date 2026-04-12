// lib/core/database/models/sleep_confidence.dart

/// مستوى الثقة في تصنيف جلسة النوم
/// يساعد في التمييز بين النوم الحقيقي والهاتف المتروك
enum SleepConfidence {
  /// نوم مؤكد (ليلي أو مؤكد من المستخدم)
  /// - نوم ليلي > 3 ساعات
  /// - تأكيد يدوي من المستخدم
  confirmed('مؤكد', '✅'),

  /// نوم محتمل (قيلولة مع دليل بشري)
  /// - نوم نهاري 20 دقيقة - 2 ساعة
  /// - مع وجود دليل بشري (استخدام هاتف، خطوات، تغير بيئة)
  probable('محتمل', '🤔'),

  /// هاتف متروك (بدون دليل بشري)
  /// - نوم نهاري بدون نشاط سابق
  /// - لا يوجد دليل على وجود المستخدم
  phoneLeft('هاتف متروك', '📱'),

  /// غير واضح (يحتاج تأكيد)
  /// - جلسة قصيرة جداً (< 20 دقيقة)
  /// - لا يمكن التصنيف بثقة
  uncertain('غير واضح', '❓');

  const SleepConfidence(this.displayName, this.emoji);

  final String displayName;
  final String emoji;

  /// هل هذه الجلسة تُحسب في الإحصائيات؟
  bool get countsInStats {
    return this == SleepConfidence.confirmed ||
        this == SleepConfidence.probable;
  }

  /// هل تحتاج تأكيد من المستخدم؟
  bool get needsConfirmation {
    return this == SleepConfidence.probable ||
        this == SleepConfidence.uncertain;
  }

  /// لون الحالة (Hex)
  String get colorHex {
    switch (this) {
      case SleepConfidence.confirmed:
        return '#4CAF50'; // أخضر
      case SleepConfidence.probable:
        return '#FF9800'; // برتقالي
      case SleepConfidence.phoneLeft:
        return '#9E9E9E'; // رمادي
      case SleepConfidence.uncertain:
        return '#F44336'; // أحمر
    }
  }

  /// وصف الحالة
  String get description {
    switch (this) {
      case SleepConfidence.confirmed:
        return 'جلسة نوم مؤكدة ويتم احتسابها في الإحصائيات';
      case SleepConfidence.probable:
        return 'جلسة نوم محتملة، يُنصح بالتأكيد';
      case SleepConfidence.phoneLeft:
        return 'يبدو أن الهاتف كان متروكاً، لا يُحسب كنوم';
      case SleepConfidence.uncertain:
        return 'غير واضح، يحتاج تأكيد من المستخدم';
    }
  }

  /// من String
  static SleepConfidence fromString(String value) {
    switch (value.toLowerCase()) {
      case 'confirmed':
        return SleepConfidence.confirmed;
      case 'probable':
        return SleepConfidence.probable;
      case 'phone_left':
        return SleepConfidence.phoneLeft;
      case 'uncertain':
        return SleepConfidence.uncertain;
      default:
        return SleepConfidence.uncertain;
    }
  }

  /// إلى String (للقاعدة)
  String toDbString() {
    switch (this) {
      case SleepConfidence.confirmed:
        return 'confirmed';
      case SleepConfidence.probable:
        return 'probable';
      case SleepConfidence.phoneLeft:
        return 'phone_left';
      case SleepConfidence.uncertain:
        return 'uncertain';
    }
  }

  @override
  String toString() => displayName;
}