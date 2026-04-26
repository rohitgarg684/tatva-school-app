import { Router } from "express";
import * as admin from "firebase-admin";
import { requireAuth } from "../middleware/auth";
import { db, queryDocs, serializeDocs } from "../lib/firestore-helpers";
import { asyncHandler } from "../lib/async-handler";
import { Collections } from "../lib/collections";
import { Config } from "../lib/config";

const router = Router();
router.use(requireAuth);

const FieldValue = admin.firestore.FieldValue;

router.get(
  "/messages/:conversationId",
  asyncHandler(async (req, res) => {
    const convId = req.params.conversationId as string;
    const uid = req.uid!;

    const msgs = await queryDocs(
      Collections.MESSAGES,
      [{ field: "conversationId", op: "==", value: convId }],
      { field: "createdAt", direction: "asc" },
      Config.MESSAGE_QUERY_LIMIT
    );

    const participates = msgs.some(
      (m: any) => m.senderUid === uid || m.receiverUid === uid
    );
    if (!participates && msgs.length > 0)
      return res.status(403).json({ error: "Forbidden" });

    res.json({ messages: serializeDocs(msgs) });
  })
);

router.post(
  "/messages",
  asyncHandler(async (req, res) => {
    const uid = req.uid!;
    const { conversationId, receiverUid, text } = req.body;
    if (!conversationId || !receiverUid || !text)
      return res.status(400).json({ error: "conversationId, receiverUid, text required" });

    const ref = await db.collection(Collections.MESSAGES).add({
      conversationId,
      senderUid: uid,
      receiverUid,
      text,
      participantUids: [uid, receiverUid],
      createdAt: FieldValue.serverTimestamp(),
    });

    res.json({ id: ref.id, sent: true });
  })
);

router.get(
  "/groups",
  asyncHandler(async (req, res) => {
    const uid = req.uid!;
    const groups = await queryDocs(
      Collections.GROUP_CONVERSATIONS,
      [{ field: "participantUids", op: "array-contains", value: uid }]
    );
    res.json({ groups: serializeDocs(groups) });
  })
);

router.get(
  "/group-messages/:groupId",
  asyncHandler(async (req, res) => {
    const groupId = req.params.groupId as string;
    const snap = await db.collection(Collections.GROUP_CONVERSATIONS).doc(groupId)
      .collection("messages")
      .orderBy("createdAt", "asc")
      .limit(Config.MESSAGE_QUERY_LIMIT)
      .get();

    const msgs = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    res.json({ messages: serializeDocs(msgs) });
  })
);

router.post(
  "/group-messages/:groupId",
  asyncHandler(async (req, res) => {
    const groupId = req.params.groupId as string;
    const uid = req.uid!;
    const { text, senderName } = req.body;
    if (!text)
      return res.status(400).json({ error: "text required" });

    const ref = await db.collection(Collections.GROUP_CONVERSATIONS).doc(groupId)
      .collection("messages").add({
        text,
        senderUid: uid,
        senderName: senderName || "",
        createdAt: FieldValue.serverTimestamp(),
      });

    res.json({ id: ref.id, sent: true });
  })
);

export default router;
