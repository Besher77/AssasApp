const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

const ESCROW_WALLET_ID = "escrow";
const COMMISSION_RATE = 0.1;

// Moyasar secret key for verifying card payments. Set via: firebase functions:config:set moyasar.secret_key="sk_test_xxx"
function getMoyasarSecretKey() {
  return functions.config().moyasar?.secret_key || process.env.MOYASAR_SECRET_KEY || "";
}

// Callback URL required by Moyasar for token/creditcard payments (3DS redirect)
function getMoyasarCallbackUrl() {
  return functions.config().moyasar?.callback_url || process.env.MOYASAR_CALLBACK_URL || "https://moyasar.com/thankyou";
}

/**
 * Process payment request: transfer from client to ESCROW (not engineer)
 * Engineer receives 90% when user confirms receipt
 */
exports.processPaymentRequest = functions.firestore
  .document("payment_requests/{requestId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const {
      fromUserId,
      toUserId,
      amount,
      projectId,
      offerId,
      status,
      deliveryDurationDays,
    } = data;

    if (status !== "pending") return null;

    if (!fromUserId || !toUserId || !amount || amount <= 0) {
      await snap.ref.update({ status: "failed", error: "invalid_data" });
      return null;
    }

    try {
      await db.runTransaction(async (tx) => {
        const clientWalletRef = db.doc(`wallets/${fromUserId}`);
        const escrowRef = db.doc(`wallets/${ESCROW_WALLET_ID}`);
        const projectRef = projectId ? db.doc(`projects/${projectId}`) : null;

        // All reads must be done before any writes
        const readPromises = [
          tx.get(clientWalletRef),
          tx.get(escrowRef),
        ];
        if (projectRef) readPromises.push(tx.get(projectRef));

        const results = await Promise.all(readPromises);
        const clientSnap = results[0];
        const escrowSnap = results[1];
        const projectSnap = projectRef ? results[2] : null;

        const clientBalance = clientSnap.exists
          ? (clientSnap.data().balance || 0)
          : 0;
        const escrowBalance = escrowSnap.exists
          ? (escrowSnap.data().balance || 0)
          : 0;

        if (clientBalance < amount) {
          throw new Error("insufficient_balance");
        }

        const projectData = projectSnap?.exists ? projectSnap.data() : {};
        const createdAt = projectData.createdAt?.toDate?.() || new Date();
        const days = deliveryDurationDays || 30;
        const expectedAt = new Date(createdAt);
        expectedAt.setDate(expectedAt.getDate() + days);

        const now = admin.firestore.FieldValue.serverTimestamp();

        if (!clientSnap.exists) {
          tx.set(clientWalletRef, {
            userId: fromUserId,
            balance: -amount,
            currency: "SAR",
            createdAt: now,
            updatedAt: now,
          });
        } else {
          tx.update(clientWalletRef, {
            balance: clientBalance - amount,
            updatedAt: now,
          });
        }

        if (!escrowSnap.exists) {
          tx.set(escrowRef, {
            userId: ESCROW_WALLET_ID,
            balance: amount,
            currency: "SAR",
            createdAt: now,
            updatedAt: now,
          });
        } else {
          tx.update(escrowRef, {
            balance: escrowBalance + amount,
            updatedAt: now,
          });
        }

        tx.set(db.collection("transactions").doc(), {
          userId: fromUserId,
          type: "payment_out",
          amount,
          status: "completed",
          currency: "SAR",
          description: "Project payment (escrow)",
          referenceId: projectId,
          referenceType: "project",
          relatedUserId: toUserId,
          metadata: { offerId },
          createdAt: now,
          completedAt: now,
        });

        if (offerId) {
          tx.update(db.doc(`offers/${offerId}`), {
            status: "accepted",
            updatedAt: now,
          });
        }
        if (projectId) {
          tx.update(db.doc(`projects/${projectId}`), {
            status: "in_progress",
            paidAmount: amount,
            acceptedEngineerId: toUserId,
            acceptedOfferId: offerId,
            paymentMethod: "wallet",
            expectedCompletionAt: admin.firestore.Timestamp.fromDate(expectedAt),
            updatedAt: now,
          });
        }

        tx.update(snap.ref, { status: "completed", completedAt: now });
      });
    } catch (err) {
      console.error("Payment failed:", err);
      await snap.ref.update({
        status: "failed",
        error: err.message || "unknown",
      });
    }
    return null;
  });

