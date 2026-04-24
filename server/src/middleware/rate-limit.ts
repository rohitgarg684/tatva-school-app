import rateLimit from "express-rate-limit";

function keyGenerator(req: any): string {
  return req.uid || req.ip || "anonymous";
}

export const uploadLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  keyGenerator,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many uploads. Try again in a minute." },
});

export const dashboardLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  keyGenerator,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many requests. Try again in a minute." },
});

export const actionLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 60,
  keyGenerator,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many requests. Try again in a minute." },
});
