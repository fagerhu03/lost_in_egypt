const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// This function can be called directly from your Flutter App
exports.forceResetPassword = functions.https.onCall(async (data, context) => {
  const email = data.email;
  const newPassword = data.newPassword;

  // Basic Validation
  if (!email || !newPassword) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with email and newPassword."
    );
  }

  try {
    // 1. Find the user by Email
    const userRecord = await admin.auth().getUserByEmail(email);

    // 2. FORCE Update the password (Admin SDK capability)
    await admin.auth().updateUser(userRecord.uid, {
      password: newPassword,
    });

    return { success: true, message: "Password updated successfully" };
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});