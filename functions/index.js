const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const textToSpeech = require("@google-cloud/text-to-speech");

admin.initializeApp();

// ── Recommendation Engine (see recommendation.js + design doc in memory) ─────
Object.assign(exports, require("./recommendation"));

// Define secrets stored securely in Google Cloud Secret Manager
const geminiApiKey = defineSecret("GEMINI_API_KEY");
const groqApiKey = defineSecret("GROQ_API_KEY");
const googleCloudVisionApiKey = defineSecret("GOOGLE_CLOUD_VISION_API_KEY");


// ── Rate limiting ────────────────────────────────────────────────────────────
// Limits per user per function per hour, tracked in Firestore.
// Keeps it simple: one counter doc per user per function that resets hourly.
const RATE_LIMITS = {
  analyzeImageOrStory: 20,  // max AI story calls per user per hour
  identifyLandmark: 30,     // max Vision API calls per user per hour
};

async function checkRateLimit(uid, functionName) {
  const db = admin.firestore();
  const hourSlot = Math.floor(Date.now() / (1000 * 60 * 60)); // changes every hour
  const ref = db
    .collection("_rate_limits")
    .doc(`${uid}_${functionName}_${hourSlot}`);

  const limit = RATE_LIMITS[functionName];

  const result = await db.runTransaction(async (tx) => {
    const doc = await tx.get(ref);
    const count = doc.exists ? doc.data().count : 0;
    if (count >= limit) return false;
    tx.set(ref, { count: count + 1, uid, updatedAt: Date.now() }, { merge: true });
    return true;
  });

  return result;
}

// ── Input sanitization ───────────────────────────────────────────────────────
function sanitizeLandmarkName(raw) {
  if (typeof raw !== "string") return null;
  // Strip non-printable / control characters, trim whitespace, cap at 200 chars
  return raw.replace(/[^\x20-\x7E\u00A0-\uFFFF]/g, "").trim().slice(0, 200);
}

function sanitizeBase64(raw) {
  if (typeof raw !== "string") return null;
  // Base64 is [A-Za-z0-9+/=]. Cap at ~10 MB of base64 (~7.5 MB image).
  if (raw.length > 10_000_000) return null;
  return raw;
}

// ===== SECURE API PROXY FOR GROQ =====
exports.analyzeImageOrStory = onCall({ secrets: [groqApiKey] }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in to use the AI Guide.");
  }

  const allowed = await checkRateLimit(request.auth.uid, "analyzeImageOrStory");
  if (!allowed) {
    throw new HttpsError(
      "resource-exhausted",
      "You've reached the story limit for this hour. Please try again later."
    );
  }

  const landmarkName = sanitizeLandmarkName(request.data?.landmarkName);
  if (!landmarkName) {
    throw new HttpsError("invalid-argument", "A valid landmark name is required.");
  }

  try {
    const apiKey = groqApiKey.value();

    const prompt = `
      You are a fascinating historical guide for Egypt.
      I have identified this landmark: ${landmarkName}.
      Tell me a short, captivating story or provide 3 amazing facts about it in 150 words or less.
      Make it sound like an adventure!
      Don't use any symbols since this will be read aloud. Just pure storytelling.
    `;

    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: "llama-3.3-70b-versatile",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7,
        max_tokens: 250
      })
    });

    if (!response.ok) {
      throw new Error(`Groq API returned ${response.status}`);
    }

    const data = await response.json();
    const text = data.choices?.[0]?.message?.content || "No story found.";

    return { story: text };
  } catch (error) {
    console.error("Groq API Error:", error);
    throw new HttpsError("internal", "Failed to generate story.");
  }
});

