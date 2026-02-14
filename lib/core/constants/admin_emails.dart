const List<String> kAdminEmails = [
  // Replace with your real admin email(s).
  'gkmwangi420@gmail.com',
  'admin@example.com',
];

const String _adminEmailsEnv = String.fromEnvironment('ADMIN_EMAILS', defaultValue: '');

bool isAdminEmail(String? email) {
  if (email == null) return false;
  final normalized = _normalize(email);
  if (normalized.isEmpty) return false;

  final allowlist = <String>{
    ...kAdminEmails.map(_normalize),
    ..._adminEmailsEnv.split(',').map(_normalize),
  }..removeWhere((e) => e.isEmpty || e == 'admin_email_here');

  return allowlist.contains(normalized);
}

String _normalize(String value) => value.trim().toLowerCase();
