const express = require("express");
const axios = require("axios");
const bodyParser = require("body-parser");
const moment = require("moment");
const cors = require("cors");
const admin = require("firebase-admin");
require("dotenv").config();

const app = express();
app.use(cors());
app.use(bodyParser.json({ limit: "256kb" }));

const {
  PORT = "3000",
  CONSUMER_KEY,
  CONSUMER_SECRET,
  SHORTCODE,
  PASSKEY,
  CALLBACK_URL,
  ACCOUNT_REFERENCE = "MEDICAL_APP",
  TRANSACTION_DESC = "Appointment Payment",
} = process.env;

const transactionStore = new Map();

function initializeFirestore() {
  try {
    if (admin.apps.length > 0) {
      return admin.firestore();
    }

    if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      admin.initializeApp();
      return admin.firestore();
    }

    const projectId = process.env.FIREBASE_PROJECT_ID;
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
    const privateKey = process.env.FIREBASE_PRIVATE_KEY;

    if (projectId && clientEmail && privateKey) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId,
          clientEmail,
          privateKey: privateKey.replace(/\\n/g, "\n"),
        }),
      });
      return admin.firestore();
    }

    console.warn(
      "[Firestore] Credentials not configured. Falling back to in-memory transaction storage."
    );
    return null;
  } catch (error) {
    console.error("[Firestore] Initialization failed:", error.message);
    return null;
  }
}

const firestore = initializeFirestore();

function isTerminalStatus(status) {
  return status === "success" || status === "failed" || status === "cancelled" || status === "timeout";
}

function statusFromResultCode(resultCode) {
  if (resultCode === 0) return "success";
  if (resultCode === 1032) return "cancelled";
  if (resultCode === 1037) return "timeout";
  return "failed";
}

function normalizePhone(raw) {
  const digits = String(raw || "").replace(/\D/g, "");
  if (digits.startsWith("254") && digits.length === 12) return digits;
  if (digits.startsWith("0") && digits.length === 10) return `254${digits.slice(1)}`;
  if (digits.startsWith("7") && digits.length === 9) return `254${digits}`;
  return null;
}

function parseCallbackMetadata(callbackMetadata) {
  const items = callbackMetadata && Array.isArray(callbackMetadata.Item)
    ? callbackMetadata.Item
    : [];

  const metadata = {};
  for (const item of items) {
    if (!item || typeof item.Name !== "string") continue;
    metadata[item.Name] = item.Value;
  }
  return metadata;
}

function requiredConfigMissing() {
  const missing = [];
  if (!CONSUMER_KEY) missing.push("CONSUMER_KEY");
  if (!CONSUMER_SECRET) missing.push("CONSUMER_SECRET");
  if (!SHORTCODE) missing.push("SHORTCODE");
  if (!PASSKEY) missing.push("PASSKEY");
  if (!CALLBACK_URL) missing.push("CALLBACK_URL");
  return missing;
}

function looksLikePlaceholder(value) {
  if (typeof value !== "string") return false;
  const normalized = value.trim().toLowerCase();
  if (!normalized) return false;
  return (
    normalized.includes("your_") ||
    normalized.includes("your-") ||
    normalized.includes("your ") ||
    normalized.includes("<your") ||
    normalized.includes("replace") ||
    normalized.includes("example")
  );
}

function invalidConfigEntries() {
  const invalid = [];
  if (looksLikePlaceholder(CONSUMER_KEY)) invalid.push("CONSUMER_KEY");
  if (looksLikePlaceholder(CONSUMER_SECRET)) invalid.push("CONSUMER_SECRET");
  if (looksLikePlaceholder(PASSKEY)) invalid.push("PASSKEY");
  if (looksLikePlaceholder(CALLBACK_URL)) invalid.push("CALLBACK_URL");

  if (SHORTCODE && !/^\d+$/.test(String(SHORTCODE).trim())) {
    invalid.push("SHORTCODE");
  }
  if (CALLBACK_URL) {
    const callback = String(CALLBACK_URL).trim();
    if (/\s/.test(callback)) {
      invalid.push("CALLBACK_URL");
    } else {
      try {
        const parsed = new URL(callback);
        const hasHttps = parsed.protocol === "https:";
        const hasHost = typeof parsed.hostname === "string" && parsed.hostname.length > 0;
        const hasCallbackPath = parsed.pathname.toLowerCase().endsWith("/callback");
        if (!hasHttps || !hasHost || !hasCallbackPath) {
          invalid.push("CALLBACK_URL");
        }
      } catch (_) {
        invalid.push("CALLBACK_URL");
      }
    }
  }
  return [...new Set(invalid)];
}

