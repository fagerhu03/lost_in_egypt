/**
 * Eventbrite Sync Cloud Function
 * 
 * Since Eventbrite deprecated their public event search API in 2019,
 * this module uses the organization-based endpoint to fetch events
 * from known Egyptian event organizers.
 * 
 * For admins, there's also a "fetch by event ID" callable that lets
 * you import any Eventbrite event by its URL/ID directly into Firestore.
 * 
 * Security: Token is in Google Cloud Secret Manager.
 * 
 * Usage:
 *   firebase functions:secrets:set EVENTBRITE_API_TOKEN
 *   firebase deploy --only functions:importEventbriteEvent
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");

const eventbriteToken = defineSecret("EVENTBRITE_API_TOKEN");

// Category mapping from Eventbrite category IDs to our app categories
const EVENTBRITE_CATEGORIES = {
  "103": "concert",      // Music
  "105": "theatre",      // Performing & Visual Arts
  "110": "food",         // Food & Drink
  "113": "cultural",     // Community & Culture
  "104": "festival",     // Film, Media & Entertainment
  "108": "adventure",    // Sports & Fitness
  "107": "art",          // Health & Wellness
};

/**
 * Import a single Eventbrite event by its ID or URL.
 * Admin-only callable — use this from the Admin Events Panel.
 * 
 * Call with: { eventId: "123456789" } or { eventUrl: "https://eventbrite.com/e/123456789" }
 */
exports.importEventbriteEvent = onCall(
  { secrets: [eventbriteToken] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Login required.");
    }

    // Check admin role
    const userDoc = await admin.firestore()
      .collection("users")
      .doc(request.auth.uid)
      .get();

    if (!userDoc.exists || userDoc.data().role !== "admin") {
      throw new HttpsError("permission-denied", "Admin access required.");
    }

    // Extract event ID from URL or direct ID
    let eventId = request.data?.eventId || "";
    const eventUrl = request.data?.eventUrl || "";
    
    if (!eventId && eventUrl) {
      // Extract ID from URL like https://www.eventbrite.com/e/event-name-123456789
      const match = eventUrl.match(/(\d{10,})/);
      if (match) eventId = match[1];
    }

    if (!eventId) {
      throw new HttpsError("invalid-argument", "Provide eventId or eventUrl.");
    }

    const token = eventbriteToken.value();

    try {
      return await processEventbriteEvent(eventId, token);
    } catch (err) {
      console.error("importEventbriteEvent error:", err.message);
      throw new HttpsError("internal", `Failed to import: ${err.message}`);
    }
  }
);

