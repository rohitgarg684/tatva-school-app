export interface AnnouncementDoc {
  id: string;
  title: string;
  body: string;
  audience: string;
  grades: string[];
  createdBy: string;
  createdByName: string;
  createdByRole: string;
  likedBy: string[];
  commentCount: number;
  attachments: unknown[];
  createdAt: unknown;
}

export interface BehaviorPointDoc {
  id: string;
  studentUid: string;
  studentName: string;
  classId: string;
  categoryId: string;
  points: number;
  awardedBy: string;
  awardedByName: string;
  note: string;
  createdAt: unknown;
}

export interface GradeDoc {
  id: string;
  studentUid: string;
  studentName: string;
  classId: string;
  subject: string;
  assessmentName: string;
  score: number;
  total: number;
  teacherUid: string;
  testDate?: string;
  createdAt: unknown;
}

export interface ClassDoc {
  id: string;
  name: string;
  subject: string;
  classCode: string;
  grade: string;
  section: string;
  teacherUid: string;
  teacherName: string;
  teacherEmail: string;
  studentUids: string[];
  parentUids: string[];
  createdAt: unknown;
}

export interface StudentDoc {
  id: string;
  name: string;
  rollNumber: string;
  grade: string;
  section: string;
  parentName: string;
  parentPhone: string;
  classIds: string[];
  enrolledBy: string;
  createdAt: unknown;
}

export interface AttendanceDoc {
  id: string;
  studentUid: string;
  studentName: string;
  date: string;
  status: string;
  markedBy: string;
  createdAt: unknown;
}

export interface ContentDoc {
  id: string;
  title: string;
  description: string;
  category: string;
  duration: string;
  grade: string;
  studentUids: string[];
  createdBy: string;
  completedBy: string[];
  createdAt: unknown;
}

export interface ActivityDoc {
  id: string;
  type: string;
  actorUid: string;
  actorName: string;
  actorRole: string;
  title: string;
  body: string;
  createdAt: unknown;
}

export function filterAnnouncementsByGrade(
  announcements: AnnouncementDoc[],
  userGrades: string[],
): AnnouncementDoc[] {
  return announcements.filter((a) => {
    if (a.audience.toLowerCase() === "everyone") return true;
    if (a.grades.length > 0) {
      return a.grades.some((g) => userGrades.includes(g));
    }
    return true;
  });
}

export function computeBehaviorScore(points: BehaviorPointDoc[]): number {
  let score = 0;
  for (const p of points) {
    score += p.points;
  }
  return score;
}

export function computeSubjectAverages(
  grades: GradeDoc[],
): Record<string, number> {
  const sums: Record<string, { total: number; count: number }> = {};
  for (const g of grades) {
    const subj = g.subject || "Unknown";
    const pct = g.total > 0 ? (g.score / g.total) * 100 : 0;
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
