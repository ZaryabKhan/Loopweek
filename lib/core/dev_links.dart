/// External links to the developer's public profiles, shown at the bottom of
/// the Settings screen in the "Developer" section.
///
/// GitHub is the repo's open-source home. The Website and Google Play links
/// point at your public profiles — replace the empty placeholders with your
/// real URLs before shipping. Buttons are shown regardless; a button with an
/// empty URL is disabled.
abstract final class DevLinks {
  /// GitHub profile: the open-source Loopweek repo lives here
  /// (https://github.com/ZaryabKhan/loopweek).
  static const String github = 'https://github.com/ZaryabKhan';

  /// Personal website / portfolio (shows all your apps).
  static const String website = 'https://www.appcodecraft.com/';

  /// Google Play developer profile. Loopweek is not published on Play yet, so
  /// this points at the developer page for your other apps for now.
  static const String playStore =
      'https://play.google.com/store/apps/dev?id=6994476958831569782';

  /// Polar checkout where users can support the project with a one-off payment.
  static const String support =
      'https://buy.polar.sh/polar_cl_J3Nnh3YVrN1jMh8GdYaqZD3FjKvg9lsyR3eih1FkRt8';
}
