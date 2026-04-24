import * as admin from "firebase-admin";
admin.initializeApp();

import express from "express";
import cors from "cors";
import dashboardRoutes from "./routes/dashboards";
import actionRoutes from "./routes/actions";
import uploadRoutes from "./routes/upload";

const app = express();

app.use(cors({ origin: true }));
app.use(express.json());

app.get("/api/health", (_req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

app.use("/api/dashboard", dashboardRoutes);
app.use("/api", actionRoutes);
app.use("/api", uploadRoutes);

const port = parseInt(process.env.PORT || "8080", 10);
app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});
