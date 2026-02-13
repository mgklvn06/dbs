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
$env:ADMIN_EMAIL="your-admin@email.com"
node tools/seed_firestore.js
```

## Optional Env Vars
- `ADMIN_EMAILS` (comma-separated list, uses the first one)
- `SEED_DOCTORS` (default 5)
- `SEED_USERS` (default 8)
- `SEED_APPOINTMENTS` (default 12)
- `SEED_SLOTS_PER_DOCTOR` (default 6)
