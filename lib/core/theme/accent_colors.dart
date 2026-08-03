import 'package:flutter/material.dart';
import 'package:loopweek/domain/models/color_tag.dart';

/// Resolves a [ColorTag] to actual Material [Color] values used by the UI.
///
/// Default orange roughly #F4511E, per spec. The accent drives the active
/// checkbox fill, the selected segmented-control option, toggle switches, and
/// the primary "Add" action — as well as the home widget color.
class AccentColors {
  const AccentColors._();

  static const Map<ColorTag, Color> _values = {
    ColorTag.orange: Color(0xFFF4511E),
    ColorTag.pink: Color(0xFFE91E63),
    ColorTag.blue: Color(0xFF1E88E5),
    ColorTag.green: Color(0xFF43A047),
  };

  static Color of(ColorTag tag) => _values[tag] ?? _values[ColorTag.orange]!;

  /// Foreground color that meets contrast on top of [accent] — used for the
  /// check glyph on the active checkbox, the selected segmented option text,
  /// and the switch thumb. Computed per-accent so a dark blue or green accent
  /// never pairs with black text.
  static Color onAccentOf(Color accent) {
    // WCAG relative luminance threshold for white-on-color is ~0.18.
    return accent.computeLuminance() > 0.45 ? Colors.black87 : Colors.white;
  }
}
