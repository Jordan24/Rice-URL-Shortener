const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

const DEFAULT_FALLBACK_URL = "https://rice.edu";

/**
 * High-speed HTTP redirect handler for Rice shortened URLs
 */
exports.redirect = onRequest({ cors: true, region: "us-central1" }, async (req, res) => {
  try {
    // Extract shortcode from path (e.g. /xyz12 or /app)
    const rawPath = req.path.replace(/^\/+/, "").split("/")[0];
    const code = (rawPath || req.query.code || "").trim().toLowerCase();

    if (!code) {
      return res.redirect(302, DEFAULT_FALLBACK_URL);
    }

    // 1. Direct O(1) Firestore Document lookup by shortCode
    let linkDoc = await db.collection("links").doc(code).get();

    // Fallback to collection query for backward compatibility with legacy documents
    if (!linkDoc.exists) {
      const snapshot = await db
        .collection("links")
        .where("shortCode", "==", code)
        .limit(1)
        .get();

      if (!snapshot.empty) {
        linkDoc = snapshot.docs[0];
      }
    }

    if (!linkDoc || !linkDoc.exists) {
      return res.redirect(302, DEFAULT_FALLBACK_URL);
    }

    const link = linkDoc.data();

    // Check active status
    if (link.isActive === false) {
      return res.redirect(302, link.fallbackUrl || DEFAULT_FALLBACK_URL);
    }

    // Check expiration
    if (link.expiresAt) {
      const expirationDate = link.expiresAt.toDate ? link.expiresAt.toDate() : new Date(link.expiresAt);
      if (expirationDate < new Date()) {
        // Link has expired -> redirect to configured fallback URL
        const fallback = link.fallbackUrl || DEFAULT_FALLBACK_URL;
        return res.redirect(302, fallback);
      }
    }

    // Active & valid link -> Destination URL
    const destination = link.destinationUrl;
    if (!destination) {
      return res.redirect(302, DEFAULT_FALLBACK_URL);
    }

    // Atomically increment click count and record timestamp asynchronously
    linkDoc.ref.update({
      clickCount: admin.firestore.FieldValue.increment(1),
      lastClickedAt: admin.firestore.FieldValue.serverTimestamp(),
    }).catch((err) => console.error("Error updating click analytics:", err));

    // Redirect to destination
    res.set("Cache-Control", "private, no-cache");
    return res.redirect(301, destination);
  } catch (error) {
    console.error("Redirect error:", error);
    return res.redirect(302, DEFAULT_FALLBACK_URL);
  }
});
