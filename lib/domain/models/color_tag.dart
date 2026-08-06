/// Color tag enum for tasks. Drives checkbox fill and accent color.
enum ColorTag {
  orange,
  pink,
  blue,
  green;

  static ColorTag get defaultValue => ColorTag.orange;

  static ColorTag fromName(String? name) {
    switch (name) {
      case 'pink':
        return ColorTag.pink;
      case 'blue':
        return ColorTag.blue;
      case 'green':
        return ColorTag.green;
      case 'orange':
      default:
        return ColorTag.orange;
    }
  }

  static ColorTag fromIndex(int index) {
    if (index >= 0 && index < ColorTag.values.length) {
      return ColorTag.values[index];
    }
    return defaultValue;
  }

  String get name => switch (this) {
    ColorTag.orange => 'orange',
    ColorTag.pink => 'pink',
    ColorTag.blue => 'blue',
    ColorTag.green => 'green',
  };
}