/**
 * Verify card payment with Moyasar and update project (card payments go to Moyasar, not escrow)
 */
exports.processCardPaymentConfirmation = functions.firestore
  .document("card_payment_confirmations/{confId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const {
      moyasarPaymentId,
      fromUserId,
      toUserId,
      amount,
      projectId,
      offerId,
      status,
      deliveryDurationDays,
    } = data;

    if (status !== "pending") return null;
    if (!moyasarPaymentId || !amount || amount <= 0) {
      await snap.ref.update({ status: "failed", error: "invalid_data" });
      return null;
    }

    const isAddCardOnly = projectId === "add_card" && offerId === "add_card";
    const isWalletTopup = projectId === "wallet_topup" && offerId === "wallet_topup";

    const secretKey = getMoyasarSecretKey();
    if (!secretKey) {
      console.error("Moyasar secret key not configured");
      await snap.ref.update({ status: "failed", error: "moyasar_not_configured" });
      return null;
    }

    try {
      const auth = Buffer.from(secretKey + ":").toString("base64");
      const res = await fetch(`https://api.moyasar.com/v1/payments/${moyasarPaymentId}`, {
        headers: { Authorization: `Basic ${auth}` },
      });

      if (!res.ok) {
        const errText = await res.text();
        console.error("Moyasar API error:", res.status, errText);
        await snap.ref.update({ status: "failed", error: "moyasar_verify_failed" });
        return null;
      }

      const payment = await res.json();
      const paidStatuses = ["paid", "captured", "authorized"];
      if (!paidStatuses.includes(payment.status)) {
        await snap.ref.update({ status: "failed", error: `payment_status_${payment.status}` });
        return null;
      }

      const amountHalalas = Math.round(amount * 100);
      if (payment.amount !== amountHalalas) {
        await snap.ref.update({ status: "failed", error: "amount_mismatch" });
        return null;
      }

      const now = admin.firestore.FieldValue.serverTimestamp();

      if (isAddCardOnly) {
        // Add-card-only: deposit 1 SAR to user's wallet (verification charge refund)
        const userWalletRef = db.doc(`wallets/${fromUserId}`);
        await db.runTransaction(async (tx) => {
          const walletSnap = await tx.get(userWalletRef);
          const currentBalance = walletSnap.exists ? (walletSnap.data().balance || 0) : 0;
          const newBalance = currentBalance + amount;
          if (!walletSnap.exists) {
            tx.set(userWalletRef, {
              userId: fromUserId,
              balance: newBalance,
              currency: "SAR",
              createdAt: now,
              updatedAt: now,
            });
          } else {
            tx.update(userWalletRef, { balance: newBalance, updatedAt: now });
          }
          tx.set(db.collection("transactions").doc(), {
            userId: fromUserId,
            type: "deposit",
            amount,
            status: "completed",
            currency: "SAR",
            description: "Add card verification refund",
            referenceType: "add_card",
            metadata: { moyasarPaymentId },
            createdAt: now,
            completedAt: now,
          });
          tx.update(snap.ref, { status: "completed", completedAt: now });
        });
      } else if (isWalletTopup) {
        const userWalletRef = db.doc(`wallets/${fromUserId}`);
        await db.runTransaction(async (tx) => {
          const walletSnap = await tx.get(userWalletRef);
          const currentBalance = walletSnap.exists ? (walletSnap.data().balance || 0) : 0;
          const newBalance = currentBalance + amount;
          if (!walletSnap.exists) {
            tx.set(userWalletRef, {
              userId: fromUserId,
              balance: newBalance,
              currency: "SAR",
              createdAt: now,
              updatedAt: now,
            });
          } else {
            tx.update(userWalletRef, { balance: newBalance, updatedAt: now });
          }
          tx.set(db.collection("transactions").doc(), {
            userId: fromUserId,
            type: "deposit",
            amount,
            status: "completed",
            currency: "SAR",
            description: "Wallet top-up (card)",
            referenceType: "wallet_topup",
            metadata: { moyasarPaymentId },
            createdAt: now,
            completedAt: now,
          });
          tx.update(snap.ref, { status: "completed", completedAt: now });
        });
      } else {
        const projectSnap = await db.doc(`projects/${projectId}`).get();
        const projectData = projectSnap.exists ? projectSnap.data() : {};
        const createdAt = projectData.createdAt?.toDate?.() || new Date();
        const days = deliveryDurationDays || 30;
        const expectedAt = new Date(createdAt);
        expectedAt.setDate(expectedAt.getDate() + days);

        await db.runTransaction(async (tx) => {
          tx.update(db.doc(`offers/${offerId}`), { status: "accepted", updatedAt: now });
          tx.update(db.doc(`projects/${projectId}`), {
            status: "in_progress",
            paidAmount: amount,
            acceptedEngineerId: toUserId,
            acceptedOfferId: offerId,
            paymentMethod: "card",
            expectedCompletionAt: admin.firestore.Timestamp.fromDate(expectedAt),
            updatedAt: now,
          });
          tx.set(db.collection("transactions").doc(), {
            userId: fromUserId,
            type: "payment_out",
            amount,
            status: "completed",
            currency: "SAR",
            description: "Project payment (card)",
            referenceId: projectId,
            referenceType: "project",
            relatedUserId: toUserId,
            metadata: { offerId, moyasarPaymentId },
            createdAt: now,
            completedAt: now,
          });
          tx.update(snap.ref, { status: "completed", completedAt: now });
        });
      }
    } catch (err) {
      console.error("Card payment verification failed:", err);
      await snap.ref.update({ status: "failed", error: err.message || "unknown" });
    }
    return null;
  });

