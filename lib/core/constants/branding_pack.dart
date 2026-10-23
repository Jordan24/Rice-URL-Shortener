/// Rice University Branding Packs including the 12 Residential Colleges.
enum BrandingPackType {
  university('Rice University', 'Official Institutional Identity', 'Rice'),
  baker('Baker College', 'Red & Silver • Hell yeah!', 'Baker'),
  willRice('Will Rice College', 'Rust & Gold • The Phoenix', 'Will Rice'),
  hanszen('Hanszen College', 'Royal Blue & Yellow • The Guardian', 'Hanszen'),
  wiess('Wiess College', 'Goldenrod & Black • War Pig & Griffin', 'Wiess'),
  jones('Jones College', 'Forest Green & Purple • JIBA', 'Jones'),
  brown('Brown College', 'Maroon & Gold • Tower & Sunburst', 'Brown'),
  lovett('Lovett College', 'Lovett Navy & Gold • Wolves & Toaster', 'Lovett'),
  sidRichardson('Sid Richardson College', 'Cardinal Red & Black • Death from Above', 'Sid Rich'),
  martel('Martel College', 'Greek Sky Blue & Maroon • Athenian Owl', 'Martel'),
  mcmurtry('McMurtry College', 'Royal McPurple & Silver • Scottish Lion', 'McMurtry'),
  duncan('Duncan College', 'Forest Green & Laurel Gold • Duncan Oak', 'Duncan'),
  chao('Chao College', 'Pink, Ivory & Navy • Twin Dragons', 'Chao');

  final String label;
  final String description;
  final String shortName;

  const BrandingPackType(this.label, this.description, this.shortName);

  static BrandingPackType fromString(String? val) {
    if (val == null) return BrandingPackType.university;
    return BrandingPackType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => BrandingPackType.university,
    );
  }
}
