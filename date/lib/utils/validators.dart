class Validators {
  Validators._();

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? displayName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name is too short';
    return null;
  }

  static String? bio(String? value) {
    if (value != null && value.length > 500) return 'Bio must be under 500 characters';
    return null;
  }

  static String? whatsappNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'WhatsApp number is required';
    final digitCount = value.replaceAll(RegExp(r'\D'), '').length;
    if (digitCount < 7) return 'Enter a valid WhatsApp number';
    return null;
  }
}
