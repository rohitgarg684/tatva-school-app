import { Router } from "express";
import * as admin from "firebase-admin";
import multer from "multer";
import { requireAuth } from "../middleware/auth";

const ALLOWED_MIME_TYPES = ["image/jpeg", "image/png", "image/gif", "image/webp"];
const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5 MB

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_FILE_SIZE },
  fileFilter: (_req, file, cb) => {
    if (ALLOWED_MIME_TYPES.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error(`Invalid file type: ${file.mimetype}. Only JPEG, PNG, GIF, and WebP are allowed.`));
    }
  },
});

const router = Router();
router.use(requireAuth);

// POST /api/story/upload  (multipart: file + classId)
router.post("/story/upload", upload.single("file"), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: "No file uploaded" });
    }

    const classId = req.body.classId;
    if (!classId || typeof classId !== "string") {
      return res.status(400).json({ error: "classId required" });
    }

    const sanitizedClassId = classId.replace(/[^a-zA-Z0-9_-]/g, "_");
    const ext = req.file.mimetype.split("/")[1] || "jpg";
    const fileName = `${Date.now()}_${Math.random().toString(36).slice(2, 8)}.${ext}`;
    const storagePath = `stories/${sanitizedClassId}/${fileName}`;

    const bucket = admin.storage().bucket();
    const fileRef = bucket.file(storagePath);

    await fileRef.save(req.file.buffer, {
      metadata: { contentType: req.file.mimetype },
      public: true,
    });

    const downloadUrl = `https://storage.googleapis.com/${bucket.name}/${storagePath}`;

    res.json({ url: downloadUrl, path: storagePath });
  } catch (err: any) {
    if (err instanceof multer.MulterError) {
      if (err.code === "LIMIT_FILE_SIZE") {
        return res.status(413).json({ error: "File too large. Max 5 MB." });
      }
      return res.status(400).json({ error: err.message });
    }
    console.error("upload error:", err);
    res.status(500).json({ error: err.message || "Internal server error" });
  }
});

export default router;
