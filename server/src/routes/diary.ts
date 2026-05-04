import crypto from "crypto";
import { Router, Request, Response } from "express";
import * as admin from "firebase-admin";
import multer from "multer";
import { requireAuth, requireRole } from "../middleware/auth";
import { isValidDocument } from "../lib/file-validation";
import { db, getDoc, serializeDoc } from "../lib/firestore-helpers";
import { asyncHandler } from "../lib/async-handler";
import { Collections } from "../lib/collections";
import { env } from "../env";
import { DiaryAttachment } from "../models";

const DOC_MIME_TYPES = [
  "image/jpeg",
  "image/png",
  "image/gif",
  "image/webp",
  "application/pdf",
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  "application/vnd.openxmlformats-officedocument.presentationml.presentation",
];

const diaryUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (DOC_MIME_TYPES.includes(file.mimetype) || file.mimetype === "application/octet-stream") {
      cb(null, true);
    } else {
      cb(new Error(`Invalid file type: ${file.mimetype}. Allowed: images, PDF, DOCX, XLSX, PPTX.`));
    }
  },
});

function generateFileName(mimetype: string): string {
  const extMap: Record<string, string> = {
    "image/jpeg": "jpg", "image/png": "png", "image/gif": "gif", "image/webp": "webp",
    "application/pdf": "pdf",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document": "docx",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": "xlsx",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation": "pptx",
  };
  const ext = extMap[mimetype] || "bin";
  return `${Date.now()}_${Math.random().toString(36).slice(2, 8)}.${ext}`;
}