async function processEventbriteEvent(eventId, token) {
    try {
      // Fetch event details with venue info
      const res = await fetch(
        `https://www.eventbriteapi.com/v3/events/${eventId}/?expand=venue,category,ticket_availability`,
        {
          headers: {
            "Authorization": `Bearer ${token}`,
            "Content-Type": "application/json",
          },
        }
      );

      if (!res.ok) {
        const errBody = await res.text();
        throw new Error(`Eventbrite API ${res.status}: ${errBody}`);
      }

      const event = await res.json();
      const firestoreData = mapEventbriteToFirestore(event);

      if (!firestoreData) {
        throw new HttpsError("invalid-argument", "Could not parse event data.");
      }

      // Save to Firestore
      const docId = `eventbrite_${eventId}`;
      await admin.firestore().collection("events").doc(docId).set({
        ...firestoreData,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      return {
        success: true,
        docId,
        title: firestoreData.title,
        message: `Imported "${firestoreData.title}" successfully.`,
      };
    } catch (err) {
      console.error("processEventbriteEvent error:", err.message);
      throw err;
    }
}

exports.processEventbriteEvent = processEventbriteEvent;

/**
 * Fetch all events from a specific Eventbrite organization.
 * Admin-only callable.
 * 
 * Call with: { organizationId: "123456789" }
 */
exports.importEventbriteOrganization = onCall(
  { secrets: [eventbriteToken] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Login required.");
    }

    const userDoc = await admin.firestore()
      .collection("users")
      .doc(request.auth.uid)
      .get();

    if (!userDoc.exists || userDoc.data().role !== "admin") {
      throw new HttpsError("permission-denied", "Admin access required.");
    }

    const orgId = request.data?.organizationId;
    if (!orgId) {
      throw new HttpsError("invalid-argument", "organizationId required.");
    }

    const token = eventbriteToken.value();
    const db = admin.firestore();
    const stats = { total: 0, imported: 0, skipped: 0 };

    try {
      let hasMore = true;
      let continuation = null;

      while (hasMore) {
        let url = `https://www.eventbriteapi.com/v3/organizations/${orgId}/events/?expand=venue,category&status=live&order_by=start_asc&page_size=50`;
        if (continuation) url += `&continuation=${continuation}`;

        const res = await fetch(url, {
          headers: { "Authorization": `Bearer ${token}` },
        });

        if (!res.ok) break;

        const data = await res.json();
        const events = data.events || [];
        stats.total += events.length;

        for (const event of events) {
          const firestoreData = mapEventbriteToFirestore(event);
          if (!firestoreData) {
            stats.skipped++;
            continue;
          }

          const docId = `eventbrite_${event.id}`;
          await db.collection("events").doc(docId).set({
            ...firestoreData,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });
          stats.imported++;
        }

        hasMore = data.pagination?.has_more_items || false;
        continuation = data.pagination?.continuation || null;
      }

      return { success: true, stats };
    } catch (err) {
      console.error("importEventbriteOrganization error:", err.message);
      throw new HttpsError("internal", `Failed: ${err.message}`);
    }
  }
);

/**
 * Map an Eventbrite event to our Firestore schema.
 */
function mapEventbriteToFirestore(event) {
  const title = event.name?.text || "";
  if (!title) return null;

  const description = (event.description?.text || event.summary || "").slice(0, 2000);
  const startDate = event.start?.utc ? new Date(event.start.utc) : new Date();

  // Venue info
  const venue = event.venue || {};
  const venueName = venue.name || "";
  const venueAddress = venue.address?.localized_address_display || "";
  const venueLat = parseFloat(venue.latitude) || 30.0444;
  const venueLng = parseFloat(venue.longitude) || 31.2357;
  const venueCity = venue.address?.city || "Cairo";

  // Category
  const ebCategoryId = event.category_id || "";
  let eventCategory = EVENTBRITE_CATEGORIES[ebCategoryId];

  if (!eventCategory) {
    const lowerText = (title + " " + description).toLowerCase();
    eventCategory = "cultural";
    if (lowerText.match(/music|concert|dj|band|singer|live performance|song|party|rave|recital|gig|orchestra|symphony|choir|عود|موسيقى|حفلة|غناء|فرقة|طرب|دي جي/)) eventCategory = "concert";
    else if (lowerText.match(/theatre|theater|play|comedy|stand-up|drama|actor|performance|performing arts|musical|opera|ballet|show|مسرح|مسرحية|كوميديا|تمثيل/)) eventCategory = "theatre";
    else if (lowerText.match(/festival|carnival|fair|gala|seasonal|holiday|celebration|parade|fiesta|jamboree|مهرجان|احتفال/)) eventCategory = "festival";
    else if (lowerText.match(/art|exhibition|gallery|museum|painting|sculpture|craft|workshop|pottery|film|media|visual arts|photography|design|fashion|beauty|class|training|retreat|culture|معرض|فن|رسم|ورشة|نحت/)) eventCategory = "art";
    else if (lowerText.match(/hike|camp|desert|safari|diving|beach|mountain|outdoor|kayak|canoe|sport|run|marathon|climb|cycle|bike|yoga|auto|boat|air|fitness|travel|trip|attraction|game|competition|مغامرة|تخييم|سفاري|غوص|كاياك/)) eventCategory = "adventure";
    else if (lowerText.match(/food|taste|market|bazaar|cuisine|cooking|dine|drink|dinner|tasting|culinary|recipe|طعام|أكل|مطبخ/)) eventCategory = "food";
    else if (lowerText.match(/cruise|felucca|yacht|dinner on water|nile tour|sailing|river|نيل|مركب|رحلة نيلية/)) eventCategory = "cruise";
  }

  // Pricing
  const isFree = event.is_free === true;
  const minPrice = event.ticket_availability?.minimum_ticket_price?.major_value;
  const price = isFree ? 0 : (parseFloat(minPrice) || 0);

  // Image
  const imagePath = event.logo?.url || event.logo?.original?.url || "";

  // Duration
  let duration = "";
  if (event.start?.utc && event.end?.utc) {
    const diffHours = (new Date(event.end.utc) - new Date(event.start.utc)) / (1000 * 60 * 60);
    if (diffHours < 1) duration = `${Math.round(diffHours * 60)} min`;
    else if (diffHours < 24) duration = `${diffHours.toFixed(1)} hours`;
    else duration = `${Math.round(diffHours / 24)} days`;
  }

  return {
    title,
    description,
    venueName,
    locationAddress: venueAddress,
    city: venueCity,
    eventCategory,
    coordinate: new admin.firestore.GeoPoint(venueLat, venueLng),
    imagePath,
    imagePaths: imagePath ? [imagePath] : [],
    date: admin.firestore.Timestamp.fromDate(startDate),
    price,
    duration,
    rating: 0,
    importance: 5,
    ticketLink: event.url || "",
    tags: [eventCategory, "eventbrite", venueCity.toLowerCase()],
    isRecurring: event.is_series === true || !!event.series_id,
    recurrenceText: (event.is_series === true || !!event.series_id) ? "Multiple dates" : "",
    source: "eventbrite",
    isEvent: true,
    weather: "",
    eventbriteId: event.id,
  };
}

module.exports = exports;
