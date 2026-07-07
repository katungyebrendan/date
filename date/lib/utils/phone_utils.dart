/// Normalizes a phone number to a stable form (leading `+` if present, digits
/// only otherwise) so the same number can't be reserved twice under two
/// different formattings, e.g. "+1 (555) 123-4567" vs "15551234567".
String normalizePhoneNumber(String raw) {
  final trimmed = raw.trim();
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  return trimmed.startsWith('+') ? '+$digits' : digits;
}
