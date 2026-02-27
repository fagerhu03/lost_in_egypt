const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const { GoogleGenerativeAI } = require("@google/generative-ai");

admin.initializeApp();

// Define secrets that are stored securely in Google Cloud Secret Manager
const geminiApiKey = defineSecret("GEMINI_API_KEY");
const googleCloudVisionApiKey = defineSecret("GOOGLE_CLOUD_VISION_API_KEY");

// ===== SECURE API PROXY FOR GEMINI =====
exports.analyzeImageOrStory = onCall({ secrets: [geminiApiKey] }, async (request) => {
  // 1. Verify Authentication
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "You must be logged in to use the AI Guide."
    );
  }

  const { landmarkName } = request.data;
  if (!landmarkName) {
    throw new HttpsError("invalid-argument", "Landmark name is required.");
  }

  try {
    // 2. Access the Secret API Key
    const apiKey = geminiApiKey.value();
    const genAI = new GoogleGenerativeAI(apiKey);
    
    // 3. Make Request to Gemini Model
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

    // 4. Return securely to client
    return { story: text };
  } catch (error) {
    console.error("Gemini API Error:", error);
    throw new HttpsError("internal", "Failed to generate story.");
  }
});

// ===== SECURE API PROXY FOR CLOUD VISION =====
exports.identifyLandmark = onCall({ secrets: [googleCloudVisionApiKey] }, async (request) => {
  // 1. Verify Authentication
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "You must be logged in to identify landmarks."
    );
  }

  const { base64Image } = request.data;
  if (!base64Image) {
    throw new HttpsError("invalid-argument", "Base64 image data is required.");
  }

  try {
    const apiKey = googleCloudVisionApiKey.value();
    
    const requestBody = {
      requests: [
        {
          image: { content: base64Image },
          features: [{ type: "LANDMARK_DETECTION", maxResults: 1 }]
        }
      ]
    };

    // Make native fetch request (Cloud Functions Node 18+ has native fetch)
    const response = await fetch(
      `https://vision.googleapis.com/v1/images:annotate?key=${apiKey}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestBody)
      }
    );

    if (!response.ok) {
      throw new Error(`Vision API failed with status ${response.status}`);
    }

    const data = await response.json();
    const responses = data.responses || [];
    
    if (responses.length > 0 && responses[0].landmarkAnnotations && responses[0].landmarkAnnotations.length > 0) {
      return { landmarkName: responses[0].landmarkAnnotations[0].description };
    }
    
    return { landmarkName: null };
  } catch (error) {
    console.error("Vision API Error:", error);
    throw new HttpsError("internal", "Failed to analyze image.");
  }
});