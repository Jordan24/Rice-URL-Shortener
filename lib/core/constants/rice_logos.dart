
enum RiceLogoType {
  shield('Rice Shield / Crest', 'Academic Mark'),
  owl('Rice Owl', 'Spirit & Athletics'),
  oldEnglishR('Old English R', 'Heritage Mark'),
  none('None', 'Standard QR Code');

  final String label;
  final String description;
  const RiceLogoType(this.label, this.description);

  static RiceLogoType fromString(String? val) {
    if (val == null) return RiceLogoType.shield;
    return RiceLogoType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => RiceLogoType.shield,
    );
  }
}

class RiceLogos {
  RiceLogos._();

  static const String shieldPath = 'assets/logos/rice_shield.png';
  static const String owlPath = 'assets/logos/rice_owl.png';
  static const String rPath = 'assets/logos/rice_r.png';

  /// SVG representation of Rice Shield
  static const String shieldSvg = '''
<svg viewBox="0 0 100 120" xmlns="http://www.w3.org/2000/svg">
  <path d="M 10 10 L 90 10 L 90 60 C 90 95 50 115 50 115 C 50 115 10 95 10 60 Z" fill="#00205B" stroke="#C19B4C" stroke-width="6"/>
  <path d="M 22 22 L 78 22 L 78 58 C 78 85 50 102 50 102 C 50 102 22 85 22 58 Z" fill="#FFFFFF"/>
  <path d="M 50 30 L 50 95 M 22 55 L 78 55" stroke="#00205B" stroke-width="4"/>
  <circle cx="36" cy="42" r="7" fill="#00205B"/>
  <circle cx="64" cy="42" r="7" fill="#00205B"/>
  <path d="M 32 75 L 50 62 L 68 75 L 50 88 Z" fill="#C19B4C"/>
</svg>
''';

  /// SVG representation of Rice Owl
  static const String owlSvg = '''
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="50" cy="50" rx="42" ry="46" fill="#00205B" stroke="#FFFFFF" stroke-width="4"/>
  <circle cx="36" cy="40" r="15" fill="#FFFFFF"/>
  <circle cx="64" cy="40" r="15" fill="#FFFFFF"/>
  <circle cx="36" cy="40" r="9" fill="#00205B"/>
  <circle cx="64" cy="40" r="9" fill="#00205B"/>
  <circle cx="38" cy="38" r="3" fill="#FFFFFF"/>
  <circle cx="66" cy="38" r="3" fill="#FFFFFF"/>
  <polygon points="50,44 43,58 57,58" fill="#C19B4C"/>
  <path d="M 35 70 Q 50 82 65 70 M 40 76 Q 50 86 60 76" stroke="#C19B4C" stroke-width="3" fill="none" stroke-linecap="round"/>
</svg>
''';

  /// SVG representation of Old English R
  static const String oldEnglishRSvg = '''
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <circle cx="50" cy="50" r="46" fill="#00205B" stroke="#FFFFFF" stroke-width="4"/>
  <text x="50" y="72" font-family="Georgia, serif" font-size="64" font-weight="900" font-style="italic" text-anchor="middle" fill="#FFFFFF">R</text>
</svg>
''';
}
