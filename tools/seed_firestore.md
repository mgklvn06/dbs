# Firestore Seed Script

This script seeds the Firestore structure for the medical booking system:
- roles
- users (admin, doctors, patients)
- doctors
- availability slots
- appointments

## Prerequisites
- Node.js installed
- Firebase Admin SDK credentials available via `GOOGLE_APPLICATION_CREDENTIALS`

## Install Dependency
```bash
npm i firebase-admin
```

## Run
```bash
# Windows PowerShell example
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\service-account.json"
$env:ADMIN_EMAIL="admin@example.com"
$env:SEED_AUTH_USERS="1"
$env:SEED_RESET_PASSWORDS="1"
$env:SEED_ADMIN_PASSWORD="Admin123!"
$env:SEED_DOCTOR_EMAIL="doctor@example.com"
$env:SEED_DOCTOR_PASSWORD="Doctor123!"
$env:SEED_PATIENT_EMAIL="patient@example.com"
$env:SEED_PATIENT_PASSWORD="Patient123!"
node tools/seed_firestore.js
```

## Optional Env Vars
- `ADMIN_EMAILS` (comma-separated list, uses the first one)
- `SEED_AUTH_USERS` (set to `1` to create auth-backed admin/doctor/patient users)
- `SEED_RESET_PASSWORDS` (set to `1` to reset passwords for existing users)
- `SEED_ADMIN_PASSWORD`
- `SEED_ADMIN_NAME`
- `SEED_DOCTOR_EMAIL`
- `SEED_DOCTOR_PASSWORD`
- `SEED_DOCTOR_NAME`
- `SEED_DOCTOR_SPECIALTY`
- `SEED_PATIENT_EMAIL`
- `SEED_PATIENT_PASSWORD`
- `SEED_PATIENT_NAME`
- `SEED_DOCTORS` (default 5)
- `SEED_USERS` (default 8)
- `SEED_APPOINTMENTS` (default 12)
- `SEED_SLOTS_PER_DOCTOR` (default 6)

## Notes
- To seed only the three login accounts, set `SEED_DOCTORS=0`, `SEED_USERS=0`, `SEED_APPOINTMENTS=0`, and `SEED_SLOTS_PER_DOCTOR=0`.
- The script prints the seeded credentials at the end when `SEED_AUTH_USERS=1`.
