import * as admin from "firebase-admin";
import { db } from "../../firestore-helpers";
import { Collections } from "../../collections";
import { NotificationChannel, NotificationPayload, Recipient } from "../types";

const BATCH_SIZE = 500;

export class PushChannel implements NotificationChannel {
  name = "push";

  async send(recipients: Recipient[], payload: NotificationPayload): Promise<void> {
    if (recipients.length === 0) return;

    const tokens = recipients.map((r) => r.token);

    for (let i = 0; i < tokens.length; i += BATCH_SIZE) {
      const batch = tokens.slice(i, i + BATCH_SIZE);
      const message: admin.messaging.MulticastMessage = {
        tokens: batch,
        notification: { title: payload.title, body: payload.body },
        data: payload.data,
        apns: {
          payload: {
            aps: { sound: "default", badge: 1 },
          },
        },
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`[push] Batch ${i / BATCH_SIZE + 1}: ${response.successCount} ok, ${response.failureCount} failed`);
      if (response.failureCount > 0) {
        response.responses.forEach((r, idx) => {
          if (r.error) console.warn(`[push] token[${i + idx}] error: ${r.error.code} — ${r.error.message}`);
        });
        await this.cleanStaleTokens(recipients.slice(i, i + BATCH_SIZE), response.responses);
      }
    }
  }

  private async cleanStaleTokens(
    recipients: Recipient[],
    responses: admin.messaging.SendResponse[]
  ): Promise<void> {
    const staleUids: string[] = [];

    responses.forEach((resp, idx) => {
      if (
        resp.error &&
        (resp.error.code === "messaging/registration-token-not-registered" ||
          resp.error.code === "messaging/invalid-registration-token")
      ) {
        staleUids.push(recipients[idx].uid);
      }
    });

    if (staleUids.length === 0) return;

    const batch = db.batch();
    for (const uid of staleUids) {
      batch.update(db.collection(Collections.USERS).doc(uid), {
        fcmToken: admin.firestore.FieldValue.delete(),
      });
    }
    await batch.commit();
    console.log(`[push] Cleaned ${staleUids.length} stale FCM tokens`);
  }
}
