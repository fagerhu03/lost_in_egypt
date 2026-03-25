import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    _FAQ(
      question: "How do I discover landmarks?",
      answer:
          "Open the Camera tab and point your phone at any Egyptian landmark. "
          "The AI will identify it and generate a historical story read aloud by your personal guide.",
    ),
    _FAQ(
      question: "How do I book a tour?",
      answer:
          "Go to the Home tab and browse available guided tours, or find one on the Map tab. "
          "Choose a tour, select your date and number of tickets, then complete payment "
          "using any of the available payment methods shown at checkout.",
    ),
    _FAQ(
      question: "How do I earn badges?",
      answer:
          "Badges are earned by discovering landmarks through the Camera tab. "
          "Visit 1, 3, 5, 10, and 20 unique landmarks to unlock Explorer, Tourist, Tomb Raider, "
          "Historian, and Pharaoh badges. There are also hidden badges — explore and find them!",
    ),
    _FAQ(
      question: "How do I become a tour guide?",
      answer:
          "Go to Account → Apply as Guide. You'll need your MOTA license number, syndicate number, "
          "certified languages, and supporting documents. Applications are reviewed by our admin team.",
    ),
    _FAQ(
      question: "Can I save places to visit later?",
      answer:
          "Yes! On the Map tab, tap any landmark pin and press the bookmark icon to save it. "
          "Access all your saved places from the Map tab → Saved Places.",
    ),
    _FAQ(
      question: "How do I change my display currency?",
      answer:
          "Go to More → Settings → Preferred Currency. All tour prices across the app "
          "will display in your chosen currency. The actual charge at checkout is always processed "
          "in the currency supported by the payment gateway.",
    ),
    _FAQ(
      question: "My camera didn't recognise a landmark — what should I do?",
      answer:
          "Ensure the landmark fills most of the frame and is well lit. "
          "Tap the shutter button and wait a few seconds. If the landmark is very minor or off "
          "the main tourist trail it may not be in the database yet.",
    ),
    _FAQ(
      question: "How do I cancel a booking?",
      answer:
          "Go to Account → My Bookings, find the booking under the Upcoming tab, and tap Cancel. "
          "Refund policies are set by each guide — check the tour details before booking.",
    ),
    _FAQ(
      question: "How do I report a post or user?",
      answer:
          "On any community post or comment, tap the ⋮ menu and select Report. "
          "Our admin team reviews all reports and takes action within 24 hours.",
    ),
    _FAQ(
      question: "Is my payment information secure?",
      answer:
          "Yes. Payments are processed through certified, PCI-compliant payment gateways. "
          "Lost in Egypt never stores your card or wallet details on its servers.",
    ),
    _FAQ(
      question: "What do I do in an emergency?",
      answer:
          "Open More → SOS. You can find the nearest police station, hospital, or fire station "
          "using your current location, or dial Egypt's official emergency numbers directly from the app.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & FAQ", style: TextStyle(fontFamily: 'Marcellus')),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: _faqs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _FaqTile(faq: _faqs[i], isDark: isDark, primary: primary),
      ),
    );
  }
}

class _FAQ {
  final String question;
  final String answer;
  const _FAQ({required this.question, required this.answer});
}

class _FaqTile extends StatefulWidget {
  final _FAQ faq;
  final bool isDark;
  final Color primary;
  const _FaqTile({required this.faq, required this.isDark, required this.primary});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: widget.isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.faq.question,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                        fontFamily: 'Marcellus',
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: widget.primary,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 10),
                Text(
                  widget.faq.answer,
                  style: TextStyle(
                    fontSize: 14,
                    color: onSurface.withOpacity(0.75),
                    height: 1.5,
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
