# dbs

DBS is a Flutter-based doctor booking system I built with Firebase (Auth + Firestore) and an M-Pesa Daraja sandbox backend.

## M-Pesa Payments (Daraja Sandbox)

This repo includes a dedicated backend at `mpesa_backend/` for STK Push.

Start Flutter with the backend URL:

```bash
flutter run --dart-define=MPESA_BACKEND_BASE_URL=https://your-ngrok-subdomain.ngrok-free.app
```

See `mpesa_backend/README.md` for full setup (Daraja credentials, ngrok callback, and status polling).

For local dev startup in one command:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\start_mpesa_backend.ps1
```

## Project Testing, Error Handling, and Development Journey

### 1. How I tested this project

I used a mix of automated tests and manual end-to-end checks.

- I wrote and ran `test/booking_bloc_test.dart` to confirm booking state transitions are correct.
- I used `test/widget_test.dart` as a UI smoke test to verify the app shell renders with `AppBackground` and `AppCard`.
- I manually tested key flows repeatedly: sign in, booking creation, appointment status updates, and help center navigation.
- For M-Pesa, I tested the full sandbox loop: `/stkpush` initiation, `/callback` processing, and `/transactions/:checkoutRequestId` polling until a terminal status.
- After every bug fix, I reran the affected flow and then did a quick regression pass on booking and payment paths.

### 2. How I handled errors

My approach was to fail clearly, show useful messages, and keep the app usable.

- On Flutter, I mapped raw Firebase auth errors to user-friendly messages in `lib/core/utils/firebase_error_mapper.dart`.
- I separated failure types in `lib/core/errors/failures.dart` (`ServerFailure`, `NetworkFailure`, `AuthFailure`) so error sources stay explicit.
- On the backend (`mpesa_backend/server.js`), I added defensive validation before calling Daraja:
  - reject missing or placeholder environment values
  - reject invalid phone and amount inputs with clear `400` responses
  - wrap third-party call failures and return safe, readable details
- I normalized Daraja result codes into app states:
  - `0 -> success`
  - `1032 -> cancelled`
  - `1037 -> timeout`
  - any other result code -> `failed`
- I also kept a resilience fallback: if Firestore admin credentials are missing, transaction status is stored in memory so local testing can still continue.

### 3. Development journey

This project started as a basic Flutter booking flow, then I expanded it in layers.

1. I built the booking foundation first (entities, repositories, bloc-driven state updates).
2. I integrated Firebase auth and Firestore so user, doctor, and appointment data could flow end to end.
3. I introduced the Node.js Daraja backend for STK Push and callback handling.
4. I hardened the system by improving validation, callback handling, and backend error reporting.
5. I polished UX with clearer help/troubleshooting content and more user-friendly error messages.

The biggest lesson for me was that payment features are mostly about reliability and visibility, not just making one API call. Most of the real work was in edge cases, callback/state consistency, and repeating tests until behavior was stable.

## Quick Start

```bash
flutter pub get
flutter test
```

Run Flutter with backend URL:

```bash
flutter run --dart-define=MPESA_BACKEND_BASE_URL=https://your-ngrok-subdomain.ngrok-free.app
```

Backend setup details are in `mpesa_backend/README.md`.
