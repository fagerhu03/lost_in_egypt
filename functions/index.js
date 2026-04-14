const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const { GoogleGenerativeAI } = require("@google/generative-ai");

admin.initializeApp();

// Define secrets stored securely in Google Cloud Secret Manager
const geminiApiKey = defineSecret("GEMINI_API_KEY");
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

// ===== SECURE API PROXY FOR GEMINI =====
exports.analyzeImageOrStory = onCall({ secrets: [geminiApiKey] }, async (request) => {
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
    const apiKey = geminiApiKey.value();
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });

    const prompt = `
      You are a fascinating historical guide for Egypt.
      I have identified this landmark: ${landmarkName}.
      Tell me a short, captivating story or provide 3 amazing facts about it in 150 words or less.
      Make it sound like an adventure!
      Don't use any symbols since this will be read aloud. Just pure storytelling.
    `;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    return { story: text };
  } catch (error) {
    console.error("Gemini API Error:", error);
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
