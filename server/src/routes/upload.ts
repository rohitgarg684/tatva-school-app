import crypto from "crypto";
import { Router, Request, Response } from "express";
import * as admin from "firebase-admin";
import multer from "multer";
import { requireAuth, requireRole } from "../middleware/auth";
import { isValidImage, isValidDocument } from "../lib/file-validation";
import { db, serializeDocs } from "../lib/firestore-helpers";
import { cacheDeletePrefix } from "../lib/cache";
import { asyncHandler } from "../lib/async-handler";
import { Collections } from "../lib/collections";
import { env } from "../env";
import { Config } from "../lib/config";

const IMAGE_MIME_TYPES = [
  "image/jpeg",
  "image/png",
  "image/gif",
  "image/webp",
];

const imageUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: Config.MAX_IMAGE_SIZE },
  fileFilter: (_req, file, cb) => {
    if (IMAGE_MIME_TYPES.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error(`Invalid image type: ${file.mimetype}. Allowed: JPEG, PNG, GIF, WebP.`));
    }
  },
});

const DOC_MIME_TYPES = [
  ...IMAGE_MIME_TYPES,
  "application/pdf",
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  "application/vnd.openxmlformats-officedocument.presentationml.presentation",
];

const docUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: Config.MAX_DOC_SIZE },
  fileFilter: (_req, file, cb) => {
    if (DOC_MIME_TYPES.includes(file.mimetype) || file.mimetype === "application/octet-stream") {
      cb(null, true);
    } else {
      cb(new Error(`Invalid file type: ${file.mimetype}. Allowed: images, PDF, DOCX, XLSX, PPTX.`));
    }
  },
});

function sanitizeId(val: string): string {
  return val.replace(/[^a-zA-Z0-9_-]/g, "_");
}

function generateFileName(mimetype: string): string {
  const extMap: Record<string, string> = {
    "image/jpeg": "jpg",
    "image/png": "png",
    "image/gif": "gif",
    "image/webp": "webp",
    "application/pdf": "pdf",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document": "docx",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": "xlsx",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation": "pptx",
    "video/mp4": "mp4",
    "video/quicktime": "mov",
    "video/x-msvideo": "avi",
    "video/webm": "webm",
    "audio/mpeg": "mp3",
    "audio/wav": "wav",
    "audio/aac": "aac",
    "audio/ogg": "ogg",
    "audio/mp4": "m4a",
    "audio/flac": "flac",
  };
  const ext = extMap[mimetype] || "bin";
  return `${Date.now()}_${Math.random().toString(36).slice(2, 8)}.${ext}`;
}

