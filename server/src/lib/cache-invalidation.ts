import { cacheDeletePrefix } from "./cache";

const DASHBOARD_PREFIXES = [
  "teacher_dash_",
  "student_dash_",
  "parent_dash_",
  "principal_dash_",
];

export function invalidateDashboards(...extraPrefixes: string[]): void {
  for (const p of [...DASHBOARD_PREFIXES, ...extraPrefixes]) {
    cacheDeletePrefix(p);
  }
}

export function invalidateAll(): void {
  invalidateDashboards(
    "announcements_",
    "homework_",
    "grades_",
    "attendance_",
    "behavior_",
    "content_",
    "votes_",
    "classes_",
    "schedules_",
  );
}
