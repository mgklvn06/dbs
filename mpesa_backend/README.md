# DBS M-Pesa Backend (Daraja Sandbox)

Node.js service for:
- initiating STK Push (`POST /stkpush`)
- receiving Daraja callbacks (`POST /callback`)
- checking transaction status (`GET /transactions/:checkoutRequestId`)

## 1. Setup

```bash
cd mpesa_backend
npm install
cp .env.example .env
```

Fill `.env` values:
- `CONSUMER_KEY`
- `CONSUMER_SECRET`
- `SHORTCODE` (`174379` for sandbox)
- `PASSKEY`
- `CALLBACK_URL` (`https://<your-ngrok-subdomain>.ngrok-free.app/callback`)

Optional but recommended for persisted status:
- configure Firebase Admin credentials via:
  - `GOOGLE_APPLICATION_CREDENTIALS`, or
  - `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`

If Firestore credentials are missing, status is kept in memory for local testing.

## 2. Run

```bash
npm run dev
```

Health check:

```bash
GET http://localhost:3000/health
```

## 3. Expose with ngrok

```bash
ngrok http 3000
```

Take the HTTPS URL and set:

```env
CALLBACK_URL=https://<your-ngrok-subdomain>.ngrok-free.app/callback
```

Restart the backend after changing `.env`.

## 4. Test STK Push

Endpoint:

```http
POST https://<your-ngrok-subdomain>.ngrok-free.app/stkpush
Content-Type: application/json
```

Body:

```json
{
  "phone": "254708374149",
  "amount": 1,
  "userId": "firebase-user-id",
  "doctorId": "doctor-id",
  "slotId": "slot-id"
}
```

Check status:

```http
GET https://<your-ngrok-subdomain>.ngrok-free.app/transactions/<CheckoutRequestID>
```

Result codes:
- `0`: success
- `1032`: cancelled by user
- `1037`: timeout
- other: failed

## 5. Flutter app integration

Run Flutter with backend base URL:

```bash
flutter run --dart-define=MPESA_BACKEND_BASE_URL=https://<your-ngrok-subdomain>.ngrok-free.app
```
