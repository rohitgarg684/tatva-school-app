import rateLimit from "express-rate-limit";

export const uploadLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  keyGenerator: (req: any) => req.uid || "anonymous",
  standardHeaders: true,
  legacyHeaders: false,
  validate: { xForwardedForHeader: false, ip: false },
  message: { error: "Too many uploads. Try again in a minute." },
});

const standardLimiterInstance = rateLimit({
  windowMs: 60 * 1000,
  max: 200,
  keyGenerator: (req: any) => req.uid || "anonymous",
  standardHeaders: true,
  legacyHeaders: false,
  validate: { xForwardedForHeader: false, ip: false },
  message: { error: "Too many requests. Try again in a minute." },
});

export const dashboardLimiter = standardLimiterInstance;
export const actionLimiter = standardLimiterInstance;
