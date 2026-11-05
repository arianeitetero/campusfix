import 'package:campusfix/core/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('accepts student and staff ALU domains', () {
      expect(Validators.email('a.student@alustudent.com'), isNull);
      expect(Validators.email('staff.member@alueducation.com'), isNull);
      expect(Validators.email('  Mixed@AluStudent.com '), isNull);
    });

    test('rejects other domains', () {
      expect(Validators.email('someone@gmail.com'), isNotNull);
      expect(Validators.email('x@alustudent.com.evil.io'), isNotNull);
    });

    test('rejects empty and malformed input', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('requires length, a letter and a number', () {
      expect(Validators.password('short1'), isNotNull);
      expect(Validators.password('onlyletters'), isNotNull);
      expect(Validators.password('12345678'), isNotNull);
      expect(Validators.password('campus2026'), isNull);
    });

    test('confirmPassword compares with the original', () {
      final validate = Validators.confirmPassword(() => 'campus2026');
      expect(validate('campus2026'), isNull);
      expect(validate('campus2025'), isNotNull);
    });
  });

  group('incident fields', () {
    test('title length bounds', () {
      expect(Validators.incidentTitle('Leak'), isNotNull);
      expect(Validators.incidentTitle('Leaking tap'), isNull);
      expect(Validators.incidentTitle('x' * 81), isNotNull);
    });

    test('description needs real detail', () {
      expect(Validators.incidentDescription('Broken'), isNotNull);
      expect(Validators.incidentDescription('The tap in room 3 drips all night'),
          isNull);
    });

    test('location is required', () {
      expect(Validators.location('   '), isNotNull);
      expect(Validators.location('Library, 2nd floor'), isNull);
    });
  });
}
