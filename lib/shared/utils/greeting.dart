class Greeting {
  Greeting._();

  static String get text {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  static String get emoji {
    final h = DateTime.now().hour;
    if (h < 12) return '\u{1F324}\u{FE0F}';
    if (h < 17) return '\u{2600}\u{FE0F}';
    return '\u{1F319}';
  }
}
