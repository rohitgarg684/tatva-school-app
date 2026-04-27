export interface AnnouncementDoc {
  id: string;
  audience?: string;
  grades?: string[];
  [key: string]: unknown;
}

export interface BehaviorPointDoc {
  id: string;
  studentUid?: string;
  points?: number;
  [key: string]: unknown;
}

export interface GradeDoc {
  id: string;
  studentUid?: string;
  subject?: string;
  score?: number;
  total?: number;
  [key: string]: unknown;
}

export interface ClassDoc {
  id: string;
  grade?: string;
  studentUids?: string[];
  [key: string]: unknown;
}

export interface StudentDoc {
  id: string;
  name?: string;
  [key: string]: unknown;
}

export interface AttendanceDoc {
  id: string;
  studentUid?: string;
  [key: string]: unknown;
}

export interface ContentDoc {
  id: string;
  grade?: string;
  studentUids?: string[];
  [key: string]: unknown;
}

export interface ActivityDoc {
  id: string;
  [key: string]: unknown;
}

export function filterAnnouncementsByGrade(
  announcements: AnnouncementDoc[],
  userGrades: string[],
): AnnouncementDoc[] {
  return announcements.filter((a) => {
    if ((a.audience || "").toLowerCase() === "everyone") return true;
    if (Array.isArray(a.grades) && a.grades.length > 0) {
      return a.grades.some((g: string) => userGrades.includes(g));
    }
    return true;
  });
}

export function computeBehaviorScore(points: BehaviorPointDoc[]): number {
  let score = 0;
  for (const p of points) {
    score += (p.points as number) || 0;
  }
  return score;
}

export function computeSubjectAverages(
  grades: GradeDoc[],
): Record<string, number> {
  const sums: Record<string, { total: number; count: number }> = {};
  for (const g of grades) {
    const subj = g.subject || "Unknown";
    const pct =
      (g.total ?? 0) > 0 ? ((g.score || 0) / (g.total ?? 1)) * 100 : 0;
    if (!sums[subj]) sums[subj] = { total: 0, count: 0 };
    sums[subj].total += pct;
    sums[subj].count += 1;
  }
  const result: Record<string, number> = {};
  for (const [subj, { total, count }] of Object.entries(sums)) {
    result[subj] = count > 0 ? Math.round((total / count) * 10) / 10 : 0;
  }
  return result;
}
