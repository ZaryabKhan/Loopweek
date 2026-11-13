/// Which day a week starts on, for ordering the week view.
enum FirstDayOfWeek {
  system,
  sunday,
  monday;

  static FirstDayOfWeek fromName(String? name) {
    switch (name) {
      case 'sunday':
        return FirstDayOfWeek.sunday;
      case 'monday':
        return FirstDayOfWeek.monday;
      case 'system':
      default:
        return FirstDayOfWeek.system;
    }
  }

  String get name => switch (this) {
    FirstDayOfWeek.system => 'system',
    FirstDayOfWeek.sunday => 'sunday',
    FirstDayOfWeek.monday => 'monday',
  };
}
