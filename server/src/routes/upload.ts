import { Router, Request, Response } from "express";
import * as admin from "firebase-admin";
import multer from "multer";
import { requireAuth } from "../middleware/auth";
import { isValidImage, isValidDocument } from "../lib/file-validation";

// ─── Image upload config ────────────────────────────────────────────────────

const IMAGE_MIME_TYPES = [
  "image/jpeg",
  "image/png",
  "image/gif",
  "image/webp",
];
const MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5 MB

const imageUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_IMAGE_SIZE },
  fileFilter: (_req, file, cb) => {
    if (IMAGE_MIME_TYPES.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(
        new Error(
          `Invalid image type: ${file.mimetype}. Allowed: JPEG, PNG, GIF, WebP.`
        )
      );
    }
  },
});

// ─── Document upload config ─────────────────────────────────────────────────

const DOC_MIME_TYPES = [
  ...IMAGE_MIME_TYPES,
  "application/pdf",
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  "application/vnd.openxmlformats-officedocument.presentationml.presentation",
];
const MAX_DOC_SIZE = 10 * 1024 * 1024; // 10 MB

const docUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_DOC_SIZE },
  fileFilter: (_req, file, cb) => {
    if (DOC_MIME_TYPES.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(
        new Error(
          `Invalid file type: ${file.mimetype}. Allowed: images, PDF, DOCX, XLSX, PPTX.`
        )
      );
    }
  },
});

// ─── Helpers ────────────────────────────────────────────────────────────────

const SIGNED_URL_EXPIRY_MS = 7 * 24 * 60 * 60 * 1000; // 7 days

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
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document":
      "docx",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet":
      "xlsx",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation":
      "pptx",
  };
  const ext = extMap[mimetype] || "bin";
  return `${Date.now()}_${Math.random().toString(36).slice(2, 8)}.${ext}`;
}

async function uploadToStorage(
  buffer: Buffer,
  storagePath: string,
  contentType: string
): Promise<string> {
  const bucket = admin.storage().bucket();
  const fileRef = bucket.file(storagePath);

  await fileRef.save(buffer, {
    metadata: { contentType },
  });

  const [signedUrl] = await fileRef.getSignedUrl({
    action: "read",
    expires: Date.now() + SIGNED_URL_EXPIRY_MS,
  });

  return signedUrl;
}

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

// ─── Router ─────────────────────────────────────────────────────────────────

const router = Router();
router.use(requireAuth);

// POST /api/story/upload  (multipart: file + classId)
router.post(
  "/story/upload",
  imageUpload.single("file"),
  async (req: Request, res: Response) => {
    try {
      if (!req.file) {
        return res.status(400).json({ error: "No file uploaded" });
      }

      if (!isValidImage(req.file.buffer)) {
        return res
          .status(400)
          .json({ error: "File content does not match a valid image format" });
      }

      const classId = req.body.classId;
      if (!classId || typeof classId !== "string") {
        return res.status(400).json({ error: "classId required" });
      }

      const storagePath = `stories/${sanitizeId(classId)}/${generateFileName(req.file.mimetype)}`;
      const url = await uploadToStorage(
        req.file.buffer,
        storagePath,
        req.file.mimetype
      );

      res.json({ url, path: storagePath });
    } catch (err: any) {
      if (handleMulterError(err, res)) return;
      console.error("story upload error:", err);
      res.status(500).json({ error: err.message || "Internal server error" });
    }
  }
);

// POST /api/document/upload  (multipart: file + classId)
router.post(
  "/document/upload",
  docUpload.single("file"),
  async (req: Request, res: Response) => {
    try {
      if (!req.file) {
        return res.status(400).json({ error: "No file uploaded" });
      }

      if (!isValidDocument(req.file.buffer)) {
        return res
          .status(400)
          .json({ error: "File content does not match a valid document format" });
      }

      const classId = req.body.classId;
      if (!classId || typeof classId !== "string") {
        return res.status(400).json({ error: "classId required" });
      }

      const storagePath = `documents/${sanitizeId(classId)}/${generateFileName(req.file.mimetype)}`;
      const url = await uploadToStorage(
        req.file.buffer,
        storagePath,
        req.file.mimetype
      );

      res.json({ url, path: storagePath });
    } catch (err: any) {
      if (handleMulterError(err, res)) return;
      console.error("document upload error:", err);
      res.status(500).json({ error: err.message || "Internal server error" });
    }
  }
);

export default router;
