/**
 * One-time migration: copies stories → announcements.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=path/to/key.json node migrate-stories-to-announcements.js
 *
 * Idempotent: skips docs that already have a matching announcement (by original story ID stored in `migratedFromStory`).
 * Delete this script after successful execution.
 */

const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

async function migrate() {
  const storiesSnap = await db.collection("stories").get();
  console.log(`Found ${storiesSnap.size} stories to migrate.`);

  if (storiesSnap.empty) {
    console.log("Nothing to migrate.");
    return;
  }

  const existingSnap = await db
    .collection("announcements")
    .where("migratedFromStory", "!=", null)
    .get();
  const alreadyMigrated = new Set(
    existingSnap.docs.map((d) => d.data().migratedFromStory)
  );

  let migrated = 0;
  let skipped = 0;

  const batch = db.batch();
  let batchCount = 0;

  for (const doc of storiesSnap.docs) {
    if (alreadyMigrated.has(doc.id)) {
      skipped++;
      continue;
    }

    const s = doc.data();

    const grade = await resolveGrade(s.classId);

    const annData = {
      title: (s.text || "").substring(0, 80) || "Class Story",
      body: s.text || "",
      audience: grade ? "Grades" : "Everyone",
      grades: grade ? [grade] : [],
      classIds: s.classId ? [s.classId] : [],
      createdBy: s.authorUid || "",
      createdByName: s.authorName || "",
      createdByRole: s.authorRole || "Teacher",
      likedBy: Array.isArray(s.likedBy) ? s.likedBy : [],
      commentCount: s.commentCount || 0,
      createdAt: s.createdAt || admin.firestore.FieldValue.serverTimestamp(),
      migratedFromStory: doc.id,
    };

    batch.set(db.collection("announcements").doc(), annData);
    batchCount++;
    migrated++;

    if (batchCount >= 450) {
      await batch.commit();
      console.log(`  Committed batch of ${batchCount}`);
      batchCount = 0;
    }
  }

  if (batchCount > 0) {
    await batch.commit();
    console.log(`  Committed final batch of ${batchCount}`);
  }

  console.log(`Migration complete. Migrated: ${migrated}, Skipped: ${skipped}`);
}

const gradeCache = new Map();

async function resolveGrade(classId) {
  if (!classId) return null;
  if (gradeCache.has(classId)) return gradeCache.get(classId);

  const classDoc = await db.collection("classes").doc(classId).get();
  const grade = classDoc.exists ? classDoc.data()?.grade || null : null;
  gradeCache.set(classId, grade);
  return grade;
}

migrate().catch((err) => {
  console.error("Migration failed:", err);
  process.exit(1);
});
