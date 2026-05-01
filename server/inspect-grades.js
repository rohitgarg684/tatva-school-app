const admin = require("firebase-admin");
const sa = require("/Users/rohitgarg/Downloads/tatva-school-app-firebase-adminsdk-fbsvc-9fb73ef449.json");
admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();

async function inspect() {
  // Find Arjun's user UID
  const userSnap = await db.collection("users")
    .where("name", "==", "Arjun Mehta")
    .where("role", "==", "Student").get();
  if (userSnap.empty) { console.log("Arjun not found"); process.exit(1); }
  const arjunUid = userSnap.docs[0].id;
  console.log(`Arjun UID: ${arjunUid}\n`);

  // Get all grades for Arjun
  const gradesSnap = await db.collection("grades")
    .where("studentUid", "==", arjunUid).get();
  console.log(`Total grade docs: ${gradesSnap.size}\n`);

  const byKey = {};
  for (const doc of gradesSnap.docs) {
    const d = doc.data();
    const key = `${d.subject}|${d.title}|${d.score}/${d.total}`;
    if (!byKey[key]) byKey[key] = [];
    byKey[key].push({ id: doc.id, classId: d.classId || "none" });
  }

  console.log("Grouped by (subject|title|score/total):");
  for (const [key, docs] of Object.entries(byKey)) {
    console.log(`  ${key} — ${docs.length} doc(s)${docs.length > 1 ? " *** DUPLICATE ***" : ""}`);
    if (docs.length > 1) {
      for (const d of docs) console.log(`    docId=${d.id} classId=${d.classId}`);
    }
  }

  process.exit(0);
}
inspect().catch(console.error);
