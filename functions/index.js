const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// ===== PASSWORD RESET FUNCTION =====
exports.forceResetPassword = functions.https.onCall(async (data, context) => {
  const email = data.email || (data.data && data.data.email) || null;
  const newPassword = data.newPassword || (data.data && data.data.newPassword) || null;

  if (!email || !newPassword) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Missing data. Email was: '${email}'`
    );
  }

  try {
    const userRecord = await admin.auth().getUserByEmail(email);
    await admin.auth().updateUser(userRecord.uid, {
      password: newPassword,
    });
    return { success: true, message: "Password updated successfully" };
  } catch (error) {
    console.error("UPDATE ERROR:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});