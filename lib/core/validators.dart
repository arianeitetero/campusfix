/// Form validators shared by the auth and report forms. Each returns an error
/// message, or null when the value is valid, matching [FormFieldValidator].
class Validators {
  Validators._();

  /// Only ALU accounts may use the app: students and staff respectively.
  static const allowedEmailDomains = ['alustudent.com', 'alueducation.com'];

  static final _emailPattern = RegExp(r'^[\w.+-]+@([\w-]+\.)+[a-zA-Z]{2,}$');

  static bool isAluEmail(String email) {
    final domain = email.trim().toLowerCase().split('@').last;
    return allowedEmailDomains.contains(domain);
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your ALU email';
    if (!_emailPattern.hasMatch(v)) return 'Enter a valid email address';
    if (!isAluEmail(v)) {
      return 'Use your @${allowedEmailDomains.first} or '
          '@${allowedEmailDomains.last} email';
    }
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter a password';
    if (v.length < 8) return 'Use at least 8 characters';
    if (!v.contains(RegExp(r'[A-Za-z]')) || !v.contains(RegExp(r'\d'))) {
      return 'Include at least one letter and one number';
    }
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() original) {
    return (value) {
      if (value == null || value.isEmpty) return 'Re-enter your password';
      if (value != original()) return 'Passwords do not match';
      return null;
    };
  }

  static String? displayName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your name';
    if (v.length < 2) return 'Name is too short';
    if (v.length > 50) return 'Keep it under 50 characters';
    return null;
  }

  static const titleMin = 5, titleMax = 80;
  static const descriptionMin = 15, descriptionMax = 1000;
  static const locationMax = 100;

  static String? incidentTitle(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Give the issue a short title';
    if (v.length < titleMin) return 'Title needs at least $titleMin characters';
    if (v.length > titleMax) return 'Keep the title under $titleMax characters';
    return null;
  }

  static String? incidentDescription(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Describe what is wrong';
    if (v.length < descriptionMin) {
      return 'Add a bit more detail (at least $descriptionMin characters)';
    }
    if (v.length > descriptionMax) {
      return 'Keep it under $descriptionMax characters';
    }
    return null;
  }

  static String? location(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Where is the issue?';
    if (v.length > locationMax) return 'Keep it under $locationMax characters';
    return null;
  }
}
