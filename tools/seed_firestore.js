/* eslint-disable no-console */
const admin = require('firebase-admin');

function envInt(name, fallback) {
  const raw = process.env[name];
  if (!raw) return fallback;
  const n = parseInt(raw, 10);
  return Number.isFinite(n) ? n : fallback;
}

function pickAdminEmail() {
  const direct = (process.env.ADMIN_EMAIL || '').trim();
  if (direct) return direct;
  const list = (process.env.ADMIN_EMAILS || '')
    .split(',')
    .map((v) => v.trim())
    .filter(Boolean);
  return list[0] || '';
}

function addDays(base, days) {
  const d = new Date(base.getTime());
  d.setDate(d.getDate() + days);
  return d;
}

function withTime(base, hour, minute) {
  const d = new Date(base.getTime());
  d.setHours(hour, minute, 0, 0);
  return d;
}

async function upsertWithTimestamps(ref, data) {
  const snap = await ref.get();
  const now = admin.firestore.FieldValue.serverTimestamp();
  const payload = { ...data, updatedAt: now };
  if (!snap.exists) payload.createdAt = now;
  await ref.set(payload, { merge: true });
}

async function main() {
  const adminEmail = pickAdminEmail();
  if (!adminEmail) {
    console.error('Missing ADMIN_EMAIL or ADMIN_EMAILS env var.');
    process.exit(1);
  }

  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });

  const db = admin.firestore();
  const auth = admin.auth();

  const seedDoctors = envInt('SEED_DOCTORS', 5);
  const seedUsers = envInt('SEED_USERS', 8);
  const seedAppointments = envInt('SEED_APPOINTMENTS', 12);
  const seedSlots = envInt('SEED_SLOTS_PER_DOCTOR', 6);

  const roles = [
    { id: 'admin', description: 'System administrator', permissions: ['manage_users', 'manage_doctors', 'manage_appointments'] },
    { id: 'doctor', description: 'Medical professional', permissions: ['manage_own_profile', 'manage_appointments'] },
    { id: 'user', description: 'Patient account', permissions: ['book_appointments'] },
  ];

  console.log('Seeding roles...');
  for (const r of roles) {
    await upsertWithTimestamps(db.collection('roles').doc(r.id), {
      description: r.description,
      permissions: r.permissions,
    });
  }

  console.log('Ensuring admin user doc...');
  const adminUser = await auth.getUserByEmail(adminEmail);
  await upsertWithTimestamps(db.collection('users').doc(adminUser.uid), {
    uid: adminUser.uid,
    email: adminUser.email,
    displayName: adminUser.displayName || 'Admin',
    photoUrl: adminUser.photoURL || null,
    avatarUrl: adminUser.photoURL || null,
    role: 'admin',
    status: 'active',
    isAdmin: true,
    lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const specialties = ['Cardiology', 'Dermatology', 'Neurology', 'Pediatrics', 'Orthopedics'];
  const doctors = [];
  console.log('Seeding doctors and doctor users...');
  for (let i = 0; i < seedDoctors; i += 1) {
    const uid = `doctor_${i + 1}`;
    const name = `Dr. Doctor ${i + 1}`;
    const specialty = specialties[i % specialties.length];
    const email = `doctor${i + 1}@example.com`;

    await upsertWithTimestamps(db.collection('users').doc(uid), {
      uid,
      email,
      displayName: name,
      photoUrl: null,
      avatarUrl: null,
      role: 'doctor',
      status: 'active',
      isAdmin: false,
      lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await upsertWithTimestamps(db.collection('doctors').doc(uid), {
      userId: uid,
      name,
      specialty,
      bio: 'Experienced specialist.',
      email,
      photoUrl: null,
      avatarUrl: null,
      isActive: true,
    });

    doctors.push({ id: uid, name });

    const start = addDays(new Date(), 1);
    for (let s = 0; s < seedSlots; s += 1) {
      const day = addDays(start, Math.floor(s / 3));
      const hour = 9 + (s % 3) * 2;
      const slotStart = withTime(day, hour, 0);
      const slotEnd = withTime(day, hour + 1, 0);
      const slotId = `slot_${day.toISOString().slice(0, 10)}_${hour}00`;
      await upsertWithTimestamps(
        db.collection('availability').doc(uid).collection('slots').doc(slotId),
        {
          startTime: admin.firestore.Timestamp.fromDate(slotStart),
          endTime: admin.firestore.Timestamp.fromDate(slotEnd),
          isBooked: false,
        }
      );
    }
  }

  const users = [];
  console.log('Seeding patient users...');
  for (let i = 0; i < seedUsers; i += 1) {
    const uid = `user_${i + 1}`;
    const name = `User ${i + 1}`;
    const email = `user${i + 1}@example.com`;
    await upsertWithTimestamps(db.collection('users').doc(uid), {
      uid,
      email,
      displayName: name,
      photoUrl: null,
      avatarUrl: null,
      role: 'user',
      status: 'active',
      isAdmin: false,
      lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    users.push({ id: uid, name });
  }

  console.log('Seeding appointments...');
  const statuses = ['pending', 'confirmed', 'completed', 'cancelled'];
  for (let i = 0; i < seedAppointments; i += 1) {
    const user = users[i % users.length];
    const doctor = doctors[i % doctors.length];
    const apptDate = addDays(new Date(), 2 + i);
    const apptTime = withTime(apptDate, 10 + (i % 4) * 2, 0);
    await db.collection('appointments').add({
      userId: user.id,
      doctorId: doctor.id,
      appointmentTime: admin.firestore.Timestamp.fromDate(apptTime),
      status: statuses[i % statuses.length],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  console.log('Seed complete.');
  await admin.app().delete();
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
