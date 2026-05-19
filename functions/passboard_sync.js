const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const cheerio = require("cheerio");

/**
 * Converts a local Cairo date and time into a UTC Date object,
 * dynamically determining the correct offset (including DST) for that date.
 */
function getCairoUTCDate(year, month, day, hours, minutes) {
  // Construct a date string in UTC as a starting point
  const utcDate = new Date(Date.UTC(year, month - 1, day, hours, minutes));
  
  // Format the date in Africa/Cairo timezone to get its local parts
  const formatter = new Intl.DateTimeFormat('en-US', {
    timeZone: 'Africa/Cairo',
    year: 'numeric',
    month: 'numeric',
    day: 'numeric',
    hour: 'numeric',
    minute: 'numeric',
    second: 'numeric',
    hour12: false
  });
  
  const parts = formatter.formatToParts(utcDate);
  const cairoParts = {};
  parts.forEach(p => cairoParts[p.type] = parseInt(p.value));
  
  // Calculate cairoLocalTimeInUTC
  const cairoLocalTimeInUTC = Date.UTC(
    cairoParts.year,
    cairoParts.month - 1,
    cairoParts.day,
    cairoParts.hour,
    cairoParts.minute
  );
  
  // The offset is the difference: (Cairo Time of utcDate) - (UTC Time of utcDate)
  const offsetMs = cairoLocalTimeInUTC - utcDate.getTime();
  
  // Now subtract the offset from the target time (in UTC coords) to get the actual UTC Date
  const targetLocalTimeInUTC = Date.UTC(year, month - 1, day, hours, minutes);
  return new Date(targetLocalTimeInUTC - offsetMs);
}

/**
 * Import a single Passboard event by its URL.
 * Admin-only callable.
 */
exports.importPassboardEvent = onCall(
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

    const eventUrl = request.data?.eventUrl || "";
    if (!eventUrl || !eventUrl.includes("passboard.net")) {
      throw new HttpsError("invalid-argument", "Provide a valid Passboard URL.");
    }

    try {
      return await processPassboardEvent(eventUrl);
    } catch (err) {
      console.error("importPassboardEvent error:", err.message);
      throw new HttpsError("internal", `Failed to import: ${err.message}`);
    }
  }
);