/**
 * Release escrow when user confirms receipt
 * 90% to engineer, 10% platform commission
 */
exports.releaseEscrowOnConfirm = functions.firestore
  .document("project_confirmations/{confId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const { projectId, userId, status } = data;

    if (status !== "pending") return null;
    if (!projectId || !userId) return null;

    try {
      const projectSnap = await db.doc(`projects/${projectId}`).get();
      if (!projectSnap.exists) return null;

      const project = projectSnap.data();
      if (project.userId !== userId) return null;
      if (project.status !== "delivered") return null;

      const paidAmount = project.paidAmount || 0;
      const engineerId = project.acceptedEngineerId;
      const offerId = project.acceptedOfferId;
      const paymentMethod = project.paymentMethod || "wallet";

      if (paidAmount <= 0 || !engineerId) return null;

      const engineerAmount = Math.round(paidAmount * (1 - COMMISSION_RATE) * 100) / 100;
      const commission = Math.round(paidAmount * COMMISSION_RATE * 100) / 100;

      await db.runTransaction(async (tx) => {
        const projectRef = db.doc(`projects/${projectId}`);
        const projectSnap = await tx.get(projectRef);
        if (!projectSnap.exists) throw new Error("project_missing");
        const pr = projectSnap.data();
        if (pr.userId !== userId) throw new Error("not_owner");
        if (pr.status !== "delivered") throw new Error("not_delivered");

        const engineerWalletRef = db.doc(`wallets/${engineerId}`);
        const platformRef = db.doc(`wallets/platform`);
        const now = admin.firestore.FieldValue.serverTimestamp();

        if (paymentMethod === "card") {
          const [engineerSnap, platformSnap] = await Promise.all([
            tx.get(engineerWalletRef),
            tx.get(platformRef),
          ]);
          const engineerBalance = engineerSnap.exists ? (engineerSnap.data().balance || 0) : 0;

          if (!engineerSnap.exists) {
            tx.set(engineerWalletRef, {
              userId: engineerId,
              balance: engineerAmount,
              currency: "SAR",
              createdAt: now,
              updatedAt: now,
            });
          } else {
            tx.update(engineerWalletRef, {
              balance: engineerBalance + engineerAmount,
              updatedAt: now,
            });
          }

          if (!platformSnap.exists) {
            tx.set(platformRef, {
              userId: "platform",
              balance: commission,
              currency: "SAR",
              createdAt: now,
              updatedAt: now,
            });
          } else {
            const platformBalance = platformSnap.data().balance || 0;
            tx.update(platformRef, {
              balance: platformBalance + commission,
              updatedAt: now,
            });
          }

          tx.set(db.collection("transactions").doc(), {
            userId: engineerId,
            type: "payment_in",
            amount: engineerAmount,
            status: "completed",
            currency: "SAR",
            description: "Payment received for project (card — settled to wallet on confirm)",
            referenceId: projectId,
            referenceType: "project",
            relatedUserId: userId,
            metadata: { offerId, commission, paymentMethod: "card" },
            createdAt: now,
            completedAt: now,
          });
        } else {
          const escrowRef = db.doc(`wallets/${ESCROW_WALLET_ID}`);
          const [escrowSnap, engineerSnap, platformSnap] = await Promise.all([
            tx.get(escrowRef),
            tx.get(engineerWalletRef),
            tx.get(platformRef),
          ]);

          const escrowBalance = escrowSnap.exists ? (escrowSnap.data().balance || 0) : 0;
          if (escrowBalance < paidAmount) {
            throw new Error("insufficient_escrow");
          }

          const engineerBalance = engineerSnap.exists ? (engineerSnap.data().balance || 0) : 0;

          tx.update(escrowRef, {
            balance: escrowBalance - paidAmount,
            updatedAt: now,
          });

          if (!engineerSnap.exists) {
            tx.set(engineerWalletRef, {
              userId: engineerId,
              balance: engineerAmount,
              currency: "SAR",
              createdAt: now,
              updatedAt: now,
            });
          } else {
            tx.update(engineerWalletRef, {
              balance: engineerBalance + engineerAmount,
              updatedAt: now,
            });
          }

          if (!platformSnap.exists) {
            tx.set(platformRef, {
              userId: "platform",
              balance: commission,
              currency: "SAR",
              createdAt: now,
              updatedAt: now,
            });
          } else {
            const platformBalance = platformSnap.data().balance || 0;
            tx.update(platformRef, {
              balance: platformBalance + commission,
              updatedAt: now,
            });
          }

          tx.set(db.collection("transactions").doc(), {
            userId: engineerId,
            type: "payment_in",
            amount: engineerAmount,
            status: "completed",
            currency: "SAR",
            description: "Payment received for project",
            referenceId: projectId,
            referenceType: "project",
            relatedUserId: userId,
            metadata: { offerId, commission },
            createdAt: now,
            completedAt: now,
          });
        }

        tx.update(projectRef, {
          status: "completed",
          updatedAt: now,
        });

        tx.update(snap.ref, { status: "completed", completedAt: now });
      });

      await db.collection("notifications").add({
        userId: engineerId,
        title: "إضافة رصيد",
        body: `تم إضافة ${engineerAmount} ريال إلى محفظتك بعد تأكيد العميل لاستلام المشروع.`,
        type: "wallet_balance_added",
        data: {
          projectId: projectId,
          amount: String(engineerAmount),
        },
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (err) {
      console.error("Release escrow failed:", err);
      await snap.ref.update({
        status: "failed",
        error: err.message || "unknown",
      });
    }
    return null;
  });

/**
 * Process project cancellation when both parties agree - refund escrow to client
 */
exports.processProjectCancellation = functions.firestore
  .document("project_cancel_requests/{reqId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (after.status !== "both_agreed" || before.status === "both_agreed") return null;

    const { projectId } = after;
    if (!projectId) return null;

    try {
      const projectSnap = await db.doc(`projects/${projectId}`).get();
      if (!projectSnap.exists) return null;

      const project = projectSnap.data();
      const clientId = project.userId;
      const paidAmount = project.paidAmount || 0;
      const paymentMethod = project.paymentMethod || "wallet";

      if (paidAmount <= 0) return null;

      const now = admin.firestore.FieldValue.serverTimestamp();

      if (paymentMethod === "wallet") {
        const escrowRef = db.doc(`wallets/${ESCROW_WALLET_ID}`);
        const clientWalletRef = db.doc(`wallets/${clientId}`);

        await db.runTransaction(async (tx) => {
          const [escrowSnap, clientSnap] = await Promise.all([
            tx.get(escrowRef),
            tx.get(clientWalletRef),
          ]);

          const escrowBalance = escrowSnap.exists ? (escrowSnap.data().balance || 0) : 0;
          const clientBalance = clientSnap.exists ? (clientSnap.data().balance || 0) : 0;

          if (escrowBalance < paidAmount) throw new Error("insufficient_escrow");

          tx.update(escrowRef, {
            balance: escrowBalance - paidAmount,
            updatedAt: now,
          });

          if (!clientSnap.exists) {
            tx.set(clientWalletRef, {
              userId: clientId,
              balance: paidAmount,
              currency: "SAR",
              createdAt: now,
              updatedAt: now,
            });
          } else {
            tx.update(clientWalletRef, {
              balance: clientBalance + paidAmount,
              updatedAt: now,
            });
          }

          tx.set(db.collection("transactions").doc(), {
            userId: clientId,
            type: "deposit",
            amount: paidAmount,
            status: "completed",
            currency: "SAR",
            description: "Project cancellation refund",
            referenceId: projectId,
            referenceType: "project_cancel",
            metadata: { cancelRequestId: change.after.id },
            createdAt: now,
            completedAt: now,
          });

          tx.update(db.doc(`projects/${projectId}`), {
            status: "cancelled",
            updatedAt: now,
          });

          tx.update(change.after.ref, { status: "processed", processedAt: now });
        });
      } else {
        // Card payment: money with Moyasar - mark project cancelled (refund via Moyasar/business)
        await db.doc(`projects/${projectId}`).update({
          status: "cancelled",
          updatedAt: now,
        });
        await change.after.ref.update({ status: "processed", processedAt: now });
      }
    } catch (err) {
      console.error("Project cancellation failed:", err);
      await change.after.ref.update({
        status: "failed",
        error: err.message || "unknown",
      });
    }
    return null;
  });

/**
 * Pay with saved card token (callable) - creates payment via Moyasar API
 */
exports.payWithSavedCard = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  const { token, amount, projectId, offerId, toUserId, deliveryDurationDays } = data;
  if (!token || typeof token !== "string" || token.trim() === "") {
    throw new functions.https.HttpsError("invalid-argument", "Invalid or missing token");
  }
  if (!projectId || typeof projectId !== "string" || projectId.trim() === "") {
    throw new functions.https.HttpsError("invalid-argument", "Invalid or missing projectId");
  }
  if (!offerId || typeof offerId !== "string" || offerId.trim() === "") {
    throw new functions.https.HttpsError("invalid-argument", "Invalid or missing offerId");
  }
  const isWalletTopup = projectId === "wallet_topup" && offerId === "wallet_topup";
  if (!isWalletTopup) {
    if (!toUserId || typeof toUserId !== "string" || toUserId.trim() === "") {
      throw new functions.https.HttpsError("invalid-argument", "Invalid or missing toUserId");
    }
  }
  const numAmount = Number(amount);
  if (isNaN(numAmount) || numAmount <= 0) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid amount");
  }
  const fromUserId = context.auth.uid;
  const secretKey = getMoyasarSecretKey();
  if (!secretKey) throw new functions.https.HttpsError("failed-precondition", "Moyasar not configured");

  const callbackUrl = getMoyasarCallbackUrl();
  const days = typeof deliveryDurationDays === "number" && deliveryDurationDays > 0 ? deliveryDurationDays : 30;
  const effectiveToUserId = isWalletTopup ? fromUserId : String(toUserId).trim();

  try {
    const amountHalalas = Math.round(numAmount * 100);
    const params = {
      amount: amountHalalas,
      currency: "SAR",
      description: isWalletTopup ? "Wallet top-up" : "Project payment",
      callback_url: callbackUrl,
      "source[type]": "token",
      "source[token]": token.trim(),
      "source[3ds]": "true",
      "metadata[projectId]": String(projectId).trim(),
      "metadata[offerId]": String(offerId).trim(),
      "metadata[fromUserId]": fromUserId,
      "metadata[toUserId]": effectiveToUserId,
    };
    const res = await fetch("https://api.moyasar.com/v1/payments", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        Authorization: "Basic " + Buffer.from(secretKey + ":").toString("base64"),
      },
      body: new URLSearchParams(params),
    });

    const payment = await res.json();
    if (!res.ok) throw new Error(payment.message || "Payment failed");

    const transactionUrl = payment.source?.transaction_url || null;
    const paymentId = payment.id;
    const status = payment.status;

    if (status === "paid" || status === "captured" || status === "authorized") {
      const now = admin.firestore.FieldValue.serverTimestamp();
      if (isWalletTopup) {
        const userWalletRef = db.doc(`wallets/${fromUserId}`);
        await db.runTransaction(async (tx) => {
          const walletSnap = await tx.get(userWalletRef);
          const currentBalance = walletSnap.exists ? (walletSnap.data().balance || 0) : 0;
          const newBalance = currentBalance + numAmount;
          if (!walletSnap.exists) {
            tx.set(userWalletRef, {
              userId: fromUserId,
              balance: newBalance,
              currency: "SAR",
              createdAt: now,
              updatedAt: now,
            });
          } else {
            tx.update(userWalletRef, { balance: newBalance, updatedAt: now });
          }
          tx.set(db.collection("transactions").doc(), {
            userId: fromUserId,
            type: "deposit",
            amount: numAmount,
            status: "completed",
            currency: "SAR",
            description: "Wallet top-up (saved card)",
            referenceType: "wallet_topup",
            metadata: { moyasarPaymentId: paymentId },
            createdAt: now,
            completedAt: now,
          });
        });
      } else {
        const projectSnap = await db.doc(`projects/${projectId}`).get();
        const projectData = projectSnap.exists ? projectSnap.data() : {};
        const createdAt = projectData.createdAt?.toDate?.() || new Date();
        const expectedAt = new Date(createdAt);
        expectedAt.setDate(expectedAt.getDate() + days);

        await db.runTransaction(async (tx) => {
          tx.update(db.doc(`offers/${offerId}`), { status: "accepted", updatedAt: now });
          tx.update(db.doc(`projects/${projectId}`), {
            status: "in_progress",
            paidAmount: numAmount,
            acceptedEngineerId: toUserId,
            acceptedOfferId: offerId,
            paymentMethod: "card",
            expectedCompletionAt: admin.firestore.Timestamp.fromDate(expectedAt),
            updatedAt: now,
          });
          tx.set(db.collection("transactions").doc(), {
            userId: fromUserId,
            type: "payment_out",
            amount: numAmount,
            status: "completed",
            currency: "SAR",
            description: "Project payment (saved card)",
            referenceId: projectId,
            referenceType: "project",
            relatedUserId: toUserId,
            metadata: { offerId, moyasarPaymentId: paymentId },
            createdAt: now,
            completedAt: now,
          });
        });
      }
    }
    // If 3DS required (status=initiated), client opens transactionUrl and creates card_payment_confirmation when done
    return { paymentId, transactionUrl, status };
  } catch (err) {
    console.error("payWithSavedCard error:", err);
    throw new functions.https.HttpsError("internal", err.message || "Payment failed");
  }
});