async function uploadToStorage(buffer: Buffer, storagePath: string, contentType: string): Promise<string> {
  const downloadToken = crypto.randomUUID();
  const bucket = admin.storage().bucket(env.storageBucket);
  const fileRef = bucket.file(storagePath);
  await fileRef.save(buffer, {
    metadata: {
      contentType,
      metadata: { firebaseStorageDownloadTokens: downloadToken },
    },
  });
  const encodedPath = encodeURIComponent(storagePath);
  return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodedPath}?alt=media&token=${downloadToken}`;
}

function classifyFileType(originalname: string): string {
  const ext = originalname.split(".").pop()?.toLowerCase() || "";
  if (ext === "pdf") return "pdf";
  if (["jpg", "jpeg", "png", "gif", "webp", "bmp"].includes(ext)) return "image";
  if (["mp4", "mov", "avi", "mkv", "webm"].includes(ext)) return "video";
  if (["mp3", "wav", "aac", "ogg", "m4a", "flac"].includes(ext)) return "audio";
  return "document";
}

const ATTACHMENT_MIME_TYPES = [
  ...IMAGE_MIME_TYPES,
  "application/pdf",
  "video/mp4", "video/quicktime", "video/x-msvideo", "video/webm",
  "audio/mpeg", "audio/wav", "audio/aac", "audio/ogg", "audio/mp4", "audio/flac",
];

const attachmentUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 50 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (ATTACHMENT_MIME_TYPES.includes(file.mimetype) || file.mimetype === "application/octet-stream") {
      cb(null, true);
    } else {
      cb(new Error(`Invalid file type: ${file.mimetype}.`));
    }
  },
});

function handleMulterError(err: any, res: Response): boolean {
  if (err instanceof multer.MulterError) {
    if (err.code === "LIMIT_FILE_SIZE") {
      res.status(413).json({ error: "File too large." });
      return true;
    }
    res.status(400).json({ error: err.message });
    return true;
  }
  if (err?.message?.startsWith("Invalid")) {
    res.status(400).json({ error: err.message });
    return true;
  }
  return false;
}

const router = Router();
router.use(requireAuth);

router.post(
  "/document/upload",
  requireRole("Teacher", "Principal"),
  docUpload.single("file"),
  async (req: Request, res: Response) => {
    try {
      if (!req.file) return res.status(400).json({ error: "No file uploaded" });
      if (!isValidDocument(req.file.buffer))
        return res.status(400).json({ error: "File content does not match a valid document format" });

      const classId = req.body.classId;
      if (!classId || typeof classId !== "string")
        return res.status(400).json({ error: "classId required" });

      const storagePath = `documents/${sanitizeId(classId)}/${generateFileName(req.file.mimetype)}`;
      const url = await uploadToStorage(req.file.buffer, storagePath, req.file.mimetype);
      res.json({ url, path: storagePath });
    } catch (err: any) {
      if (handleMulterError(err, res)) return;
      console.error("document upload error:", err);
      res.status(500).json({ error: err.message || "Internal server error" });
    }
  }
);

router.post(
  "/announcement/upload",
  requireRole("Teacher", "Principal"),
  attachmentUpload.array("files", 10),
  async (req: Request, res: Response) => {
    try {
      const files = req.files as Express.Multer.File[];
      if (!files || files.length === 0)
        return res.status(400).json({ error: "No files uploaded" });

      const uploaded: { url: string; name: string; type: string }[] = [];
      for (const file of files) {
        const storagePath = `announcements/${generateFileName(file.mimetype)}`;
        const url = await uploadToStorage(file.buffer, storagePath, file.mimetype);
        uploaded.push({ url, name: file.originalname, type: classifyFileType(file.originalname) });
      }

      res.json({ attachments: uploaded });
    } catch (err: any) {
      if (handleMulterError(err, res)) return;
      console.error("announcement upload error:", err);
      res.status(500).json({ error: err.message || "Internal server error" });
    }
  }
);

router.post(
  "/homework/:id/upload",
  requireRole("Teacher", "Principal"),
  docUpload.array("files", Config.MAX_UPLOAD_FILES),
  async (req: Request, res: Response) => {
    try {
      const homeworkId = sanitizeId(req.params.id as string);
      const files = req.files as Express.Multer.File[];
      if (!files || files.length === 0)
        return res.status(400).json({ error: "No files uploaded" });

      const uploaded: { url: string; name: string; type: string }[] = [];
      for (const file of files) {
        if (!isValidDocument(file.buffer))
          return res.status(400).json({ error: `File "${file.originalname}" has invalid content` });

        const storagePath = `homework/${homeworkId}/attachments/${generateFileName(file.mimetype)}`;
        const url = await uploadToStorage(file.buffer, storagePath, file.mimetype);
        uploaded.push({ url, name: file.originalname, type: classifyFileType(file.originalname) });
      }

      await db.collection(Collections.HOMEWORK).doc(homeworkId).update({
        attachments: admin.firestore.FieldValue.arrayUnion(...uploaded),
      });

      cacheDeletePrefix("teacher_dash_");
      cacheDeletePrefix("student_dash_");
      res.json({ uploaded });
    } catch (err: any) {
      if (handleMulterError(err, res)) return;
      console.error("homework upload error:", err);
      res.status(500).json({ error: err.message || "Internal server error" });
    }
  }
);

router.post(
  "/homework/:id/submit-files",
  requireRole("Student"),
  docUpload.array("files", Config.MAX_UPLOAD_FILES),
  async (req: Request, res: Response) => {
    try {
      const homeworkId = sanitizeId(req.params.id as string);
      const uid = req.uid!;
      const files = req.files as Express.Multer.File[];
      const note = (req.body.note as string) || "";

      const fileUrls: { url: string; name: string; type: string }[] = [];
      if (files && files.length > 0) {
        for (const file of files) {
          if (!isValidDocument(file.buffer))
            return res.status(400).json({ error: `File "${file.originalname}" has invalid content` });

          const storagePath = `homework/${homeworkId}/submissions/${sanitizeId(uid)}/${generateFileName(file.mimetype)}`;
          const url = await uploadToStorage(file.buffer, storagePath, file.mimetype);
          fileUrls.push({ url, name: file.originalname, type: classifyFileType(file.originalname) });
        }
      }

      const subRef = db.collection(Collections.HOMEWORK_SUBMISSIONS).doc(`${homeworkId}_${uid}`);
      await subRef.set(
        {
          homeworkId,
          studentUid: uid,
          files: admin.firestore.FieldValue.arrayUnion(...(fileUrls.length > 0 ? fileUrls : [])),
          note,
          submittedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      await db.collection(Collections.HOMEWORK).doc(homeworkId).update({
        submittedBy: admin.firestore.FieldValue.arrayUnion(uid),
      });

      cacheDeletePrefix("student_dash_");
      cacheDeletePrefix("teacher_dash_");
      res.json({ submitted: true, files: fileUrls });
    } catch (err: any) {
      if (handleMulterError(err, res)) return;
      console.error("homework submit error:", err);
      res.status(500).json({ error: err.message || "Internal server error" });
    }
  }
);

router.get(
  "/homework/:id/submissions",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const homeworkId = req.params.id as string;
    const snaps = await db.collection(Collections.HOMEWORK_SUBMISSIONS)
      .where("homeworkId", "==", homeworkId).get();

    const submissions = snaps.docs.map((d) => {
      const data = d.data();
      return { id: d.id, ...data, submittedAt: data.submittedAt?.toDate?.()?.toISOString?.() || null };
    });

    const studentUids = submissions.map((s: any) => s.studentUid).filter(Boolean);
    const userMap: Record<string, string> = {};
    if (studentUids.length > 0) {
      const chunks = [];
      for (let i = 0; i < studentUids.length; i += 10) {
        chunks.push(studentUids.slice(i, i + 10));
      }
      for (const chunk of chunks) {
        const snap = await db.collection(Collections.USERS)
          .where(admin.firestore.FieldPath.documentId(), "in", chunk).get();
        snap.docs.forEach((d) => { userMap[d.id] = d.data().name || d.id; });
      }
    }

    const enriched = submissions.map((s: any) => ({
      ...s,
      studentName: userMap[s.studentUid] || s.studentUid,
    }));

    res.json({ submissions: enriched });
  })
);

router.get(
  "/homework/:id/my-submission",
  requireRole("Student"),
  asyncHandler(async (req, res) => {
    const homeworkId = req.params.id as string;
    const uid = req.uid!;
    const docRef = db.collection(Collections.HOMEWORK_SUBMISSIONS).doc(`${homeworkId}_${uid}`);
    const snap = await docRef.get();
    if (!snap.exists) return res.json({ submission: null });

    const data = snap.data()!;
    res.json({
      submission: { id: snap.id, ...data, submittedAt: data.submittedAt?.toDate?.()?.toISOString?.() || null },
    });
  })
);

export default router;
