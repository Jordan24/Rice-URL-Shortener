import 'package:flutter_test/flutter_test.dart';
import 'package:rice_url_shortener/core/utils/url_validator.dart';

void main() {
  group('UrlValidator Tests', () {
    test('normalizeUrl prefixes https:// if missing', () {
      expect(UrlValidator.normalizeUrl('rice.edu/admissions'), equals('https://rice.edu/admissions'));
      expect(UrlValidator.normalizeUrl('http://rice.edu'), equals('http://rice.edu'));
      expect(UrlValidator.normalizeUrl('https://rice.edu'), equals('https://rice.edu'));
    });

    test('validateUrl approves valid URLs', () {
      expect(UrlValidator.validateUrl('https://rice.edu'), isNull);
      expect(UrlValidator.validateUrl('rice.edu/path/to/page'), isNull);
      expect(UrlValidator.validateUrl('https://sub.domain.rice.edu?query=test#hash'), isNull);
    });

    test('validateUrl fails on invalid inputs', () {
      expect(UrlValidator.validateUrl(''), isNotNull);
      expect(UrlValidator.validateUrl(null), isNotNull);
      expect(UrlValidator.validateUrl('not a valid url'), isNotNull);
    });

    test('validateUrl allows empty when not required', () {
      expect(UrlValidator.validateUrl('', isRequired: false), isNull);
      expect(UrlValidator.validateUrl(null, isRequired: false), isNull);
    });
  });
}
