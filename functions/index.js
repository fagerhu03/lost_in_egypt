const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.forceResetPassword = functions.https.onCall(async (data, context) => {
  // --- ROBUST EXTRACTION ---
  // We explicitly look for the fields we need
  const email = data.email || (data.data && data.data.email) || null;
  const newPassword = data.newPassword || (data.data && data.data.newPassword) || null;

  // --- VALIDATION ---
  if (!email || !newPassword) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Missing data. Email was: '${email}'`
    );
  }

  try {
    // 1. Find user
    const userRecord = await admin.auth().getUserByEmail(email);
    
    // 2. Force Update
    await admin.auth().updateUser(userRecord.uid, {
      password: newPassword,
    });

    return { success: true, message: "Password updated successfully" };
  } catch (error) {
    console.error("UPDATE ERROR:", error);
    // Return the actual error message to the client so you can see it in Flutter
    throw new functions.https.HttpsError("internal", error.message);
  }
});