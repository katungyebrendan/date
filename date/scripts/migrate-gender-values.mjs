#!/usr/bin/env node
import admin from 'firebase-admin';

function parseArgs(argv) {
  const flags = new Set(argv.slice(2));
  return {
    dryRun: !flags.has('--apply'),
  };
}

function normalizeGender(value) {
  if (typeof value !== 'string') return null;
  const v = value.toLowerCase();
  if (v === 'male' || v === 'man') return 'male';
  if (v === 'female' || v === 'woman') return 'female';
  return null;
}

function normalizeInterestedIn(values) {
  if (!Array.isArray(values)) return null;
  const normalized = values
    .map(normalizeGender)
    .filter((v) => v === 'male' || v === 'female');
  return Array.from(new Set(normalized));
}

const { dryRun } = parseArgs(process.argv);

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('GOOGLE_APPLICATION_CREDENTIALS is not set.');
  console.error('Set it to your service account JSON path before running this script.');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();
const usersRef = db.collection('users');

let scanned = 0;
let changed = 0;
let skipped = 0;

const snapshot = await usersRef.get();

for (const doc of snapshot.docs) {
  scanned += 1;
  const data = doc.data();

  const currentGender = data.gender;
  const currentInterestedIn = data.interestedIn;

  const nextGender = normalizeGender(currentGender);
  const nextInterestedIn = normalizeInterestedIn(currentInterestedIn);

  const patch = {};

  if (nextGender && nextGender !== currentGender) {
    patch.gender = nextGender;
  }

  if (nextInterestedIn) {
    const sameLength = Array.isArray(currentInterestedIn) && currentInterestedIn.length === nextInterestedIn.length;
    const sameValues = sameLength && currentInterestedIn.every((v, i) => v === nextInterestedIn[i]);
    if (!sameValues) {
      patch.interestedIn = nextInterestedIn;
    }
  }

  if (Object.keys(patch).length === 0) {
    skipped += 1;
    continue;
  }

  changed += 1;

  if (dryRun) {
    console.log(`[DRY RUN] users/${doc.id}`, patch);
  } else {
    await doc.ref.update(patch);
    console.log(`[UPDATED] users/${doc.id}`, patch);
  }
}

console.log('---');
console.log(`Users scanned: ${scanned}`);
console.log(`Users changed: ${changed}`);
console.log(`Users unchanged: ${skipped}`);
console.log(dryRun ? 'Dry run complete. Re-run with --apply to write changes.' : 'Migration complete.');