function configStatus() {
  const missing = requiredConfigMissing();
  const invalid = invalidConfigEntries();
  return {
    ready: missing.length === 0 && invalid.length === 0,
    missing,
    invalid,
  };
}

function stringifySafe(value) {
  try {
    return JSON.stringify(value);
  } catch (_) {
    return String(value);
  }
}

function extractErrorDetails(error) {
  const data = error?.response?.data;
  if (typeof data === "string" && data.trim().length > 0) return data;
  if (data && typeof data.errorMessage === "string") return data.errorMessage;
  if (data && typeof data.error === "string") return data.error;
  if (data && typeof data.ResponseDescription === "string") {
    return data.ResponseDescription;
  }
  if (data != null) return stringifySafe(data);
  if (typeof error?.message === "string") return error.message;
  return "Unknown backend error.";
}

async function saveTransaction(record) {
  const nowIso = new Date().toISOString();
  const checkoutRequestId =
    typeof record.checkoutRequestId === "string" && record.checkoutRequestId.trim().length > 0
      ? record.checkoutRequestId.trim()
      : null;
  const merchantRequestId =
    typeof record.merchantRequestId === "string" && record.merchantRequestId.trim().length > 0
      ? record.merchantRequestId.trim()
      : null;

  const memoryKey = checkoutRequestId || `merchant-${merchantRequestId || Date.now()}`;
  const existing = transactionStore.get(memoryKey) || {};

  const merged = {
    ...existing,
    ...record,
    checkoutRequestId: checkoutRequestId || existing.checkoutRequestId || null,
    merchantRequestId: merchantRequestId || existing.merchantRequestId || null,
    createdAt: existing.createdAt || record.createdAt || nowIso,
    updatedAt: nowIso,
  };

  transactionStore.set(memoryKey, merged);

  if (firestore && merged.checkoutRequestId) {
    await firestore
      .collection("mpesa_transactions")
      .doc(merged.checkoutRequestId)
      .set(merged, { merge: true });
  }

  return merged;
}

async function findTransaction(checkoutRequestId) {
  const local = transactionStore.get(checkoutRequestId);
  if (local) return local;

  if (!firestore) return null;

  const snap = await firestore
    .collection("mpesa_transactions")
    .doc(checkoutRequestId)
    .get();
  if (!snap.exists) return null;
  return snap.data();
}

async function getAccessToken() {
  const auth = Buffer.from(`${CONSUMER_KEY}:${CONSUMER_SECRET}`).toString("base64");
  const response = await axios.get(
    "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials",
    {
      headers: {
        Authorization: `Basic ${auth}`,
      },
      timeout: 30000,
    }
  );
  const token =
    response &&
    response.data &&
    typeof response.data.access_token === "string"
      ? response.data.access_token.trim()
      : "";
  if (!token) {
    throw new Error(
      `Failed to obtain Daraja access token. Response: ${stringifySafe(
        response?.data
      )}`
    );
  }
  return token;
}

app.get("/health", (_req, res) => {
  const cfg = configStatus();
  res.status(200).json({
    ok: true,
    firestoreEnabled: Boolean(firestore),
    config: cfg,
  });
});