// ===== SECURE API PROXY FOR CLOUD VISION =====
exports.identifyLandmark = onCall({ secrets: [googleCloudVisionApiKey] }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in to identify landmarks.");
  }

  const allowed = await checkRateLimit(request.auth.uid, "identifyLandmark");
  if (!allowed) {
    throw new HttpsError(
      "resource-exhausted",
      "You've reached the scan limit for this hour. Please try again later."
    );
  }

  const base64Image = sanitizeBase64(request.data?.base64Image);
  if (!base64Image) {
    throw new HttpsError("invalid-argument", "Valid base64 image data is required.");
  }

  try {
    const apiKey = googleCloudVisionApiKey.value();

    const requestBody = {
      requests: [
        {
          image: { content: base64Image },
          features: [{ type: "LANDMARK_DETECTION", maxResults: 1 }],
        },
      ],
    };

    const response = await fetch(
      `https://vision.googleapis.com/v1/images:annotate?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(requestBody),
      }
    );

    if (!response.ok) {
      throw new Error(`Vision API failed with status ${response.status}`);
    }

    const data = await response.json();
    const responses = data.responses || [];

    if (
      responses.length > 0 &&
      responses[0].landmarkAnnotations &&
      responses[0].landmarkAnnotations.length > 0
    ) {
      return { landmarkName: responses[0].landmarkAnnotations[0].description };
    }

    return { landmarkName: null };
  } catch (error) {
    console.error("Vision API Error:", error);
    throw new HttpsError("internal", "Failed to analyze image.");
  }
});

// ===== GOOGLE CLOUD TTS (AI Narrator Voice — free tier, uses service account) =====
exports.generateStoryAudio = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in to use the AI narrator.");
  }

  const allowed = await checkRateLimit(request.auth.uid, "analyzeImageOrStory");
  if (!allowed) {
    throw new HttpsError(
      "resource-exhausted",
      "You've reached the narration limit for this hour. Please try again later."
    );
  }

  const text = request.data?.text;
  if (!text || typeof text !== "string" || text.trim().length === 0) {
    throw new HttpsError("invalid-argument", "Text content is required for narration.");
  }

  // Cap text at 4096 chars to stay within free tier
  const sanitizedText = text.trim().slice(0, 4096);

  try {
    const client = new textToSpeech.TextToSpeechClient();

    const [response] = await client.synthesizeSpeech({
      input: { text: sanitizedText },
      voice: {
        languageCode: "en-US",
        name: "en-US-Studio-Q",        // Premium Studio voice — deepest, most cinematic male
        ssmlGender: "MALE",
      },
      audioConfig: {
        audioEncoding: "MP3",
        speakingRate: 0.78,            // Slow, deliberate — like a history documentary
        pitch: -8.0,                   // Very deep, authoritative tone
        volumeGainDb: 2.0,
      },
    });

    // response.audioContent is a Buffer — convert to base64
    const base64Audio = response.audioContent.toString("base64");
    return { audio: base64Audio, format: "mp3" };
  } catch (error) {
    console.error("Google Cloud TTS Error:", error);
    throw new HttpsError("internal", "Failed to generate audio narration.");
  }
});

// ===== SCHEDULED: ADVANCE RECURRING TOURS NIGHTLY =====
exports.advanceRecurringTours = onSchedule('5 0 * * *', async (event) => {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();
  const nowDate = now.toDate();

  const snapshot = await db.collection('tours')
    .where('isArchived', '!=', true)
    .get();

  const batch = db.batch();

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const recurrenceType = data.recurrenceType || 'one_time';
    const nextOccurrence = data.nextOccurrence?.toDate();

    if (recurrenceType === 'one_time') {
      // Archive if past
      if (nextOccurrence && nextOccurrence < nowDate) {
        batch.update(doc.ref, { isArchived: true });
      }
    } else {
      // Compute next future occurrence
      const timeOfDay = data.meetingTimeOfDay || '09:00'; // "HH:mm"
      const [hours, minutes] = timeOfDay.split(':').map(Number);
      const recurrenceDays = data.recurrenceDays || [];

      let nextDate = new Date(nowDate);
      nextDate.setHours(hours, minutes, 0, 0);

      if (recurrenceType === 'daily') {
        if (nextDate <= nowDate) nextDate.setDate(nextDate.getDate() + 1);
      } else if (recurrenceType === 'weekly' && recurrenceDays.length > 0) {
        const targetDay = recurrenceDays[0]; // 0=Mon...6=Sun
        // Convert to JS day (0=Sun...6=Sat)
        const jsTargetDay = (targetDay + 1) % 7;
        const currentJsDay = nextDate.getDay();
        let daysUntil = (jsTargetDay - currentJsDay + 7) % 7;
        if (daysUntil === 0 && nextDate <= nowDate) daysUntil = 7;
        nextDate.setDate(nextDate.getDate() + daysUntil);
      } else if (recurrenceType === 'custom' && recurrenceDays.length > 0) {
        // Find the next day in the custom set
        // recurrenceDays: 0=Mon...6=Sun; JS: 0=Sun...6=Sat
        const jsDays = recurrenceDays.map(d => (d + 1) % 7).sort((a, b) => a - b);
        const currentJsDay = nextDate.getDay();
        let found = false;
        for (const jsDay of jsDays) {
          let daysUntil = (jsDay - currentJsDay + 7) % 7;
          if (daysUntil === 0 && nextDate <= nowDate) continue;
          if (daysUntil === 0) { found = true; break; }
          nextDate.setDate(nextDate.getDate() + daysUntil);
          found = true;
          break;
        }
        if (!found) {
          // Next occurrence is next week on the first day
          const firstDay = jsDays[0];
          let daysUntil = (firstDay - currentJsDay + 7) % 7 || 7;
          nextDate.setDate(nextDate.getDate() + daysUntil);
        }
      }

      batch.update(doc.ref, {
        nextOccurrence: admin.firestore.Timestamp.fromDate(nextDate),
        // Reset capacity for new cycle (only if current nextOccurrence has passed)
        ...(nextOccurrence && nextOccurrence < nowDate && data.totalCapacity
          ? { maxAttendees: data.totalCapacity }
          : {}),
      });
    }
  }

  await batch.commit();
  console.log('advanceRecurringTours: processed', snapshot.docs.length, 'tours');
});

// ── FCM Push Notification Helper ─────────────────────────────────────────────
/**
 * Sends an FCM push notification to a single user, respecting master switch
 * and granular notificationPreferences stored in their Firestore user doc.
 *
 * @param {string} recipientUid
 * @param {string} title
 * @param {string} body
 * @param {string} type   — matches notification `type` field in Firestore
 * @param {string} targetId — deep-link target (bookingId, postId, etc.)
 * @param {string|null} preferenceKey — key inside notificationPreferences map
 */
async function sendPushNotification({ recipientUid, title, body, type, targetId = '', preferenceKey = null }) {
  const db = admin.firestore();
  try {
    const userDoc = await db.collection('users').doc(recipientUid).get();
    if (!userDoc.exists) return;
    const userData = userDoc.data();

    const fcmToken = userData.fcmToken;
    if (!fcmToken) return;

    // Master notifications switch (preferences.notifications)
    if (userData.preferences?.notifications === false) return;

    // Granular preference check
    if (preferenceKey && userData.notificationPreferences?.[preferenceKey] === false) return;

    await admin.messaging().send({
      token: fcmToken,
      notification: { title, body },
      data: { type, targetId: String(targetId) },
      android: {
        notification: {
          channelId: 'high_importance_channel',
          priority: 'high',
          color: '#D6A00F',
        },
      },
      apns: {
        payload: { aps: { badge: 1, sound: 'default' } },
      },
    });
  } catch (e) {
    console.error(`FCM error for ${recipientUid}:`, e.message);
  }
}

/** Sends push to multiple tourists (tour_cancelled / tour_updated). */
async function sendPushToMany(uids, title, body, type, targetId) {
  await Promise.all(
    uids.map(uid => sendPushNotification({ recipientUid: uid, title, body, type, targetId, preferenceKey: 'bookings' }))
  );
}

// ── BOOKING CREATED → notify guide ───────────────────────────────────────────
exports.onBookingCreated = onDocumentCreated({ document: 'bookings/{bookingId}', region: 'europe-west1' }, async (event) => {
  const booking = event.data?.data();
  if (!booking) return;

  const { guideId, tourId, userId: touristId } = booking;
  if (!guideId || !tourId || !touristId) return;

  const [tourDoc, touristDoc] = await Promise.all([
    admin.firestore().collection('tours').doc(tourId).get(),
    admin.firestore().collection('users').doc(touristId).get(),
  ]);

  const tourTitle = tourDoc.data()?.title ?? 'your tour';
  const touristData = touristDoc.data();
  const touristName = touristData
    ? `${touristData.firstName ?? ''} ${touristData.lastName ?? ''}`.trim() || 'A tourist'
    : 'A tourist';

  await sendPushNotification({
    recipientUid: guideId,
    title: 'New Booking! 🎉',
    body: `${touristName} booked "${tourTitle}"`,
    type: 'booking',
    targetId: event.params.bookingId,
    preferenceKey: 'bookings',
  });
});

// ── BOOKING UPDATED → notify tourist on status change ────────────────────────
exports.onBookingUpdated = onDocumentUpdated({ document: 'bookings/{bookingId}', region: 'europe-west1' }, async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!before || !after) return;

  const { status: statusBefore } = before;
  const { status: statusAfter, userId: touristId, tourId } = after;

  if (!touristId || statusBefore === statusAfter) return;

  const tourDoc = await admin.firestore().collection('tours').doc(tourId).get();
  const tourTitle = tourDoc.data()?.title ?? 'your tour';

  if (statusAfter === 'confirmed') {
    await sendPushNotification({
      recipientUid: touristId,
      title: 'Booking Confirmed ✅',
      body: `Your booking for "${tourTitle}" has been confirmed!`,
      type: 'booking_confirmed',
      targetId: event.params.bookingId,
      preferenceKey: 'bookings',
    });
  } else if (statusAfter === 'cancelled') {
    await sendPushNotification({
      recipientUid: touristId,
      title: 'Booking Cancelled',
      body: `Your booking for "${tourTitle}" was cancelled.`,
      type: 'booking_cancelled',
      targetId: event.params.bookingId,
      preferenceKey: 'bookings',
    });
  }
});

// ── REVIEW CREATED → notify guide ────────────────────────────────────────────
exports.onReviewCreated = onDocumentCreated({ document: 'reviews/{reviewId}', region: 'europe-west1' }, async (event) => {
  const review = event.data?.data();
  if (!review) return;

  const { guideId, tourId, userName: reviewerName = 'A tourist', rating = 5 } = review;
  if (!guideId) return;

  const tourDoc = await admin.firestore().collection('tours').doc(tourId).get();
  const tourTitle = tourDoc.data()?.title ?? 'your tour';
  const stars = '⭐'.repeat(Math.min(Math.round(rating), 5));

  await sendPushNotification({
    recipientUid: guideId,
    title: `New Review ${stars}`,
    body: `${reviewerName} reviewed "${tourTitle}"`,
    type: 'review',
    targetId: tourId ?? '',
    preferenceKey: 'reviews',
  });
});

// ── COMMENT CREATED → notify post author + reply author ──────────────────────
exports.onCommentCreated = onDocumentCreated(
  { document: 'community_posts/{postId}/comments/{commentId}', region: 'europe-west1' },
  async (event) => {
    const comment = event.data?.data();
    if (!comment) return;

    const db = admin.firestore();
    const { postId } = event.params;
    const { userId: commenterUid, userUsername, userName } = comment;
    const commenterName = userUsername ? `@${userUsername}` : (userName || 'Someone');

    // Notify post author
    const postDoc = await db.collection('community_posts').doc(postId).get();
    if (postDoc.exists) {
      const postAuthorUid = postDoc.data().userId;
      if (postAuthorUid && postAuthorUid !== commenterUid) {
        await sendPushNotification({
          recipientUid: postAuthorUid,
          title: 'New Comment 💬',
          body: `${commenterName} commented on your post`,
          type: 'comment',
          targetId: postId,
          preferenceKey: 'community',
        });
      }
    }

    // If this is a reply, notify the parent comment's author
    if (comment.replyToId) {
      const parentDoc = await db
        .collection('community_posts').doc(postId)
        .collection('comments').doc(comment.replyToId)
        .get();
      if (parentDoc.exists) {
        const parentAuthorUid = parentDoc.data().userId;
        if (parentAuthorUid && parentAuthorUid !== commenterUid) {
          await sendPushNotification({
            recipientUid: parentAuthorUid,
            title: 'New Reply 💬',
            body: `${commenterName} replied to your comment`,
            type: 'reply',
            targetId: `${postId}_${comment.replyToId}`,
            preferenceKey: 'community',
          });
        }
      }
    }
  }
);

// ── POST UPDATED → notify post author when someone likes it ──────────────────
exports.onPostLiked = onDocumentUpdated({ document: 'community_posts/{postId}', region: 'europe-west1' }, async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!before || !after) return;

  const beforeLikes = before.likes || [];
  const afterLikes = after.likes || [];
  if (afterLikes.length <= beforeLikes.length) return;

  const newLikerUid = afterLikes.find(uid => !beforeLikes.includes(uid));
  if (!newLikerUid) return;

  const postAuthorUid = after.userId;
  if (!postAuthorUid || postAuthorUid === newLikerUid) return;

  const likerDoc = await admin.firestore().collection('users').doc(newLikerUid).get();
  const likerData = likerDoc.data();
  const likerName = likerData?.username ? `@${likerData.username}` : (likerData?.firstName || 'Someone');

  await sendPushNotification({
    recipientUid: postAuthorUid,
    title: 'New Like ❤️',
    body: `${likerName} liked your post`,
    type: 'like_post',
    targetId: event.params.postId,
    preferenceKey: 'community',
  });
});

// ── COMMENT UPDATED → notify comment author when someone likes it ─────────────
exports.onCommentLiked = onDocumentUpdated(
  { document: 'community_posts/{postId}/comments/{commentId}', region: 'europe-west1' },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!before || !after) return;

    const beforeLikes = before.likes || [];
    const afterLikes = after.likes || [];
    if (afterLikes.length <= beforeLikes.length) return;

    const newLikerUid = afterLikes.find(uid => !beforeLikes.includes(uid));
    if (!newLikerUid) return;

    const commentAuthorUid = after.userId;
    if (!commentAuthorUid || commentAuthorUid === newLikerUid) return;

    const likerDoc = await admin.firestore().collection('users').doc(newLikerUid).get();
    const likerData = likerDoc.data();
    const likerName = likerData?.username ? `@${likerData.username}` : (likerData?.firstName || 'Someone');

    await sendPushNotification({
      recipientUid: commentAuthorUid,
      title: 'New Like ❤️',
      body: `${likerName} liked your comment`,
      type: 'like_comment',
      targetId: `${event.params.postId}_${event.params.commentId}`,
      preferenceKey: 'community',
    });
  }
);

// ── TOUR UPDATED → notify confirmed tourists (cancelled or details changed) ───
exports.onTourUpdated = onDocumentUpdated({ document: 'tours/{tourId}', region: 'europe-west1' }, async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!before || !after) return;

  const tourId = event.params.tourId;
  const tourTitle = after.title ?? 'a tour';

  const wasJustArchived = !before.isArchived && after.isArchived === true;
  const keyFieldsChanged =
    before.title !== after.title ||
    before.description !== after.description ||
    before.price !== after.price ||
    JSON.stringify(before.destinations) !== JSON.stringify(after.destinations) ||
    before.meetingLocationName !== after.meetingLocationName ||
    JSON.stringify(before.nextOccurrence) !== JSON.stringify(after.nextOccurrence);

  if (!wasJustArchived && !keyFieldsChanged) return;

  // Fetch all active bookings for this tour
  const bookingsSnap = await admin.firestore()
    .collection('bookings')
    .where('tourId', '==', tourId)
    .where('status', 'in', ['pending', 'confirmed', 'partially_checked_in'])
    .get();

  if (bookingsSnap.empty) return;

  const touristUids = [...new Set(
    bookingsSnap.docs.map(d => d.data().userId).filter(Boolean)
  )];

  if (wasJustArchived) {
    await sendPushToMany(touristUids, 'Tour Cancelled', `"${tourTitle}" has been cancelled by the guide.`, 'tour_cancelled', tourId);
  } else {
    await sendPushToMany(touristUids, 'Tour Updated 📢', `"${tourTitle}" details have changed. Check the new info.`, 'tour_updated', tourId);
  }
});

// ── USER UPDATED → guide application approved / rejected ─────────────────────
exports.onGuideApplicationUpdated = onDocumentUpdated({ document: 'users/{userId}', region: 'europe-west1' }, async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!before || !after) return;

  const { applicationStatus: statusBefore } = before;
  const { applicationStatus: statusAfter } = after;

  if (!statusBefore || statusBefore === statusAfter || statusBefore !== 'pending') return;

  const userId = event.params.userId;

  if (statusAfter === 'approved') {
    await sendPushNotification({
      recipientUid: userId,
      title: 'Application Approved! 🎉',
      body: "Congratulations! You're now a verified guide on Lost in Egypt.",
      type: 'guide_application_approved',
      targetId: userId,
      preferenceKey: 'guideUpdates',
    });
  } else if (statusAfter === 'rejected') {
    await sendPushNotification({
      recipientUid: userId,
      title: 'Application Update',
      body: 'Your guide application was not approved. Tap to view details.',
      type: 'guide_application_rejected',
      targetId: userId,
      preferenceKey: 'guideUpdates',
    });
  }
});

// ── ADMIN REQUEST UPDATED → language certification approved / rejected ─────────
exports.onLanguageRequestUpdated = onDocumentUpdated({ document: 'admin_requests/{requestId}', region: 'europe-west1' }, async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!before || !after) return;

  const { status: statusBefore } = before;
  const { status: statusAfter, userId, requestedLanguage: language = 'a language' } = after;

  if (!userId || statusBefore === statusAfter || statusBefore !== 'pending') return;

  if (statusAfter === 'approved') {
    await sendPushNotification({
      recipientUid: userId,
      title: 'Language Certified! 🌟',
      body: `Your ${language} certification has been approved.`,
      type: 'language_request_approved',
      targetId: event.params.requestId,
      preferenceKey: 'guideUpdates',
    });
  } else if (statusAfter === 'rejected') {
    await sendPushNotification({
      recipientUid: userId,
      title: 'Language Request Update',
      body: `Your ${language} certification request was not approved.`,
      type: 'language_request_rejected',
      targetId: event.params.requestId,
      preferenceKey: 'guideUpdates',
    });
  }
});
