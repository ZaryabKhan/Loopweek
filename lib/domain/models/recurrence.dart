/// Recurrence rules for tasks.
///
/// Per the spec, recurring tasks generate independent occurrences. Completing
/// or deleting one occurrence never affects past or future occurrences, and
/// the user can stop future recurrence without touching history.
enum Recurrence {
  never,
  daily,
  weekly;

  static Recurrence fromName(String? name) {
    switch (name) {
      case 'daily':
        return Recurrence.daily;
      case 'weekly':
        return Recurrence.weekly;
      case 'never':
      default:
        return Recurrence.never;
    }
  }

  String get name => switch (this) {
    Recurrence.never => 'never',
    Recurrence.daily => 'daily',
    Recurrence.weekly => 'weekly',
  };

  bool get isRecurring => this != Recurrence.never;
}