async function processPassboardEvent(eventUrl) {
  try {
      const res = await fetch(eventUrl);
      if (!res.ok) {
        throw new Error(`Passboard returned ${res.status}`);
      }

      const html = await res.text();
      const $ = cheerio.load(html);

      // Extract OpenGraph tags
      const title = $('meta[property="og:title"]').attr('content') || $('title').text() || "Imported Passboard Event";
      const description = $('meta[property="og:description"]').attr('content') || "";
      const imagePath = $('meta[property="og:image"]').attr('content') || "";

      // We extract the slug from the URL to use as ID
      const urlParts = eventUrl.split('/');
      const slug = urlParts[urlParts.length - 1].split('?')[0];
      const docId = `passboard_${slug || Date.now()}`;

      // Context-based categorization
      const lowerText = (title + " " + description).toLowerCase();
      let eventCategory = "cultural";
      if (lowerText.match(/music|concert|dj|band|singer|live performance|song|party|rave|recital|gig|orchestra|symphony|choir|عود|موسيقى|حفلة|غناء|فرقة|طرب|دي جي/)) eventCategory = "concert";
      else if (lowerText.match(/theatre|theater|play|comedy|stand-up|drama|actor|performance|performing arts|musical|opera|ballet|show|مسرح|مسرحية|كوميديا|تمثيل/)) eventCategory = "theatre";
      else if (lowerText.match(/festival|carnival|fair|gala|seasonal|holiday|celebration|parade|fiesta|jamboree|مهرجان|احتفال/)) eventCategory = "festival";
      else if (lowerText.match(/art|exhibition|gallery|museum|painting|sculpture|craft|workshop|pottery|film|media|visual arts|photography|design|fashion|beauty|class|training|retreat|culture|معرض|فن|رسم|ورشة|نحت/)) eventCategory = "art";
      else if (lowerText.match(/hike|camp|desert|safari|diving|beach|mountain|outdoor|kayak|canoe|sport|run|marathon|climb|cycle|bike|yoga|auto|boat|air|fitness|travel|trip|attraction|game|competition|مغامرة|تخييم|سفاري|غوص|كاياك/)) eventCategory = "adventure";
      else if (lowerText.match(/food|taste|market|bazaar|cuisine|cooking|dine|drink|dinner|tasting|culinary|recipe|طعام|أكل|مطبخ/)) eventCategory = "food";
      else if (lowerText.match(/cruise|felucca|yacht|dinner on water|nile tour|sailing|river|نيل|مركب|رحلة نيلية/)) eventCategory = "cruise";

      // Location extraction from Passboard Next.js state
      let venueName = "Check Passboard for details";
      let locationAddress = "";
      let latitude = 30.0444; // Default Cairo
      let longitude = 31.2357;
      let city = "Cairo";

      const locNameMatch = html.match(/locationName\\?":\\?"(.*?)\\?"/);
      if (locNameMatch && locNameMatch[1] && locNameMatch[1].trim() !== "") {
        venueName = locNameMatch[1];
      }

      const addressMatch = html.match(/\\"text\\":\\"([^\\"]+)\\"/);
      if (addressMatch && addressMatch[1] && addressMatch[1].trim() !== "") {
        locationAddress = addressMatch[1];
        if (locationAddress.toLowerCase().includes("alexandria")) {
          city = "Alexandria";
        } else if (locationAddress.toLowerCase().includes("giza") || locationAddress.toLowerCase().includes("october")) {
          city = "Giza";
        } else if (locationAddress.toLowerCase().includes("dahab")) {
          city = "Dahab";
        }
      }

      const latMatch = html.match(/\\"latitude\\":\\"([^\\"]+)\\"/);
      const lngMatch = html.match(/\\"longitude\\":\\"([^\\"]+)\\"/);
      if (latMatch && lngMatch && latMatch[1] && lngMatch[1]) {
        const lat = parseFloat(latMatch[1]);
        const lng = parseFloat(lngMatch[1]);
        if (!isNaN(lat) && !isNaN(lng)) {
          latitude = lat;
          longitude = lng;
        }
      }

      // ── Date extraction ──────────────────────────────────────────────
      let eventDate = new Date(); // fallback: now
      let dateSource = "fallback";

      // Try 0: Unix timestamp (seconds) in Passboard's embedded RSC/JSON payload
      // e.g.  "startDate":1779447633  — a 10-digit number, NOT a quoted string
      const unixTsMatch = html.match(/\\?"startDate\\?"\s*:\s*(\d{9,11})/);
      if (unixTsMatch && unixTsMatch[1]) {
        const ts = parseInt(unixTsMatch[1], 10);
        const parsed = new Date(ts * 1000); // seconds → milliseconds
        if (!isNaN(parsed.getTime()) && parsed.getFullYear() >= 2024) {
          eventDate = parsed;
          dateSource = "unix_timestamp";
          console.log(`Passboard unix timestamp: ${ts} → ${parsed.toISOString()}`);
        }
      }

      // Try 1: structured startDate from Passboard's embedded JSON (quoted ISO string)
      const startDateMatch = dateSource === "unix_timestamp"
        ? null
        : html.match(/startDate\\?":\\s*\\?"([^\\?"]+)\\?"/);
      if (startDateMatch && startDateMatch[1]) {
        const parsed = new Date(startDateMatch[1]);
        if (!isNaN(parsed.getTime())) {
          eventDate = parsed;
          dateSource = "structured";
        }
      }

      // Try 2: ISO-like date in __NEXT_DATA__ or script tags
      if (dateSource === "fallback") {
        const isoMatch = html.match(/"date"\s*:\s*"(\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2})/);
        if (isoMatch && isoMatch[1]) {
          const parsed = new Date(isoMatch[1]);
          if (!isNaN(parsed.getTime())) {
            eventDate = parsed;
            dateSource = "iso";
          }
        }
      }

      // Try 3: human-readable date in og:description or page body
      if (dateSource === "fallback") {
        const datePatterns = [
          // "18 May 2026" or "18 May"
          /(\d{1,2})\s+(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\s*(\d{4})?/i,
          // "May 18, 2026" or "May 18th"
          /(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\s+(\d{1,2})(?:st|nd|rd|th)?,?\s*(\d{4})?/i,
        ];
        const searchText = description + " " + title + " " + $('body').text().slice(0, 3000);
        for (const pattern of datePatterns) {
          const m = searchText.match(pattern);
          if (m) {
            let dateStr;
            if (/^\d/.test(m[1])) {
              // "18 May 2026"
              dateStr = `${m[1]} ${m[2]} ${m[3] || new Date().getFullYear()}`;
            } else {
              // "May 18, 2026"
              dateStr = `${m[2]} ${m[1]} ${m[3] || new Date().getFullYear()}`;
            }
            const parsed = new Date(dateStr);
            if (!isNaN(parsed.getTime())) {
              eventDate = parsed;
              dateSource = "human";
              break;
            }
          }
        }
      }

      // Only try to extract/override time when we DON'T have a precise unix timestamp.
      // The unix timestamp already encodes the exact date + time.
      if (dateSource !== "unix_timestamp") {
        // Try to extract time (e.g. "8:00 PM", "09:00 PM")
        const timeMatch = (description + " " + title + " " + $('body').text().slice(0, 3000))
          .match(/(\d{1,2}):(\d{2})\s*(AM|PM|am|pm)/);
        let hours = 20, minutes = 0; // Default 8 PM
        if (timeMatch) {
          hours = parseInt(timeMatch[1]);
          minutes = parseInt(timeMatch[2]);
          const ampm = timeMatch[3].toUpperCase();
          if (ampm === "PM" && hours < 12) hours += 12;
          if (ampm === "AM" && hours === 12) hours = 0;
          
          eventDate = getCairoUTCDate(
            eventDate.getFullYear(),
            eventDate.getMonth() + 1,
            eventDate.getDate(),
            hours,
            minutes
          );
        } else if (dateSource === "human" || dateSource === "fallback") {
          eventDate = getCairoUTCDate(
            eventDate.getFullYear(),
            eventDate.getMonth() + 1,
            eventDate.getDate(),
            20,
            0
          );
        }
      }

      const firestoreData = {
        title,
        description: description.slice(0, 2000),
        venueName,
        locationAddress,
        city,
        eventCategory,
        coordinate: new admin.firestore.GeoPoint(latitude, longitude),
        imagePath,
        imagePaths: imagePath ? [imagePath] : [],
        date: admin.firestore.Timestamp.fromDate(eventDate),
        price: 0,
        duration: "",
        rating: 0,
        importance: 10, // Max priority to show first!
        ticketLink: eventUrl,
        tags: ["passboard"],
        isRecurring: false,
        recurrenceText: "",
        source: "passboard",
        isEvent: true,
        weather: "",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      await admin.firestore().collection("events").doc(docId).set(firestoreData, { merge: true });

      return {
        success: true,
        docId,
        title: firestoreData.title,
        message: `Imported "${firestoreData.title}" successfully.`,
      };
    } catch (err) {
      console.error("processPassboardEvent error:", err.message);
      throw err;
    }
}

exports.processPassboardEvent = processPassboardEvent;

const { onRequest } = require("firebase-functions/v2/https");

exports.migrateCategories = onRequest(async (req, res) => {
  const db = admin.firestore();
  const snap = await db.collection("events").get();
  let updatedCount = 0;
  
  function categorizeEvent(text) {
    const lowerText = text.toLowerCase();
    if (lowerText.match(/music|concert|dj|band|singer|live performance|song|party|rave|recital|gig|orchestra|symphony|choir|عود|موسيقى|حفلة|غناء|فرقة|طرب|دي جي/)) return "concert";
    if (lowerText.match(/theatre|theater|play|comedy|stand-up|drama|actor|performance|performing arts|musical|opera|ballet|show|مسرح|مسرحية|كوميديا|تمثيل/)) return "theatre";
    if (lowerText.match(/festival|carnival|fair|gala|seasonal|holiday|celebration|parade|fiesta|jamboree|مهرجان|احتفال/)) return "festival";
    if (lowerText.match(/art|exhibition|gallery|museum|painting|sculpture|craft|workshop|pottery|film|media|visual arts|photography|design|fashion|beauty|class|training|retreat|culture|معرض|فن|رسم|ورشة|نحت/)) return "art";
    if (lowerText.match(/hike|camp|desert|safari|diving|beach|mountain|outdoor|kayak|canoe|sport|run|marathon|climb|cycle|bike|yoga|auto|boat|air|fitness|travel|trip|attraction|game|competition|مغامرة|تخييم|سفاري|غوص|كاياك/)) return "adventure";
    if (lowerText.match(/food|taste|market|bazaar|cuisine|cooking|dine|drink|dinner|tasting|culinary|recipe|طعام|أكل|مطبخ/)) return "food";
    if (lowerText.match(/cruise|felucca|yacht|dinner on water|nile tour|sailing|river|نيل|مركب|رحلة نيلية/)) return "cruise";
    return "cultural";
  }

  function extractDate(text) {
    const patterns = [
      /(\d{1,2})\s+(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\s*(\d{4})?/i,
      /(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\s+(\d{1,2})(?:st|nd|rd|th)?,?\s*(\d{4})?/i,
    ];
    
    const months = { jan: '01', january: '01', feb: '02', february: '02', mar: '03', march: '03', apr: '04', april: '04', may: '05', jun: '06', june: '06', jul: '07', july: '07', aug: '08', august: '08', sep: '09', september: '09', oct: '10', october: '10', nov: '11', november: '11', dec: '12', december: '12' };

    for (const pattern of patterns) {
      const m = text.match(pattern);
      if (m) {
        let day, monthStr, year;
        if (/^\d/.test(m[1])) {
          day = m[1].padStart(2, '0');
          monthStr = m[2].toLowerCase();
          year = m[3] || String(new Date().getFullYear());
        } else {
          monthStr = m[1].toLowerCase();
          day = m[2].padStart(2, '0');
          year = m[3] || String(new Date().getFullYear());
        }
        const month = months[monthStr];
        if (!month) continue;

        // Extract time from text (e.g. "8:00 PM")
        let hours = 20, minutes = 0; // Default 8 PM Cairo
        const timeMatch = text.match(/(\d{1,2}):(\d{2})\s*(AM|PM|am|pm)/);
        if (timeMatch) {
          hours = parseInt(timeMatch[1]);
          minutes = parseInt(timeMatch[2]);
          const ampm = timeMatch[3].toUpperCase();
          if (ampm === "PM" && hours < 12) hours += 12;
          if (ampm === "AM" && hours === 12) hours = 0;
        }

        const parsed = getCairoUTCDate(
          parseInt(year),
          parseInt(month),
          parseInt(day),
          hours,
          minutes
        );
        if (parsed && !isNaN(parsed.getTime())) return parsed;
      }
    }
    return null;
  }

  let totalEvents = 0;
  let passboardEvents = 0;
  let dateFixed = 0;
  
  for (const doc of snap.docs) {
    totalEvents++;
    const data = doc.data();
    const updates = {};

    if (data.source === "passboard" || data.source === "eventbrite") {
      passboardEvents++;
      const text = (data.title + " " + (data.description || ""));
      updates.eventCategory = categorizeEvent(text.toLowerCase());

      // Fix date if it looks wrong (exact timestamp mismatch, handling hours/timezones)
      const storedDate = data.date?.toDate();
      const extractedDate = extractDate(text);
      if (extractedDate && storedDate) {
        if (storedDate.getTime() !== extractedDate.getTime()) {
          updates.date = admin.firestore.Timestamp.fromDate(extractedDate);
          dateFixed++;
          console.log(`Fixed date for "${data.title}": ${storedDate.toISOString()} -> ${extractedDate.toISOString()}`);
        }
      }

      await doc.ref.update(updates);
      updatedCount++;
    }
  }
  res.send(`Events: ${totalEvents}. Updated: ${updatedCount}. Dates fixed: ${dateFixed}.`);
});




