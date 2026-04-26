import { Response } from "express";
import { db } from "./firestore-helpers";
import { cacheDeletePrefix } from "./cache";
import { CollectionName } from "./collections";

export async function deleteDocument(
  collection: CollectionName,
  id: string,
  res: Response,
  cachePrefixes: string[] = []
): Promise<void> {
  const ref = db.collection(collection).doc(id);
  const snap = await ref.get();
  if (!snap.exists) {
    res.status(404).json({ error: "Not found" });
    return;
  }
  await ref.delete();
  for (const prefix of cachePrefixes) {
    cacheDeletePrefix(prefix);
  }
  res.json({ deleted: true });
}
