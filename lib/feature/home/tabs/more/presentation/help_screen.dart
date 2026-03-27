import 'package:flutter/material.dart';

// ── Section model ─────────────────────────────────────────────────────────────
class _Section {
  final String title;
  final IconData icon;
  final List<_FAQ> faqs;
  const _Section({required this.title, required this.icon, required this.faqs});
}

class _FAQ {
  final String question;
  final String answer;
  const _FAQ({required this.question, required this.answer});
}

// ── Data ──────────────────────────────────────────────────────────────────────
const _sections = [
  _Section(
    title: "Getting Started",
    icon: Icons.explore_outlined,
    faqs: [
      _FAQ(
        question: "How do I discover landmarks?",
        answer:
            "Open the Camera tab and point your phone at any Egyptian landmark. "
            "The AI will identify it and generate a historical story read aloud by your personal guide. "
            "Each discovery is saved to your profile and counts toward your badge progress.",
      ),
      _FAQ(
        question: "How do I earn badges?",
        answer:
            "Badges are earned by discovering landmarks through the Camera tab. "
            "Visit 1, 3, 5, 10, and 20 unique landmarks to unlock Novice Explorer, Tourist, "
            "Tomb Raider, Historian, and Pharaoh badges respectively. "
            "There are also hidden badges — explore and find them!",
      ),
      _FAQ(
        question: "How do I become a tour guide?",
        answer:
            "Go to Account → Apply as Guide. You'll need your MOTA license number, syndicate number, "
            "certified languages, and supporting documents. Applications are reviewed by our admin team "
            "and you will be notified of the outcome in-app.",
      ),
    ],
  ),
  _Section(
    title: "Map & Places",
    icon: Icons.map_outlined,
    faqs: [
      _FAQ(
        question: "Can I save places to visit later?",
        answer:
            "Yes! On the Map tab, tap any landmark pin and press the bookmark icon to save it. "
            "You can also save events from the Home tab by tapping the heart icon on any event card. "
            "Access all your saved places from the Map tab → Saved Places.",
      ),
      _FAQ(
        question: "My camera didn't recognise a landmark — what should I do?",
        answer:
            "Ensure the landmark fills most of the frame and is well lit. "
            "Tap the shutter button and wait a few seconds. "
            "If the landmark is very minor or off the main tourist trail it may not be in the database yet.",
      ),
    ],
  ),
  _Section(
    title: "Bookings & Payments",
    icon: Icons.confirmation_number_outlined,
    faqs: [
      _FAQ(
        question: "How do I book a tour?",
        answer:
            "Go to the Home tab and browse available guided tours, or find one on the Map tab. "
            "Choose a tour, select your date and number of tickets, then complete payment "
            "using any of the available payment methods shown at checkout (card, Apple Pay, or mobile wallet).",
      ),
      _FAQ(
        question: "How do I cancel a booking?",
        answer:
            "Go to Account → My Bookings, find the booking under the Upcoming tab, and tap Cancel. "
            "Refund policies are set by each guide — check the tour details before booking.",
      ),
      _FAQ(
        question: "Is my payment information secure?",
        answer:
            "Yes. Payments are processed through Paymob, a certified PCI-compliant payment gateway. "
            "Lost in Egypt never stores your card or wallet details on its servers.",
      ),
      _FAQ(
        question: "How do I change my display currency?",
        answer:
            "Go to More → Settings → Preferred Currency. All tour prices across the app "
            "will display in your chosen currency. The actual charge at checkout is always processed "
            "in EGP via Paymob.",
      ),
    ],
  ),
  _Section(
    title: "Community",
    icon: Icons.people_outline_rounded,
    faqs: [
      _FAQ(
        question: "How do I post in the community?",
        answer:
            "Tap the Community tab and press the + button. You can write text, add photos, "
            "tag a location, choose a category (Travel Story, Question, Tip, etc.), "
            "and use #hashtags or @mention other users.",
      ),
      _FAQ(
        question: "How do I report a post or user?",
        answer:
            "On any community post or comment, tap the ⋮ menu and select Report. "
            "Our admin team reviews all reports and takes action within 24 hours.",
      ),
    ],
  ),
  _Section(
    title: "Account & Settings",
    icon: Icons.manage_accounts_outlined,
    faqs: [
      _FAQ(
        question: "How do I change my username?",
        answer:
            "Go to Account → Edit Profile. Your username (e.g. @ahmed_x1) must be 3–20 characters, "
            "lowercase letters, numbers, and underscores only, and globally unique. "
            "It is displayed on all your posts and comments.",
      ),
      _FAQ(
        question: "How do I switch between light and dark mode?",
        answer:
            "Go to More → Settings and toggle the Dark Mode switch. "
            "Your preference is saved to your account and synced across devices.",
      ),
    ],
  ),
  _Section(
    title: "Offline Mode",
    icon: Icons.wifi_off_rounded,
    faqs: [
      _FAQ(
        question: "What can I use without an internet connection?",
        answer:
            "Lost in Egypt is designed primarily as an online experience, but several features "
            "remain available offline:\n\n"
            "• Map pins — over 500 Egyptian landmarks are bundled locally in the app, so the map "
            "shows location markers even without internet (map tiles themselves require connectivity).\n"
            "• Cached images — places and event images you have previously viewed are stored on "
            "your device and load instantly offline.\n"
            "• Text recognition (Camera → Scan text) — ML Kit processes text entirely on-device.\n"
            "• Translator — once a language pack is downloaded, translation works offline.\n"
            "• App navigation, badges, and settings — always available.",
      ),
      _FAQ(
        question: "What features require an internet connection?",
        answer:
            "The following features need an active connection:\n\n"
            "• Landmark identification via the Camera tab (uses Google Cloud Vision API)\n"
            "• AI historical story generation (uses Google Gemini)\n"
            "• Community posts, likes, and comments (Firestore)\n"
            "• Browsing and booking tours (Firestore)\n"
            "• Events feed (Firestore)\n"
            "• Currency conversion (live exchange rates)\n"
            "• SOS — nearest emergency services search (Google Places API)\n"
            "• Signing in or creating an account (Firebase Auth)",
      ),
      _FAQ(
        question: "Will offline-capable features improve over time?",
        answer:
            "Yes. We plan to expand offline support in future updates, including downloadable "
            "city guides and cached tour content. Keep the app updated to get these improvements.",
      ),
    ],
  ),
  _Section(
    title: "Safety & Emergency",
    icon: Icons.shield_outlined,
    faqs: [
      _FAQ(
        question: "What do I do in an emergency?",
        answer:
            "Open More → SOS. You can find the nearest police station, hospital, or fire station "
            "using your current location, or dial Egypt's official emergency numbers directly from the app:\n"
            "• Police: 122\n"
            "• Ambulance: 123\n"
            "• Fire: 180\n"
            "• Tourist Police: 126",
      ),
    ],
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & FAQ", style: TextStyle(fontFamily: 'Marcellus')),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: onSurface,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        itemCount: _sections.length,
        itemBuilder: (context, si) {
          final section = _sections[si];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (si > 0) const SizedBox(height: 24),
              // Section header
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(section.icon, size: 18, color: primary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    section.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Marcellus',
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...section.faqs.asMap().entries.map((e) => Padding(
                    padding: EdgeInsets.only(bottom: e.key < section.faqs.length - 1 ? 8 : 0),
                    child: _FaqTile(faq: e.value, primary: primary),
                  )),
            ],
          );
        },
      ),
    );
  }
}

// ── Tile ─────────────────────────────────────────────────────────────────────
class _FaqTile extends StatefulWidget {
  final _FAQ faq;
  final Color primary;
  const _FaqTile({required this.faq, required this.primary});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final gold = widget.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _expanded ? gold.withOpacity(0.35) : gold.withOpacity(0.12),
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.faq.question,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                        fontFamily: 'Marcellus',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: gold,
                    size: 22,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 10),
                Text(
                  widget.faq.answer,
                  style: TextStyle(
                    fontSize: 13,
                    color: onSurface.withOpacity(0.75),
                    height: 1.6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