/**
 * Send FCM when new chat message is created
 */
exports.onChatMessageCreated = functions.firestore
  .document("messages/{msgId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const { senderId, receiverId, projectId, text, type } = data;

    if (!receiverId || !senderId) return null;

    try {
      const [receiverDoc, senderDoc] = await Promise.all([
        db.doc(`users/${receiverId}`).get(),
        db.doc(`users/${senderId}`).get(),
      ]);

      const fcmToken = receiverDoc.exists ? receiverDoc.data()?.fcmToken : null;
      if (!fcmToken) return null;

      const senderName = senderDoc.exists ? (senderDoc.data()?.name || "Someone") : "Someone";
      let body = "";
      if (type === "image") {
        body = "📷 Sent an image";
      } else if (type === "file") {
        body = "📎 Sent a file";
      } else if (type === "audio") {
        body = "🎤 Sent a voice message";
      } else {
        body = (text || "").trim();
        if (body.length > 80) body = body.substring(0, 77) + "...";
        if (!body) body = "New message";
      }

      const message = {
        token: fcmToken,
        notification: {
          title: senderName,
          body: body,
        },
        data: {
          type: "chat",
          projectId: projectId || "",
          route: "/chat",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "high_importance_channel",
            priority: "high",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      await admin.messaging().send(message);
    } catch (err) {
      console.error("Chat FCM error:", err);
    }
    return null;
  });

/**
 * When admin rejects a pending withdrawal: refund wallet + cancel linked transaction + notify user (FCM).
 * Only runs for pending → rejected (not after transferred).
 */
exports.refundWithdrawalOnReject = functions.firestore
  .document("withdrawal_requests/{reqId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!after || after.status !== "rejected") return null;
    if (!before || before.status === "rejected") return null;
    if (before.status !== "pending") return null;
    if (after.refundApplied === true) return null;

    const userId = after.userId;
    const amount = Number(after.amount);
    const linkedTransactionId = after.linkedTransactionId;
    if (!userId || !Number.isFinite(amount) || amount <= 0) return null;

    const wrRef = change.after.ref;
    const reqId = context.params.reqId;

    try {
      await db.runTransaction(async (tx) => {
        const wrSnap = await tx.get(wrRef);
        const wr = wrSnap.data();
        if (!wr || wr.refundApplied === true) return;
        if (wr.status !== "rejected") return;

        const now = admin.firestore.FieldValue.serverTimestamp();
        const walletRef = db.doc(`wallets/${userId}`);
        const walletSnap = await tx.get(walletRef);
        const balance = walletSnap.exists ? walletSnap.data().balance || 0 : 0;

        if (walletSnap.exists) {
          tx.update(walletRef, {
            balance: balance + amount,
            updatedAt: now,
          });
        } else {
          tx.set(walletRef, {
            userId,
            balance: amount,
            currency: "SAR",
            createdAt: now,
            updatedAt: now,
          });
        }

        if (linkedTransactionId) {
          const tRef = db.doc(`transactions/${linkedTransactionId}`);
          const tSnap = await tx.get(tRef);
          if (tSnap.exists) {
            const tData = tSnap.data();
            if (tData.status === "pending" && tData.type === "withdraw") {
              const meta = Object.assign({}, tData.metadata || {}, {
                refundReason: "withdrawal_rejected",
              });
              tx.update(tRef, {
                status: "cancelled",
                cancelledAt: now,
                metadata: meta,
              });
            }
          }
        }

        tx.update(wrRef, {
          refundApplied: true,
          refundedAt: now,
        });
      });

      await db.collection("notifications").add({
        userId,
        title: "إرجاع رصيد",
        body: `تم إرجاع ${amount} ريال إلى محفظتك بعد رفض طلب السحب.`,
        type: "withdrawal_rejected_refund",
        data: {
          amount: String(amount),
          withdrawalRequestId: reqId,
        },
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (err) {
      console.error("refundWithdrawalOnReject:", err);
    }
    return null;
  });

/**
 * Send FCM push when notification is created
 */
exports.sendNotificationFcm = functions.firestore
  .document("notifications/{notifId}")
  .onCreate(async (snap, context) => {
    const notif = snap.data();
    const { userId, title, body, type } = notif;
    const notifData = notif.data || {};

    if (!userId || !title || !body) return null;

    try {
      const userDoc = await db.doc(`users/${userId}`).get();
      const fcmToken = userDoc.exists ? userDoc.data()?.fcmToken : null;

      if (!fcmToken) return null;

      const projectId = notifData.projectId != null ? String(notifData.projectId) : "";
      const offerId = notifData.offerId != null ? String(notifData.offerId) : "";
      const reviewId = notifData.reviewId != null ? String(notifData.reviewId) : "";
      const engineerId = notifData.engineerId != null ? String(notifData.engineerId) : "";
      const amount = notifData.amount != null ? String(notifData.amount) : "";

      let route = "/notifications";
      if (type === "admin_project_deleted" || type === "admin_user_removed") {
        route = "/notifications";
      } else if (
        type === "wallet_deposit" ||
        type === "admin_wallet_credit" ||
        type === "admin_wallet_debit" ||
        type === "wallet_balance_added" ||
        type === "withdrawal_submitted" ||
        type === "withdrawal_rejected_refund" ||
        type === "withdrawal_transferred"
      ) {
        route = "/wallet";
      } else if (projectId) {
        route = "/project-detail";
      } else if (type === "review_received" || type === "review_answered") {
        route = engineerId ? "/engineer-profile" : "/notifications";
      }

      const message = {
        token: fcmToken,
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: type || "",
          projectId: projectId,
          offerId: offerId,
          reviewId: reviewId,
          engineerId: engineerId,
          amount: amount,
          route: route,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "high_importance_channel",
            priority: "high",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
          fcmOptions: {
            imageUrl: undefined,
          },
        },
      };

      await admin.messaging().send(message);
    } catch (err) {
      console.error("FCM send error:", err);
    }
    return null;
  });