app.post("/stkpush", async (req, res) => {
  try {
    const missing = requiredConfigMissing();
    if (missing.length > 0) {
      return res.status(500).json({
        error: `Missing required configuration: ${missing.join(", ")}`,
      });
    }
    const invalid = invalidConfigEntries();
    if (invalid.length > 0) {
      return res.status(500).json({
        error: `Invalid configuration values: ${invalid.join(", ")}`,
      });
    }

    const { phone, amount, userId, doctorId, slotId, accountReference, transactionDesc } = req.body || {};

    const normalizedPhone = normalizePhone(phone);
    if (!normalizedPhone) {
      return res.status(400).json({
        error: "Invalid phone. Use 2547XXXXXXXX format (or 07XXXXXXXX).",
      });
    }

    const amountNumber = Number(amount);
    if (!Number.isFinite(amountNumber) || amountNumber <= 0) {
      return res.status(400).json({ error: "Amount must be a number greater than 0." });
    }

    const token = await getAccessToken();
    const timestamp = moment().format("YYYYMMDDHHmmss");
    const password = Buffer.from(`${SHORTCODE}${PASSKEY}${timestamp}`).toString("base64");

    const darajaResponse = await axios.post(
      "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest",
      {
        BusinessShortCode: SHORTCODE,
        Password: password,
        Timestamp: timestamp,
        TransactionType: "CustomerPayBillOnline",
        Amount: Math.round(amountNumber),
        PartyA: normalizedPhone,
        PartyB: SHORTCODE,
        PhoneNumber: normalizedPhone,
        CallBackURL: CALLBACK_URL,
        AccountReference: (accountReference || ACCOUNT_REFERENCE).toString(),
        TransactionDesc: (transactionDesc || TRANSACTION_DESC).toString(),
      },
      {
        headers: {
          Authorization: `Bearer ${token}`,
        },
        timeout: 30000,
      }
    );

    const payload = darajaResponse.data || {};

    const record = await saveTransaction({
      provider: "mpesa",
      status: "pending",
      userId: userId || null,
      doctorId: doctorId || null,
      slotId: slotId || null,
      amount: Math.round(amountNumber),
      phone: normalizedPhone,
      merchantRequestId: payload.MerchantRequestID || null,
      checkoutRequestId: payload.CheckoutRequestID || null,
      responseCode: payload.ResponseCode || null,
      responseDescription: payload.ResponseDescription || null,
      customerMessage: payload.CustomerMessage || null,
      rawInitiateResponse: payload,
    });

    return res.status(200).json({
      success: true,
      message: "STK Push initiated.",
      transaction: record,
    });
  } catch (error) {
    const details = extractErrorDetails(error);
    console.error("STK push failed:", details);
    return res.status(500).json({
      success: false,
      error: "STK Push failed",
      details,
    });
  }
});

app.post("/callback", async (req, res) => {
  try {
    console.log("M-Pesa callback payload:", JSON.stringify(req.body, null, 2));

    const stkCallback = req.body?.Body?.stkCallback;
    if (!stkCallback) {
      return res.status(400).json({ error: "Invalid callback payload." });
    }

    const metadata = parseCallbackMetadata(stkCallback.CallbackMetadata);
    const resultCode = Number(stkCallback.ResultCode);
    const status = statusFromResultCode(Number.isNaN(resultCode) ? -1 : resultCode);

    await saveTransaction({
      status,
      resultCode: Number.isNaN(resultCode) ? null : resultCode,
      resultDesc: stkCallback.ResultDesc || null,
      merchantRequestId: stkCallback.MerchantRequestID || null,
      checkoutRequestId: stkCallback.CheckoutRequestID || null,
      mpesaReceiptNumber: metadata.MpesaReceiptNumber || null,
      callbackAmount: metadata.Amount ?? null,
      callbackPhone: metadata.PhoneNumber ? String(metadata.PhoneNumber) : null,
      callbackTransactionDate: metadata.TransactionDate
        ? String(metadata.TransactionDate)
        : null,
      rawCallback: req.body,
    });

    return res.status(200).json({ ResultCode: 0, ResultDesc: "Accepted" });
  } catch (error) {
    console.error("Callback handling failed:", error.response?.data || error.message);
    return res.status(500).json({ error: "Callback processing failed." });
  }
});

app.get("/transactions/:checkoutRequestId", async (req, res) => {
  try {
    const checkoutRequestId = String(req.params.checkoutRequestId || "").trim();
    if (!checkoutRequestId) {
      return res.status(400).json({ error: "checkoutRequestId is required." });
    }

    const transaction = await findTransaction(checkoutRequestId);
    if (!transaction) {
      return res.status(404).json({ error: "Transaction not found." });
    }

    return res.status(200).json({
      success: true,
      terminal: isTerminalStatus(transaction.status),
      transaction,
    });
  } catch (error) {
    console.error("Transaction fetch failed:", error.message);
    return res.status(500).json({ error: "Failed to fetch transaction." });
  }
});

const server = app.listen(Number(PORT), () => {
  console.log(`M-Pesa backend running on port ${PORT}`);
  console.log(`Callback URL configured as: ${CALLBACK_URL || "(not set)"}`);
  const cfg = configStatus();
  if (!cfg.ready) {
    console.warn(
      `Daraja config not ready. Missing: ${cfg.missing.join(", ") || "none"}; Invalid: ${cfg.invalid.join(", ") || "none"}`
    );
  }
});

server.on("error", (error) => {
  if (error && error.code === "EADDRINUSE") {
    console.error(
      `Port ${PORT} is already in use. Stop the existing process or set PORT in .env.`
    );
    process.exit(1);
  }
  console.error("Server startup error:", error);
  process.exit(1);
});
