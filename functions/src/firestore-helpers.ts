import * as admin from "firebase-admin";

const db = admin.firestore();

export { db };

export async function getDoc(
  collection: string,
  id: string
): Promise<Record<string, any> | null> {
  const snap = await db.collection(collection).doc(id).get();
  return snap.exists ? { id: snap.id, ...snap.data()! } : null;
}

export async function getDocs(
  collection: string,
  ids: string[]
): Promise<Record<string, any>[]> {
  if (ids.length === 0) return [];
  const refs = ids.map((id) => db.collection(collection).doc(id));
  const snaps = await db.getAll(...refs);
  return snaps
    .filter((s) => s.exists)
    .map((s) => ({ id: s.id, ...s.data()! }));
}

export async function queryDocs(
  collection: string,
  constraints: Array<{
    field: string;
    op: FirebaseFirestore.WhereFilterOp;
    value: any;
  }>,
  orderBy?: { field: string; direction?: "asc" | "desc" },
  limit?: number
) {
  let ref: FirebaseFirestore.Query = db.collection(collection);
  for (const c of constraints) {
    ref = ref.where(c.field, c.op, c.value);
  }
  if (orderBy) {
    ref = ref.orderBy(orderBy.field, orderBy.direction ?? "asc");
  }
  if (limit) {
    ref = ref.limit(limit);
  }
  const snap = await ref.get();
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

export function timestampToIso(val: any): string | null {
  if (!val) return null;
  if (val.toDate) return val.toDate().toISOString();
  if (val instanceof Date) return val.toISOString();
  return String(val);
}

export function serializeDocs(docs: any[]): any[] {
  return docs.map(serializeDoc);
}

export function serializeDoc(doc: any): any {
  if (!doc) return null;
  const result: any = {};
  for (const [key, value] of Object.entries(doc)) {
    if (value && typeof value === "object" && "toDate" in (value as any)) {
      result[key] = (value as any).toDate().toISOString();
    } else if (Array.isArray(value)) {
      result[key] = value.map((v) =>
        v && typeof v === "object" && "toDate" in v
          ? v.toDate().toISOString()
          : v
      );
    } else {
      result[key] = value;
    }
  }
  return result;
}
