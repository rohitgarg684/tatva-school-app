import * as admin from "firebase-admin";
admin.initializeApp();

import express, { Request, Response, NextFunction } from "express";
import cors from "cors";
import helmet from "helmet";
import { uploadLimiter, dashboardLimiter, actionLimiter } from "./middleware/rate-limit";
import { env } from "./env";

import adminRoutes from "./routes/admin";
import userRoutes from "./routes/users";
import classRoutes from "./routes/classes";
import studentRoutes from "./routes/students";
import homeworkRoutes from "./routes/homework";
import announcementRoutes from "./routes/announcements";
import voteRoutes from "./routes/votes";
import gradeRoutes from "./routes/grades";
import messagingRoutes from "./routes/messaging";
import scheduleRoutes from "./routes/schedules";
import attendanceRoutes from "./routes/attendance";
import behaviorRoutes from "./routes/behavior";
import contentRoutes from "./routes/content";
import dashboardRoutes from "./routes/dashboards";
import uploadRoutes from "./routes/upload";

const app = express();

app.use(helmet());

app.use(cors({
  origin: env.corsOrigins,
}));

app.use(express.json({ limit: "1mb" }));

app.get("/api/health", (_req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

app.use("/api", adminRoutes);
app.use("/api", actionLimiter, userRoutes);
app.use("/api", actionLimiter, classRoutes);
app.use("/api", actionLimiter, studentRoutes);
app.use("/api", actionLimiter, homeworkRoutes);
app.use("/api", actionLimiter, announcementRoutes);
app.use("/api", actionLimiter, voteRoutes);
app.use("/api", actionLimiter, gradeRoutes);
app.use("/api", actionLimiter, messagingRoutes);
app.use("/api", actionLimiter, scheduleRoutes);
app.use("/api", actionLimiter, attendanceRoutes);
app.use("/api", actionLimiter, behaviorRoutes);
app.use("/api", actionLimiter, contentRoutes);
app.use("/api/dashboard", dashboardLimiter, dashboardRoutes);
app.use("/api/document/upload", uploadLimiter);
app.use("/api", uploadRoutes);

// Global error handler
app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
  console.error("Unhandled error:", err);
  res.status(500).json({ error: err.message || "Internal server error" });
});

const port = env.port;
app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});
