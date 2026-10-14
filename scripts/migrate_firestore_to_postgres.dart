// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

/// Migration utility to migrate Firestore links to PostgreSQL
/// Usage: dart run scripts/migrate_firestore_to_postgres.dart [firestore_export.json] [output_insert.sql]
void main(List<String> args) async {
  final inputPath = args.isNotEmpty ? args[0] : 'firestore_export.json';
  final outputPath = args.length > 1 ? args[1] : 'migrated_links.sql';

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    print('Input file "$inputPath" does not exist.');
    print('Generating a sample migration SQL template based on default Rice seed links...');
    _generateSampleSql(File(outputPath));
    return;
  }

  try {
    final jsonContent = await inputFile.readAsString();
    final List<dynamic> links = jsonDecode(jsonContent);

    final buffer = StringBuffer();
    buffer.writeln('-- Generated PostgreSQL Migration from Firestore');
    buffer.writeln('-- Migration Date: ${DateTime.now().toIso8601String()}\n');

    for (final item in links) {
      final link = item as Map<String, dynamic>;
      final id = _escapeSql(link['id'] ?? link['shortCode']);
      final userId = _escapeSql(link['userId'] ?? 'rice_migrated_user');
      final userEmail = _escapeSql(link['userEmail'] ?? 'admin@rice.edu');
      final shortCode = _escapeSql((link['shortCode'] as String).toLowerCase());
      final destinationUrl = _escapeSql(link['destinationUrl'] ?? 'https://rice.edu');
      final fallbackUrl = _escapeSql(link['fallbackUrl'] ?? 'https://rice.edu');
      final isActive = link['isActive'] == false ? 'FALSE' : 'TRUE';
      final clickCount = (link['clickCount'] as num?)?.toInt() ?? 0;
      final qrConfigJson = link['qrConfig'] != null
          ? _escapeSql(jsonEncode(link['qrConfig']))
          : 'NULL';

      buffer.writeln('''
INSERT INTO short_link (
  link_id, user_id, user_email, short_code, destination_url, fallback_url,
  is_active, click_count, created_at, updated_at, qr_config_json
) VALUES (
  '$id', '$userId', '$userEmail', '$shortCode', '$destinationUrl', '$fallbackUrl',
  $isActive, $clickCount, NOW(), NOW(), ${qrConfigJson == 'NULL' ? 'NULL' : "'$qrConfigJson'"}
) ON CONFLICT (short_code) DO UPDATE SET
  destination_url = EXCLUDED.destination_url,
  fallback_url = EXCLUDED.fallback_url,
  is_active = EXCLUDED.is_active;
''');
    }

    final outputFile = File(outputPath);
    await outputFile.writeAsString(buffer.toString());
    print('Successfully generated migration SQL with ${links.length} links at "$outputPath".');
  } catch (e) {
    print('Error processing Firestore export: $e');
    exit(1);
  }
}

void _generateSampleSql(File file) {
  final sampleSql = '''
-- Sample PostgreSQL Seed Script for Rice University Links
INSERT INTO short_link (
  link_id, user_id, user_email, short_code, destination_url, fallback_url,
  is_active, click_count, created_at, updated_at, qr_config_json
) VALUES
  ('campanile', 'rice_demo_uid_1912', 'sammy.owl@rice.edu', 'campanile', 'https://rice.edu/about', 'https://rice.edu', TRUE, 142, NOW(), NOW(), '{"fgColorHex":"#00205B","bgColorHex":"#FFFFFF","style":"square","logoType":"shield"}'),
  ('fest26', 'rice_demo_uid_1912', 'sammy.owl@rice.edu', 'fest26', 'https://events.rice.edu', 'https://rice.edu', TRUE, 38, NOW(), NOW(), '{"fgColorHex":"#00205B","bgColorHex":"#FFFFFF","style":"rounded","logoType":"owl"}')
ON CONFLICT (short_code) DO NOTHING;
''';
  file.writeAsStringSync(sampleSql);
  print('Created sample migration file at "${file.path}".');
}

String _escapeSql(String value) {
  return value.replaceAll("'", "''");
}

