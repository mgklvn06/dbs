# TODO: Fix Registration, Login, and Routes

## Issues Identified
- Register button doesn't redirect after successful registration.
- Login page doesn't navigate on successful login.
- Routes are defined but not used in MaterialApp.
- AuthGuard is not set as initial route.

## Plan
1. Update app.dart to use routes and set initialRoute to authRedirect.
2. Add navigation in login_page.dart listener for AuthAuthenticated.
3. Add navigation in register_page.dart listener for AuthAuthenticated.
4. Uncomment pushNamed for register in login_page.dart.
5. Add profile_setup route if needed.
6. Test the app by running it.

## Steps
- [x] Update app.dart
- [x] Update login_page.dart
- [x] Update register_page.dart
- [ ] Update routes.dart if needed
- [x] Run the app to test

## Summary
- Fixed app.dart to use routes and set initialRoute to authRedirect.
- Added navigation on AuthAuthenticated in login_page.dart and register_page.dart.
- Enabled register button navigation in login_page.dart.
- Ran flutter analyze and flutter run --debug.
- The app should now properly redirect after successful registration and login.

## New Issue: AuthBloc Exception Handling
- AuthBloc was not handling exceptions from usecases, causing indefinite loading on login/register errors.

## Fix Applied
- Added try-catch blocks in AuthBloc _onLogin, _onRegister, and _onLogout methods to emit AuthError on exceptions.
- This ensures that on login/register failures, the UI shows an error message instead of staying in loading state.

## New Issue: AuthGuard Loading Indefinitely
- AuthGuard was using a mock FirebaseFirestore, and the real Firestore fetch was hanging or failing without error handling.

## Fix Applied
- Added cloud_firestore dependency.
- Uncommented the import for cloud_firestore in AuthGuard.
- Added error handling in AuthGuard FutureBuilder to show ProfileSetupPage on errors.
- Added timeout to login method to prevent indefinite hanging.
- This should allow the user to proceed to ProfileSetupPage if the Firestore document is missing or errors occur.
