/// Recurrence rules for tasks.
///
/// Per the spec, recurring tasks generate independent occurrences. Completing
/// or deleting one occurrence never affects past or future occurrences, and
/// the user can stop future recurrence without touching history.
enum Recurrence {
  never,
  daily,
  weekly,
  biweekly,
  monthly,
  yearly;

  static Recurrence fromName(String? name) {
    switch (name) {
      case 'daily':
        return Recurrence.daily;
      case 'weekly':
        return Recurrence.weekly;
      case 'biweekly':
        return Recurrence.biweekly;
      case 'monthly':
        return Recurrence.monthly;
      case 'yearly':
        return Recurrence.yearly;
      case 'never':
      default:
        return Recurrence.never;
    }
  }

  String get name => switch (this) {
    Recurrence.never => 'never',
    Recurrence.daily => 'daily',
    Recurrence.weekly => 'weekly',
    Recurrence.biweekly => 'biweekly',
    Recurrence.monthly => 'monthly',
    Recurrence.yearly => 'yearly',
  };

  bool get isRecurring => this != Recurrence.never;
}
