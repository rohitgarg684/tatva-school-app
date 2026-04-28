export const env = {
  port: parseInt(process.env.PORT || "8080", 10),
  storageBucket: process.env.STORAGE_BUCKET || "tatva-school-app.firebasestorage.app",
  corsOrigins: (process.env.CORS_ORIGINS || "https://tatva-school-app.web.app,https://tatva-school-app.firebaseapp.com,http://localhost:5000")
    .split(",")
    .map((s) => s.trim()),
};
