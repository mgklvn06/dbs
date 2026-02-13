String mapFirebaseAuthError(String raw) {
  final msg = raw.toLowerCase();

  if (msg.contains('user-not-found')) return 'No account found for that email.';
  if (msg.contains('wrong-password')) return 'The password is incorrect. Please try again.';
  if (msg.contains('invalid-credential') || msg.contains('malformed') || msg.contains('expired')) {
    return 'Invalid credentials. If you signed up with Google, you need to set a password first.';
  }
  if (msg.contains('operation-not-allowed')) {
    return 'Email/password sign-in is disabled. Enable it in Firebase Auth.';
  }
  if (msg.contains('user-disabled')) return 'This account has been disabled.';
  if (msg.contains('invalid-email')) return 'The email address is invalid.';
  if (msg.contains('network-request-failed')) return 'Network error. Check your internet connection.';
  if (msg.contains('popup-blocked') || msg.contains('popup_closed_by_user')) return 'The sign-in popup was blocked or closed. Allow popups and try again.';
  if (msg.contains('account-exists-with-different-credential')) return 'An account exists with a different sign-in method. Try another sign-in method.';
  if (msg.contains('cancelled')) return 'Sign-in was cancelled.';

  // Fallback: if raw contains a human message after a colon, return that part
  final parts = raw.split(':');
  if (parts.length > 1) return parts.sublist(1).join(':').trim();

  return raw;
}
