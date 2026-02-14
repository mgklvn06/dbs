/* eslint-disable no-console */
const admin = require('firebase-admin');

function envInt(name, fallback) {
  const raw = process.env[name];
  if (!raw) return fallback;
  const n = parseInt(raw, 10);
  return Number.isFinite(n) ? n : fallback;
}

function envFlag(name) {
  const raw = (process.env[name] || '').trim().toLowerCase();
  return raw === '1' || raw === 'true' || raw === 'yes';
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

async function getOrCreateAuthUser(auth, { email, password, displayName, resetPassword }) {
  try {
    let record = await auth.getUserByEmail(email);
    const needsName = displayName && displayName !== record.displayName;
    const needsPassword = resetPassword && password;
    if (needsName || needsPassword) {
      record = await auth.updateUser(record.uid, {
        displayName: needsName ? displayName : record.displayName,
        password: needsPassword ? password : undefined,
      });
    }
    return { user: record, created: false, passwordKnown: needsPassword };
  } catch (e) {
    if (e.code === 'auth/user-not-found') {
      const record = await auth.createUser({
        email,
        password,
        displayName,
        emailVerified: true,
      });
      return { user: record, created: true, passwordKnown: true };
    }
    throw e;
  }
}

async function ensureUserDoc(db, user, { role, displayName, isAdmin }) {
  const name = displayName || user.displayName || 'User';
  await upsertWithTimestamps(db.collection('users').doc(user.uid), {
    uid: user.uid,
    email: user.email,
    displayName: name,
    photoUrl: user.photoURL || null,
    avatarUrl: user.photoURL || null,
    role,
    status: 'active',
    isAdmin: !!isAdmin,
    lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function ensureDoctorDoc(db, user, { name, specialty }) {
  await upsertWithTimestamps(db.collection('doctors').doc(user.uid), {
    userId: user.uid,
    name,
    specialty,
    bio: 'Experienced specialist.',
    email: user.email,
    photoUrl: user.photoURL || null,
    avatarUrl: user.photoURL || null,
    isActive: true,
  });
}

async function main() {
  const seedAuthUsers = envFlag('SEED_AUTH_USERS');
  const resetPasswords = envFlag('SEED_RESET_PASSWORDS');

  let adminEmail = pickAdminEmail();
  if (!adminEmail) {
    if (seedAuthUsers) {
      adminEmail = 'admin@example.com';
      console.warn('ADMIN_EMAIL not set. Using admin@example.com for seeded admin.');
    } else {
      console.error('Missing ADMIN_EMAIL or ADMIN_EMAILS env var.');
      process.exit(1);
    }
  }

  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });

  const db = admin.firestore();
  const auth = admin.auth();

  const adminPassword = process.env.SEED_ADMIN_PASSWORD || 'Admin123!';
  const doctorEmail = (process.env.SEED_DOCTOR_EMAIL || 'doctor@example.com').trim();
  const doctorPassword = process.env.SEED_DOCTOR_PASSWORD || 'Doctor123!';
  const patientEmail = (process.env.SEED_PATIENT_EMAIL || 'patient@example.com').trim();
  const patientPassword = process.env.SEED_PATIENT_PASSWORD || 'Patient123!';
  const adminName = process.env.SEED_ADMIN_NAME || 'Admin';
  const doctorName = process.env.SEED_DOCTOR_NAME || 'Dr. Seed Doctor';
  const patientName = process.env.SEED_PATIENT_NAME || 'Seed Patient';
  const doctorSpecialty = process.env.SEED_DOCTOR_SPECIALTY || 'Cardiology';

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

  const seedReport = [];
  const doctors = [];
  const users = [];

  console.log('Ensuring admin user doc...');
  let adminUser;
  if (seedAuthUsers) {
    const result = await getOrCreateAuthUser(auth, {
      email: adminEmail,
      password: adminPassword,
      displayName: adminName,
      resetPassword: resetPasswords,
    });
    adminUser = result.user;
    seedReport.push({
      label: 'Admin',
      email: adminEmail,
      password: adminPassword,
      passwordKnown: result.passwordKnown,
      created: result.created,
    });
  } else {
    adminUser = await auth.getUserByEmail(adminEmail);
  }
  await ensureUserDoc(db, adminUser, { role: 'admin', displayName: adminName, isAdmin: true });

  if (seedAuthUsers) {
    console.log('Seeding auth-backed doctor and patient users...');

    const doctorResult = await getOrCreateAuthUser(auth, {
      email: doctorEmail,
      password: doctorPassword,
      displayName: doctorName,
      resetPassword: resetPasswords,
    });
    await ensureUserDoc(db, doctorResult.user, { role: 'doctor', displayName: doctorName, isAdmin: false });
    await ensureDoctorDoc(db, doctorResult.user, { name: doctorName, specialty: doctorSpecialty });
    doctors.push({ id: doctorResult.user.uid, name: doctorName });
    seedReport.push({
      label: 'Doctor',
      email: doctorEmail,
      password: doctorPassword,
      passwordKnown: doctorResult.passwordKnown,
      created: doctorResult.created,
    });

    const patientResult = await getOrCreateAuthUser(auth, {
      email: patientEmail,
      password: patientPassword,
      displayName: patientName,
      resetPassword: resetPasswords,
    });
    await ensureUserDoc(db, patientResult.user, { role: 'user', displayName: patientName, isAdmin: false });
    users.push({ id: patientResult.user.uid, name: patientName });
    seedReport.push({
      label: 'Patient',
      email: patientEmail,
      password: patientPassword,
      passwordKnown: patientResult.passwordKnown,
      created: patientResult.created,
    });
  }

  const specialties = ['Cardiology', 'Dermatology', 'Neurology', 'Pediatrics', 'Orthopedics'];
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
  if (seedAuthUsers) {
    console.log('\nSeeded auth accounts:');
    for (const r of seedReport) {
      if (r.passwordKnown) {
        console.log(`- ${r.label}: ${r.email} / ${r.password}${r.created ? ' (created)' : ' (password set)'}`);
      } else {
        console.log(`- ${r.label}: ${r.email} / (password unchanged, set SEED_RESET_PASSWORDS=1 to reset)`);
      }
    }
  }
  await admin.app().delete();
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
