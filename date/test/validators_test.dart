import 'package:flutter_test/flutter_test.dart';
import 'package:kokonyo/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty', () {
      expect(Validators.email(''), isNotNull);
    });

    test('rejects malformed', () {
      expect(Validators.email('not-an-email'), isNotNull);
    });

    test('accepts valid email', () {
      expect(Validators.email('user@example.com'), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects short password', () {
      expect(Validators.password('123'), isNotNull);
    });

    test('accepts 6+ characters', () {
      expect(Validators.password('abcdef'), isNull);
    });
  });

  group('Validators.displayName', () {
    test('rejects empty', () {
      expect(Validators.displayName(''), isNotNull);
    });

    test('rejects single character', () {
      expect(Validators.displayName('A'), isNotNull);
    });

    test('accepts a normal name', () {
      expect(Validators.displayName('Ada'), isNull);
    });
  });

  group('Validators.bio', () {
    test('accepts null/empty', () {
      expect(Validators.bio(null), isNull);
      expect(Validators.bio(''), isNull);
    });

    test('rejects overly long bio', () {
      expect(Validators.bio('a' * 501), isNotNull);
    });
  });
}
