import * as admin from "firebase-admin";
admin.initializeApp();

import express from "express";
import cors from "cors";
import helmet from "helmet";
import dashboardRoutes from "./routes/dashboards";
import actionRoutes from "./routes/actions";
import uploadRoutes from "./routes/upload";
import adminRoutes from "./routes/admin";
import { uploadLimiter, dashboardLimiter, actionLimiter } from "./middleware/rate-limit";

const app = express();

app.use(helmet());

app.use(cors({
  origin: [
    "https://tatva-school-app.web.app",
    "https://tatva-school-app.firebaseapp.com",
    "http://localhost:5000",
  ],
}));

app.use(express.json({ limit: "1mb" }));

app.get("/api/health", (_req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

app.use("/api", adminRoutes);
app.use("/api/dashboard", dashboardLimiter, dashboardRoutes);
app.use("/api/story/upload", uploadLimiter);
app.use("/api/document/upload", uploadLimiter);
app.use("/api", actionLimiter, actionRoutes);
app.use("/api", uploadRoutes);

const port = parseInt(process.env.PORT || "8080", 10);
app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});
