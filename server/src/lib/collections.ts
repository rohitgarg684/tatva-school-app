export const Collections = {
  USERS: "users",
  CLASSES: "classes",
  STUDENTS: "students",
  HOMEWORK: "homework",
  HOMEWORK_SUBMISSIONS: "homework_submissions",
  ANNOUNCEMENTS: "announcements",
  VOTES: "votes",
  STORIES: "stories",
  GRADES: "grades",
  TEST_TITLES: "test_titles",
  BEHAVIOR_POINTS: "behavior_points",
  ATTENDANCE: "attendance",
  MESSAGES: "messages",
  GROUP_CONVERSATIONS: "group_conversations",
  ACTIVITIES: "activities",
  CONTENT: "content",
  SCHEDULES: "schedules",
  SCHEDULE_EVENTS: "schedule_events",
  PERIOD_CANCELLATIONS: "period_cancellations",
} as const;

export type CollectionName = (typeof Collections)[keyof typeof Collections];
