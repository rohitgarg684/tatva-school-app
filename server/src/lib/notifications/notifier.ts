import { NotificationChannel, NotificationPayload, EventContext } from "./types";
import { PushChannel } from "./channels/push";
import {
  resolveAnnouncementRecipients,
  resolveClassRecipients,
  resolveStudentAndParents,
  resolveCommentRecipient,
} from "./recipient-resolver";

const channels: NotificationChannel[] = [new PushChannel()];

function buildPayload(ec: EventContext): NotificationPayload {
  switch (ec.event) {
    case "announcement": {
      const { ctx } = ec;
      const isGlobal = ctx.audience === "Everyone";
      return {
        title: isGlobal ? "New Announcement" : `Announcement for Grade ${ctx.grades.join(", ")}`,
        body: `${ctx.authorName}: ${ctx.title}`,
        data: { type: "announcement", id: ctx.announcementId },
      };
    }
    case "homeworkAssigned": {
      const { ctx } = ec;
      return {
        title: "New Homework",
        body: `${ctx.teacherName}: ${ctx.title}`,
        data: { type: "homework", id: ctx.homeworkId },
      };
    }
    case "homeworkStatusChanged": {
      const { ctx } = ec;
      const verb = ctx.status === "accepted" ? "accepted" : "returned for revision";
      return {
        title: ctx.status === "accepted" ? "Homework Accepted" : "Homework Returned",
        body: `Your "${ctx.title}" was ${verb}`,
        data: { type: "homework", id: ctx.homeworkId },
      };
    }
    case "homeworkComment": {
      const { ctx } = ec;
      return {
        title: "New Comment",
        body: `${ctx.authorName} commented on ${ctx.homeworkTitle}`,
        data: { type: "homework_comment", id: ctx.homeworkId, studentUid: ctx.studentUid },
      };
    }
  }
}

async function resolveAndSend(ec: EventContext): Promise<void> {
  const payload = buildPayload(ec);

  let recipients;
  switch (ec.event) {
    case "announcement":
      recipients = await resolveAnnouncementRecipients(
        ec.ctx.audience,
        ec.ctx.grades,
        ec.ctx.senderUid
      );
      break;
    case "homeworkAssigned":
      recipients = await resolveClassRecipients(ec.ctx.classId, ec.ctx.teacherUid);
      break;
    case "homeworkStatusChanged":
      recipients = await resolveStudentAndParents(ec.ctx.studentUid, ec.ctx.classId);
      break;
    case "homeworkComment":
      recipients = await resolveCommentRecipient(
        ec.ctx.authorUid,
        ec.ctx.studentUid,
        ec.ctx.teacherUid
      );
      break;
  }

  if (recipients.length === 0) return;

  await Promise.all(channels.map((ch) => ch.send(recipients, payload)));
}

export function notify(ec: EventContext): void {
  resolveAndSend(ec).catch((err) => {
    console.error(`[notifier] Failed to send ${ec.event} notification:`, err);
  });
}
