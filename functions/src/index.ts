import * as admin from "firebase-admin";

admin.initializeApp();

export {
  getStudentDashboard,
  getTeacherDashboard,
  getParentDashboard,
  getPrincipalDashboard,
} from "./dashboards";

export {
  toggleStoryLike,
  submitHomework,
  markContentCompleted,
  castVote,
  closeVote,
  markAttendance,
  awardBehaviorPoint,
} from "./actions";
