class Validators {
  Validators._();

  /// Admin email that bypasses email verification
  static const String adminEmail = 'rowan@students.rowan.edu';

  static bool isAdminEmail(String email) {
    return email.trim().toLowerCase() == adminEmail;
  }

  static bool isValidRowanEmail(String email) {
    final lower = email.trim().toLowerCase();
    return lower.endsWith('@students.rowan.edu') ||
        lower.endsWith('@rowan.edu');
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!isValidRowanEmail(value)) {
      return 'Must be a @rowan.edu or @students.rowan.edu email';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.length < 10) {
      return 'Enter a valid phone number';
    }
    return null;
  }
}
