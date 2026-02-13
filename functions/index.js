const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

const NotificationType = Object.freeze({
  NEW_MESSAGE: "new_message",
  NEW_RIDE: "new_ride",
  NEW_REVIEW: "new_review",
  RIDE_ACCEPTED: "ride_accepted",
  RIDE_STARTED: "ride_started",
  RIDE_COMPLETED: "ride_completed",
  RIDE_CANCELLED: "ride_cancelled",
  RIDE_EXPIRED: "ride_expired",
});

// ── Helper: send push notification to a user by UID ──
async function sendPushToUser(uid, title, body, data = {}) {
  try {
    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) return;

    const fcmToken = userDoc.data().fcm_token;
    if (!fcmToken) return;

    await getMessaging().send({
      token: fcmToken,
      notification: { title, body },
      data: { ...data, click_action: "FLUTTER_NOTIFICATION_CLICK" },
      android: {
        priority: "high",
        notification: {
          channelId: "campus_ride_notifications",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: { sound: "default", badge: 1 },
        },
      },
    });
  } catch (err) {
    console.error(`Failed to send push to ${uid}:`, err.message);
  }
}

// ── 1. Notify rider when their ride is ACCEPTED ──
exports.onRideAccepted = onDocumentUpdated("rides/{rideId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  if (before.status === "OPEN" && after.status === "ACCEPTED") {
    const rideId = event.params.rideId;

    // Notify the rider
    await sendPushToUser(
      after.rider_uid,
      "Ride Accepted! 🚗",
      `${after.driver_name} accepted your ride to ${after.destination}.`,
      { type: NotificationType.RIDE_ACCEPTED, ride_id: rideId }
    );

    // Create in-app notification
    await db.collection("notifications").add({
      recipient_uid: after.rider_uid,
      type: NotificationType.RIDE_ACCEPTED,
      title: "Ride Accepted",
      body: `${after.driver_name} accepted your ride to ${after.destination}.`,
      ride_id: rideId,
      sender_uid: after.driver_uid,
      is_read: false,
      created_at: new Date(),
    });
  }
});

// ── 2. Notify rider when ride is STARTED ──
exports.onRideStarted = onDocumentUpdated("rides/{rideId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  if (before.status === "ACCEPTED" && after.status === "IN_PROGRESS") {
    const rideId = event.params.rideId;

    await sendPushToUser(
      after.rider_uid,
      "Ride Started! 🚙",
      `${after.driver_name} is on the way. Your ride to ${after.destination} has started.`,
      { type: NotificationType.RIDE_STARTED, ride_id: rideId }
    );

    await db.collection("notifications").add({
      recipient_uid: after.rider_uid,
      type: NotificationType.RIDE_STARTED,
      title: "Ride Started",
      body: `${after.driver_name} is on the way to ${after.destination}.`,
      ride_id: rideId,
      sender_uid: after.driver_uid,
      is_read: false,
      created_at: new Date(),
    });
  }
});

// ── 3. Notify both parties when ride is COMPLETED ──
exports.onRideCompleted = onDocumentUpdated("rides/{rideId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  if (before.status === "IN_PROGRESS" && after.status === "COMPLETED") {
    const rideId = event.params.rideId;

    // Notify rider
    await sendPushToUser(
      after.rider_uid,
      "Ride Complete! ✅",
      `Your ride to ${after.destination} is complete. Don't forget to rate your driver!`,
      { type: NotificationType.RIDE_COMPLETED, ride_id: rideId }
    );

    // Notify driver
    await sendPushToUser(
      after.driver_uid,
      "Ride Complete! ✅",
      `Your ride to ${after.destination} with ${after.rider_name} is complete.`,
      { type: NotificationType.RIDE_COMPLETED, ride_id: rideId }
    );

    // In-app notification for rider
    await db.collection("notifications").add({
      recipient_uid: after.rider_uid,
      type: NotificationType.RIDE_COMPLETED,
      title: "Ride Complete",
      body: `Your ride to ${after.destination} is complete. Rate your driver!`,
      ride_id: rideId,
      sender_uid: after.driver_uid,
      is_read: false,
      created_at: new Date(),
    });

    // In-app notification for driver
    await db.collection("notifications").add({
      recipient_uid: after.driver_uid,
      type: NotificationType.RIDE_COMPLETED,
      title: "Ride Complete",
      body: `Your ride to ${after.destination} with ${after.rider_name} is complete.`,
      ride_id: rideId,
      sender_uid: after.rider_uid,
      is_read: false,
      created_at: new Date(),
    });
  }
});

// ── 4. Notify other party when ride is CANCELLED ──
exports.onRideCancelled = onDocumentUpdated("rides/{rideId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  if (before.status !== "CANCELLED" && after.status === "CANCELLED") {
    const rideId = event.params.rideId;
    const cancelledBy = after.cancelled_by;

    // Don't notify for system-cancelled (expired) rides
    if (cancelledBy === "system") return;

    // Notify the OTHER party
    const notifyUid = cancelledBy === after.rider_uid
      ? after.driver_uid
      : after.rider_uid;

    if (!notifyUid) return;

    const cancellerName = cancelledBy === after.rider_uid
      ? after.rider_name
      : after.driver_name;

    await sendPushToUser(
      notifyUid,
      "Ride Cancelled ❌",
      `${cancellerName} cancelled the ride to ${after.destination}.`,
      { type: NotificationType.RIDE_CANCELLED, ride_id: rideId }
    );

    await db.collection("notifications").add({
      recipient_uid: notifyUid,
      type: NotificationType.RIDE_CANCELLED,
      title: "Ride Cancelled",
      body: `${cancellerName} cancelled the ride to ${after.destination}.`,
      ride_id: rideId,
      sender_uid: cancelledBy,
      is_read: false,
      created_at: new Date(),
    });
  }
});