async function uploadToStorage(buffer: Buffer, storagePath: string, contentType: string): Promise<string> {
  const downloadToken = crypto.randomUUID();
  const bucket = admin.storage().bucket(env.storageBucket);
  const fileRef = bucket.file(storagePath);
  await fileRef.save(buffer, {
    metadata: { contentType, metadata: { firebaseStorageDownloadTokens: downloadToken } },
  });
  const encodedPath = encodeURIComponent(storagePath);
  return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodedPath}?alt=media&token=${downloadToken}`;
}

async function deleteFromStorage(storagePath: string): Promise<void> {
  const bucket = admin.storage().bucket(env.storageBucket);
  await bucket.file(storagePath).delete().catch(() => {});
}


const router = Router();
router.use(requireAuth);

// GET /diary/entries?studentUid=&date=YYYY-MM-DD
router.get(
  "/diary/entries",
  asyncHandler(async (req: Request, res: Response) => {
    const { studentUid, date } = req.query;
    if (!studentUid || !date) return res.status(400).json({ error: "studentUid and date required" });

    if (req.role === "Parent") {
      const parentDoc = await getDoc(Collections.USERS, req.uid!);
      const children: { childUid?: string }[] = parentDoc?.children || [];
      if (!children.some((c) => c.childUid === studentUid))
        return res.status(403).json({ error: "Access denied" });
    }

    const snap = await db.collection(Collections.DIARY_ENTRIES)
      .where("studentUid", "==", studentUid)
      .where("date", "==", date)
      .orderBy("createdAt", "desc")
      .get();

    const entries = snap.docs.map((d) => serializeDoc({ id: d.id, ...d.data() }));
    res.json({ entries });
  })
);

// GET /diary/dates?studentUid=&month=YYYY-MM — returns dates that have entries (for calendar dots)
router.get(
  "/diary/dates",
  asyncHandler(async (req: Request, res: Response) => {
    const { studentUid, month } = req.query;
    if (!studentUid || !month) return res.status(400).json({ error: "studentUid and month required" });

    const monthStr = month as string;
    const startDate = `${monthStr}-01`;
    const endDate = `${monthStr}-31`;

    const snap = await db.collection(Collections.DIARY_ENTRIES)
      .where("studentUid", "==", studentUid)
      .where("date", ">=", startDate)
      .where("date", "<=", endDate)
      .get();

    const dates = [...new Set(snap.docs.map((d) => d.data().date as string))];
    res.json({ dates });
  })
);

// GET /diary/entries/:id
router.get(
  "/diary/entries/:id",
  asyncHandler(async (req: Request, res: Response) => {
    const id = req.params.id as string;
    const doc = await getDoc(Collections.DIARY_ENTRIES, id);
    if (!doc) return res.status(404).json({ error: "Entry not found" });

    if (req.role === "Parent") {
      const parentDoc = await getDoc(Collections.USERS, req.uid!);
      const children: { childUid?: string }[] = parentDoc?.children || [];
      if (!children.some((c) => c.childUid === doc.studentUid))
        return res.status(403).json({ error: "Access denied" });
    }

    res.json({ entry: serializeDoc(doc) });
  })
);

// POST /diary/entries
router.post(
  "/diary/entries",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req: Request, res: Response) => {
    const { classId, studentUid, title, body } = req.body;
    if (!studentUid || !title || !body)
      return res.status(400).json({ error: "studentUid, title, and body required" });

    const [userDoc, studentDoc] = await Promise.all([
      getDoc(Collections.USERS, req.uid!),
      getDoc(Collections.USERS, studentUid),
    ]);
    const today = new Date().toISOString().split("T")[0];

    const ref = await db.collection(Collections.DIARY_ENTRIES).add({
      classId: classId || "",
      studentUid,
      studentName: studentDoc?.name || "Unknown",
      teacherUid: req.uid!,
      teacherName: userDoc?.name || "Unknown",
      date: today,
      title,
      body,
      attachments: [],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.json({ id: ref.id, created: true });
  })
);

// PUT /diary/entries/:id
router.put(
  "/diary/entries/:id",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req: Request, res: Response) => {
    const id = req.params.id as string;
    const doc = await getDoc(Collections.DIARY_ENTRIES, id);
    if (!doc) return res.status(404).json({ error: "Entry not found" });

    if (req.role !== "Principal" && doc.teacherUid !== req.uid!)
      return res.status(403).json({ error: "Can only edit your own entries" });

    const { title, body } = req.body;
    const updates: Record<string, any> = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };
    if (title) updates.title = title;
    if (body) updates.body = body;

    await db.collection(Collections.DIARY_ENTRIES).doc(id).update(updates);
    res.json({ updated: true });
  })
);

// DELETE /diary/entries/:id
router.delete(
  "/diary/entries/:id",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req: Request, res: Response) => {
    const id = req.params.id as string;
    const doc = await getDoc(Collections.DIARY_ENTRIES, id);
    if (!doc) return res.status(404).json({ error: "Entry not found" });

    if (req.role !== "Principal" && doc.teacherUid !== req.uid!)
      return res.status(403).json({ error: "Can only delete your own entries" });

    for (const att of (doc.attachments || []) as DiaryAttachment[]) {
      await deleteFromStorage(att.storagePath);
    }

    const commentsSnap = await db.collection(Collections.DIARY_COMMENTS)
      .where("entryId", "==", id).get();
    const batch = db.batch();
    for (const c of commentsSnap.docs) {
      const cData = c.data();
      for (const att of (cData.attachments || []) as DiaryAttachment[]) {
        await deleteFromStorage(att.storagePath);
      }
      batch.delete(c.ref);
    }
    batch.delete(db.collection(Collections.DIARY_ENTRIES).doc(id));
    await batch.commit();

    res.json({ deleted: true });
  })
);

// GET /diary/entries/:id/comments
router.get(
  "/diary/entries/:id/comments",
  asyncHandler(async (req: Request, res: Response) => {
    const id = req.params.id as string;
    const entry = await getDoc(Collections.DIARY_ENTRIES, id);
    if (!entry) return res.status(404).json({ error: "Entry not found" });

    if (req.role === "Parent") {
      const parentDoc = await getDoc(Collections.USERS, req.uid!);
      const children: { childUid?: string }[] = parentDoc?.children || [];
      if (!children.some((c) => c.childUid === entry.studentUid))
        return res.status(403).json({ error: "Access denied" });
    }

    const snap = await db.collection(Collections.DIARY_COMMENTS)
      .where("entryId", "==", id)
      .orderBy("createdAt", "asc")
      .get();

    const comments = snap.docs.map((d) => serializeDoc({ id: d.id, ...d.data() }));
    res.json({ comments });
  })
);

// POST /diary/entries/:id/comments
router.post(
  "/diary/entries/:id/comments",
  requireRole("Teacher", "Parent", "Principal"),
  asyncHandler(async (req: Request, res: Response) => {
    const id = req.params.id as string;
    const entry = await getDoc(Collections.DIARY_ENTRIES, id);
    if (!entry) return res.status(404).json({ error: "Entry not found" });

    if (req.role === "Parent") {
      const parentDoc = await getDoc(Collections.USERS, req.uid!);
      const children: { childUid?: string }[] = parentDoc?.children || [];
      if (!children.some((c) => c.childUid === entry.studentUid))
        return res.status(403).json({ error: "Access denied" });
    }

    const { body } = req.body;
    if (!body || typeof body !== "string")
      return res.status(400).json({ error: "body required" });

    const userDoc = await getDoc(Collections.USERS, req.uid!);

    const ref = await db.collection(Collections.DIARY_COMMENTS).add({
      entryId: id,
      authorUid: req.uid!,
      authorName: userDoc?.name || "Unknown",
      authorRole: req.role!,
      body,
      attachments: [],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.json({ id: ref.id, created: true });
  })
);

// DELETE /diary/comments/:id
router.delete(
  "/diary/comments/:id",
  asyncHandler(async (req: Request, res: Response) => {
    const id = req.params.id as string;
    const doc = await getDoc(Collections.DIARY_COMMENTS, id);
    if (!doc) return res.status(404).json({ error: "Comment not found" });

    if (req.role !== "Principal" && doc.authorUid !== req.uid!)
      return res.status(403).json({ error: "Can only delete your own comments" });

    for (const att of (doc.attachments || []) as DiaryAttachment[]) {
      await deleteFromStorage(att.storagePath);
    }

    await db.collection(Collections.DIARY_COMMENTS).doc(id).delete();
    res.json({ deleted: true });
  })
);

// POST /diary/entries/:id/upload — upload attachments to an entry (Teacher/Principal)
router.post(
  "/diary/entries/:id/upload",
  requireRole("Teacher", "Principal"),
  diaryUpload.array("files", 5),
  asyncHandler(async (req: Request, res: Response) => {
    const id = req.params.id as string;
    const entry = await getDoc(Collections.DIARY_ENTRIES, id);
    if (!entry) return res.status(404).json({ error: "Entry not found" });

    if (req.role !== "Principal" && entry.teacherUid !== req.uid!)
      return res.status(403).json({ error: "Can only upload to your own entries" });

    const files = req.files as Express.Multer.File[];
    if (!files || files.length === 0)
      return res.status(400).json({ error: "No files uploaded" });

    const uploaded: DiaryAttachment[] = [];
    for (const file of files) {
      if (!isValidDocument(file.buffer))
        return res.status(400).json({ error: `File "${file.originalname}" has invalid content` });

      const storagePath = `diary/${id}/attachments/${generateFileName(file.mimetype)}`;
      const url = await uploadToStorage(file.buffer, storagePath, file.mimetype);
      uploaded.push({ url, fileName: file.originalname, mimeType: file.mimetype, storagePath });
    }

    await db.collection(Collections.DIARY_ENTRIES).doc(id).update({
      attachments: admin.firestore.FieldValue.arrayUnion(...uploaded),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.json({ attachments: uploaded });
  })
);

// POST /diary/comments/:id/upload — upload attachments to a comment (owner only)
router.post(
  "/diary/comments/:id/upload",
  requireRole("Teacher", "Parent", "Principal"),
  diaryUpload.array("files", 3),
  asyncHandler(async (req: Request, res: Response) => {
    const id = req.params.id as string;
    const comment = await getDoc(Collections.DIARY_COMMENTS, id);
    if (!comment) return res.status(404).json({ error: "Comment not found" });

    if (req.role !== "Principal" && comment.authorUid !== req.uid!)
      return res.status(403).json({ error: "Can only upload to your own comments" });

    const files = req.files as Express.Multer.File[];
    if (!files || files.length === 0)
      return res.status(400).json({ error: "No files uploaded" });

    const uploaded: DiaryAttachment[] = [];
    for (const file of files) {
      if (!isValidDocument(file.buffer))
        return res.status(400).json({ error: `File "${file.originalname}" has invalid content` });

      const storagePath = `diary/comments/${id}/${generateFileName(file.mimetype)}`;
      const url = await uploadToStorage(file.buffer, storagePath, file.mimetype);
      uploaded.push({ url, fileName: file.originalname, mimeType: file.mimetype, storagePath });
    }

    await db.collection(Collections.DIARY_COMMENTS).doc(id).update({
      attachments: admin.firestore.FieldValue.arrayUnion(...uploaded),
    });

    res.json({ attachments: uploaded });
  })
);

// DELETE /diary/attachments — delete a specific attachment (owner check)
router.delete(
  "/diary/attachments",
  asyncHandler(async (req: Request, res: Response) => {
    const { entryId, commentId, storagePath } = req.body;
    if (!storagePath) return res.status(400).json({ error: "storagePath required" });

    if (entryId) {
      const entry = await getDoc(Collections.DIARY_ENTRIES, entryId);
      if (!entry) return res.status(404).json({ error: "Entry not found" });
      if (req.role !== "Principal" && entry.teacherUid !== req.uid!)
        return res.status(403).json({ error: "Cannot delete attachments from others' entries" });

      const attachments: DiaryAttachment[] = entry.attachments || [];
      const target = attachments.find((a) => a.storagePath === storagePath);
      if (!target) return res.status(404).json({ error: "Attachment not found" });

      await deleteFromStorage(storagePath);
      await db.collection(Collections.DIARY_ENTRIES).doc(entryId).update({
        attachments: admin.firestore.FieldValue.arrayRemove(target),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } else if (commentId) {
      const comment = await getDoc(Collections.DIARY_COMMENTS, commentId);
      if (!comment) return res.status(404).json({ error: "Comment not found" });
      if (req.role !== "Principal" && comment.authorUid !== req.uid!)
        return res.status(403).json({ error: "Cannot delete attachments from others' comments" });

      const attachments: DiaryAttachment[] = comment.attachments || [];
      const target = attachments.find((a) => a.storagePath === storagePath);
      if (!target) return res.status(404).json({ error: "Attachment not found" });

      await deleteFromStorage(storagePath);
      await db.collection(Collections.DIARY_COMMENTS).doc(commentId).update({
        attachments: admin.firestore.FieldValue.arrayRemove(target),
      });
    } else {
      return res.status(400).json({ error: "entryId or commentId required" });
    }

    res.json({ deleted: true });
  })
);

export default router;
