/// ✅ Input sanitization and validation utilities
class InputSanitizer {
  // ===== TEXT SANITIZATION =====

  /// Remove leading/trailing whitespace and extra spaces between words
  static String sanitizeText(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Remove all special characters except spaces
  static String sanitizeName(String text) {
    return text.replaceAll(RegExp(r'[^a-zA-Z\s]'), '').trim();
  }

  /// Remove all non-numeric characters
  static String sanitizePhoneNumber(String text) {
    return text.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  /// Remove all non-alphanumeric characters except dots
  static String sanitizeEmail(String text) {
    return text.toLowerCase().trim();
  }

  /// Prevent XSS by removing dangerous HTML/script content
  static String sanitizeForDisplay(String text) {
    return text
        .replaceAll('<script>', '')
        .replaceAll('</script>', '')
        .replaceAll('<iframe>', '')
        .replaceAll('</iframe>', '')
        .replaceAll(RegExp(r'on\w+='), '') // Remove onclick, onload, etc.
        .trim();
  }

  // ===== LENGTH VALIDATION =====

  static bool isValidLength(
    String text, {
    int minLength = 1,
    int maxLength = 1000,
  }) {
    return text.isNotEmpty &&
        text.length >= minLength &&
        text.length <= maxLength;
  }

  static bool isNotEmpty(String text) {
    return text.trim().isNotEmpty;
  }

  // ===== PASSWORD VALIDATION =====

  static bool hasMinLength(String password, {int minLength = 8}) {
    return password.length >= minLength;
  }

  static bool hasLetter(String password) {
    return RegExp(r'[a-zA-Z]').hasMatch(password);
  }

  static bool hasNumber(String password) {
    return RegExp(r'[0-9]').hasMatch(password);
  }

  static bool hasSpecialCharacter(String password) {
    return RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  static bool isStrongPassword(String password) {
    return hasMinLength(password) &&
        hasLetter(password) &&
        hasNumber(password) &&
        hasSpecialCharacter(password);
  }

  // ===== EMAIL VALIDATION =====

  static bool isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email.toLowerCase());
  }

  // ===== PHONE VALIDATION =====

  static bool isValidPhoneNumber(String phone) {
    final cleaned = sanitizePhoneNumber(phone);
    return cleaned.length >= 10 &&
        RegExp(r'^(\+)?[0-9]{10,}$').hasMatch(cleaned);
  }

  // ===== NAME VALIDATION =====

  static bool isValidName(String name) {
    final cleaned = sanitizeName(name);
    return cleaned.isNotEmpty && cleaned.length >= 2 && cleaned.length <= 50;
  }

  // ===== URL VALIDATION =====

  static bool isValidUrl(String url) {
    return Uri.tryParse(url)?.isAbsolute ?? false;
  }

  // ===== NUMBERS =====

  static bool isNumeric(String text) {
    return int.tryParse(text) != null || double.tryParse(text) != null;
  }

  // ===== COMBINED VALIDATION =====

  /// Validate signup form inputs
  static Map<String, String?> validateSignupForm({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    required String? dateOfBirth,
  }) {
    final errors = <String, String?>{};

    // Validate first name
    if (!isValidName(firstName)) {
      errors['firstName'] = 'First name must be 2-50 characters (letters only)';
    }

    // Validate last name
    if (!isValidName(lastName)) {
      errors['lastName'] = 'Last name must be 2-50 characters (letters only)';
    }

    // Validate email
    if (!isValidEmail(email)) {
      errors['email'] = 'Please enter a valid email address';
    }

    // Validate password
    if (!hasMinLength(password)) {
      errors['password'] = 'Password must be at least 8 characters';
    } else if (!hasLetter(password)) {
      errors['password'] = 'Password must contain at least one letter';
    } else if (!hasNumber(password)) {
      errors['password'] = 'Password must contain at least one number';
    }

    // Validate passwords match
    if (password != confirmPassword) {
      errors['confirmPassword'] = 'Passwords do not match';
    }

    // Validate date of birth
    if (dateOfBirth == null || dateOfBirth.isEmpty) {
      errors['dateOfBirth'] = 'Please select your date of birth';
    }

    return errors;
  }

  /// Validate login form inputs
  static Map<String, String?> validateLoginForm({
    required String email,
    required String password,
  }) {
    final errors = <String, String?>{};

    if (email.isEmpty) {
      errors['email'] = 'Email is required';
    } else if (!isValidEmail(email)) {
      errors['email'] = 'Please enter a valid email address';
    }

    if (password.isEmpty) {
      errors['password'] = 'Password is required';
    }

    return errors;
  }

  /// Validate profile edit form inputs
  static Map<String, String?> validateProfileForm({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String nationality,
  }) {
    final errors = <String, String?>{};

    if (fullName.isEmpty) {
      errors['fullName'] = 'Full name is required';
    }

    if (email.isEmpty) {
      errors['email'] = 'Email is required';
    } else if (!isValidEmail(email)) {
      errors['email'] = 'Please enter a valid email';
    }

    if (phoneNumber.isNotEmpty && !isValidPhoneNumber(phoneNumber)) {
      errors['phoneNumber'] = 'Please enter a valid phone number';
    }

    if (nationality.isEmpty) {
      errors['nationality'] = 'Please select a nationality';
    }

    return errors;
  }

  // ===== DATE VALIDATION =====

  /// Validates if a date is actually valid (e.g., rejects Feb 31)
  /// Returns true if the date is valid, false otherwise
  static bool isValidDate(int day, int month, int year) {
    try {
      final date = DateTime(year, month, day);
      // DateTime constructor fixes invalid dates, so we check if it matches
      return date.year == year && date.month == month && date.day == day;
    } catch (_) {
      return false;
    }
  }

  /// Validates a complete birthdate and checks minimum age
  /// Returns error message if invalid, null if valid
  static String? validateBirthDate(
    int day,
    int month,
    int year, {
    int minAge = 16,
  }) {
    // Check if date is valid (e.g., reject Feb 31)
    if (!isValidDate(day, month, year)) {
      return 'Please enter a valid date (e.g., February does not have 31 days)';
    }

    try {
      final birthDate = DateTime(year, month, day);
      final now = DateTime.now();

      // Check if birth date is in the future
      if (birthDate.isAfter(now)) {
        return 'Birth date cannot be in the future';
      }

      // Calculate age
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }

      // Check minimum age
      if (age < minAge) {
        return 'You must be at least $minAge years old';
      }

      return null; // Valid
    } catch (_) {
      return 'Please enter a valid date';
    }
  }
}
