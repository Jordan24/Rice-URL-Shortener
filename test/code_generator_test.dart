import 'package:flutter_test/flutter_test.dart';
import 'package:rice_url_shortener/core/utils/code_generator.dart';

void main() {
  group('CodeGenerator Tests', () {
    test('generateShortCode creates 5 character alphanumeric string', () {
      final code = CodeGenerator.generateShortCode();
      expect(code.length, equals(5));
      expect(RegExp(r'^[a-z0-9]{5}$').hasMatch(code), isTrue);
    });

    test('generateShortCode creates unique codes', () {
      final codes = <String>{};
      for (int i = 0; i < 100; i++) {
        codes.add(CodeGenerator.generateShortCode());
      }
      expect(codes.length, equals(100));
    });

    test('sanitizeSlug lowercases and trims', () {
      expect(CodeGenerator.sanitizeSlug('  RICE-Fest-2026  '), equals('rice-fest-2026'));
    });

    test('validateSlug accepts valid custom slugs', () {
      expect(CodeGenerator.validateSlug('owl-fest'), isNull);
      expect(CodeGenerator.validateSlug('hackrice_12'), isNull);
      expect(CodeGenerator.validateSlug('rice2026'), isNull);
    });

    test('validateSlug rejects too short or too long slugs', () {
      expect(CodeGenerator.validateSlug('ab'), isNotNull);
      expect(CodeGenerator.validateSlug('a' * 35), isNotNull);
    });

    test('validateSlug blocks reserved system routes', () {
      expect(CodeGenerator.validateSlug('app'), isNotNull);
      expect(CodeGenerator.validateSlug('api'), isNotNull);
      expect(CodeGenerator.validateSlug('login'), isNotNull);
      expect(CodeGenerator.validateSlug('dashboard'), isNotNull);
    });

    test('validateSlug rejects illegal characters', () {
      expect(CodeGenerator.validateSlug('bad code!@#'), isNotNull);
      expect(CodeGenerator.validateSlug('rice/event'), isNotNull);
    });
  });
}
