import 'package:flutter_test/flutter_test.dart';
import 'package:campus_ride/utils/validators.dart';

void main() {
  group('Validators', () {
    group('isValidRowanEmail', () {
      test('accepts valid @students.rowan.edu email', () {
        expect(Validators.isValidRowanEmail('john@students.rowan.edu'), isTrue);
      });

      test('accepts email with dots before @', () {
        expect(
          Validators.isValidRowanEmail('john.doe@students.rowan.edu'),
          isTrue,
        );
      });

      test('is case insensitive', () {
        expect(
          Validators.isValidRowanEmail('John@Students.Rowan.Edu'),
          isTrue,
        );
      });

      test('trims whitespace', () {
        expect(
          Validators.isValidRowanEmail('  john@students.rowan.edu  '),
          isTrue,
        );
      });

      test('accepts @rowan.edu', () {
        expect(Validators.isValidRowanEmail('john@rowan.edu'), isTrue);
      });

      test('rejects gmail.com', () {
        expect(Validators.isValidRowanEmail('john@gmail.com'), isFalse);
      });

      test('rejects empty string', () {
        expect(Validators.isValidRowanEmail(''), isFalse);
      });

      test('rejects partial domain', () {
        expect(Validators.isValidRowanEmail('john@students.rowan'), isFalse);
      });
    });

    group('isAdminEmail', () {
      test('returns true for admin email', () {
        expect(
          Validators.isAdminEmail('rowan@students.rowan.edu'),
          isTrue,
        );
      });

      test('is case insensitive', () {
        expect(
          Validators.isAdminEmail('ROWAN@Students.Rowan.Edu'),
          isTrue,
        );
      });

      test('trims whitespace', () {
        expect(
          Validators.isAdminEmail('  rowan@students.rowan.edu  '),
          isTrue,
        );
      });

      test('returns false for non-admin email', () {
        expect(
          Validators.isAdminEmail('john@students.rowan.edu'),
          isFalse,
        );
      });

      test('adminEmail constant is correct', () {
        expect(Validators.adminEmail, 'rowan@students.rowan.edu');
      });
    });

    group('validateEmail', () {
      test('returns null for valid email', () {
        expect(
          Validators.validateEmail('john@students.rowan.edu'),
          isNull,
        );
      });

      test('returns error for null', () {
        expect(Validators.validateEmail(null), isNotNull);
        expect(Validators.validateEmail(null), 'Email is required');
      });

      test('returns error for empty string', () {
        expect(Validators.validateEmail(''), 'Email is required');
      });

      test('returns error for whitespace only', () {
        expect(Validators.validateEmail('   '), 'Email is required');
      });

      test('returns error for non-Rowan email', () {
        expect(
          Validators.validateEmail('john@gmail.com'),
          'Must be a @rowan.edu or @students.rowan.edu email',
        );
      });
    });

    group('validatePassword', () {
      test('returns null for valid password (6+ chars)', () {
        expect(Validators.validatePassword('abc123'), isNull);
      });

      test('returns null for long password', () {
        expect(Validators.validatePassword('averylongpassword123'), isNull);
      });

      test('returns error for null', () {
        expect(Validators.validatePassword(null), 'Password is required');
      });

      test('returns error for empty string', () {
        expect(Validators.validatePassword(''), 'Password is required');
      });

      test('returns error for short password', () {
        expect(
          Validators.validatePassword('abc'),
          'Password must be at least 6 characters',
        );
      });

      test('returns error for 5-char password', () {
        expect(
          Validators.validatePassword('12345'),
          'Password must be at least 6 characters',
        );
      });

      test('accepts exactly 6 characters', () {
        expect(Validators.validatePassword('123456'), isNull);
      });
    });

    group('validateRequired', () {
      test('returns null for non-empty value', () {
        expect(Validators.validateRequired('Hello', 'Name'), isNull);
      });

      test('returns error for null', () {
        expect(
          Validators.validateRequired(null, 'Name'),
          'Name is required',
        );
      });

      test('returns error for empty string', () {
        expect(
          Validators.validateRequired('', 'Name'),
          'Name is required',
        );
      });

      test('returns error for whitespace only', () {
        expect(
          Validators.validateRequired('   ', 'Name'),
          'Name is required',
        );
      });

      test('uses correct field name in error message', () {
        expect(
          Validators.validateRequired('', 'Phone'),
          'Phone is required',
        );
      });
    });

    group('validatePhone', () {
      test('returns null for valid 10-digit phone', () {
        expect(Validators.validatePhone('1234567890'), isNull);
      });

      test('returns null for phone with formatting', () {
        expect(Validators.validatePhone('(123) 456-7890'), isNull);
      });

      test('returns null for empty (phone is optional)', () {
        expect(Validators.validatePhone(''), isNull);
      });

      test('returns null for null (phone is optional)', () {
        expect(Validators.validatePhone(null), isNull);
      });

      test('returns null for whitespace only (optional)', () {
        expect(Validators.validatePhone('   '), isNull);
      });

      test('returns error for short phone number', () {
        expect(
          Validators.validatePhone('12345'),
          'Enter a valid phone number',
        );
      });

      test('strips formatting before length check', () {
        // (12) 3-45 → cleaned = 12345 → length 5 < 10
        expect(
          Validators.validatePhone('(12) 3-45'),
          'Enter a valid phone number',
        );
      });
    });
  });
}