// ── 5. Notify when a new chat message is sent ──
exports.onNewMessage = onDocumentCreated(
  "rides/{rideId}/messages/{messageId}",
  async (event) => {
    const message = event.data.data();
    const rideId = event.params.rideId;

    // Don't send push for system messages
    if (message.type === "system") return;

    // Get the ride to find the other participant
    const rideDoc = await db.collection("rides").doc(rideId).get();
    if (!rideDoc.exists) return;

    const ride = rideDoc.data();
    const senderUid = message.sender_uid;

    // Notify the other participant
    const recipientUid = senderUid === ride.rider_uid
      ? ride.driver_uid
      : ride.rider_uid;

    if (!recipientUid) return;

    await sendPushToUser(
      recipientUid,
      `${message.sender_name}`,
      message.text.length > 100
        ? message.text.substring(0, 100) + "..."
        : message.text,
      { type: NotificationType.NEW_MESSAGE, ride_id: rideId }
    );
  }
);

// ── 6. Notify when a new review is posted ──
exports.onNewReview = onDocumentCreated(
  "users/{userId}/reviews/{reviewId}",
  async (event) => {
    const review = event.data.data();
    const reviewedUserId = event.params.userId;

    await sendPushToUser(
      reviewedUserId,
      "New Review ⭐",
      `${review.reviewer_name} left you a ${review.stars}-star review.`,
      { type: NotificationType.NEW_REVIEW }
    );

    await db.collection("notifications").add({
      recipient_uid: reviewedUserId,
      type: NotificationType.NEW_REVIEW,
      title: "New Review",
      body: `${review.reviewer_name} left you a ${review.stars}-star review.`,
      ride_id: review.ride_id,
      sender_uid: review.reviewer_uid,
      is_read: false,
      created_at: new Date(),
    });
  }
);

// ── 7. Notify drivers when a new ride request is posted ──
exports.onNewRideRequest = onDocumentCreated("rides/{rideId}", async (event) => {
  const ride = event.data.data();
  const rideId = event.params.rideId;

  // Only notify for new OPEN rides
  if (ride.status !== "OPEN") return;

  // Get all drivers
  const driversSnap = await db
    .collection("users")
    .where("is_driver", "==", true)
    .get();

  // Send push to each driver (except the rider themselves)
  const promises = driversSnap.docs
    .filter((doc) => doc.id !== ride.rider_uid)
    .map((doc) =>
      sendPushToUser(
        doc.id,
        "New Ride Request 📍",
        `${ride.rider_name} needs a ride to ${ride.destination} at ${ride.pickup_time}.`,
        { type: NotificationType.NEW_RIDE, ride_id: rideId }
      )
    );

  await Promise.all(promises);
});

// ── 8. Expire OPEN rides whose pickup time has passed (server-side) ──
exports.expireOpenRides = onSchedule("every 5 minutes", async () => {
  const now = new Date();

  const snap = await db
    .collection("rides")
    .where("status", "==", "OPEN")
    .where("pickup_datetime", "<=", now)
    .get();

  if (snap.empty) return;

  for (const rideDoc of snap.docs) {
    const ride = rideDoc.data();
    const rideId = rideDoc.id;

    await rideDoc.ref.update({
      status: "CANCELLED",
      cancelled_by: "system",
      cancel_reason: "Ride expired - pickup time has passed.",
      updated_at: now,
    });

    // Decline active offers for this ride.
    const offersSnap = await rideDoc.ref
      .collection("offers")
      .where("status", "in", ["pending", "rider_confirmed"])
      .get();
    if (!offersSnap.empty) {
      const batch = db.batch();
      for (const offerDoc of offersSnap.docs) {
        batch.update(offerDoc.ref, {
          status: "declined",
          updated_at: now,
        });
      }
      await batch.commit();
    }

    // Add system chat message.
    await rideDoc.ref.collection("messages").add({
      sender_uid: "system",
      sender_name: "System",
      sender_avatar: "",
      text: "This ride has expired because the pickup time has passed.",
      type: "system",
      thread_driver_uid: ride.driver_uid || null,
      timestamp: now,
    });

    // Notify rider.
    await sendPushToUser(
      ride.rider_uid,
      "Ride Expired",
      `Your ride to ${ride.destination} has expired. Please create a new request.`,
      { type: NotificationType.RIDE_EXPIRED, ride_id: rideId }
    );

    await db.collection("notifications").add({
      recipient_uid: ride.rider_uid,
      type: NotificationType.RIDE_EXPIRED,
      title: "Ride Expired",
      body: `Your ride to ${ride.destination} has expired. Please create a new request.`,
      ride_id: rideId,
      sender_uid: "system",
      is_read: false,
      created_at: now,
    });
  }
});
