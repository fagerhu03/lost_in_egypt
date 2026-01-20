import 'package:flutter/material.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFFFFEF0);
    final card = const Color(0xFFFFFEF0);
    final chip = const Color(0xFFEFE6D6);
    final textDark = const Color(0xFF4A3D2E);
    final textMid = const Color(0xFF7A6A55);
    final border = const Color(0xFFFFFEF0);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Container(color: const Color(0xFFFCFBE8)),
          // Pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
              child: Image.asset(
                "assets/pattern_comp.png",
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),

          // Your main UI
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Where want to go?",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.search,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _IconPill(
                        icon: Icons.person_outline_rounded,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
                    children: [
                      // Header tag
                      Padding(
                        padding: const EdgeInsets.only(left: 2, bottom: 10),
                        child: Text(
                          "Community",
                          style: TextStyle(
                            color: textMid,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),

                      // Composer
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: border),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                              color: Colors.black.withOpacity(0.06),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const _Avatar(size: 34),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: chip,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: border),
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Share your thoughts....",
                                    style: TextStyle(
                                      color: textMid,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              height: 40,
                              width: 44,
                              decoration: BoxDecoration(
                                color: chip,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: border),
                              ),
                              child: Icon(Icons.image_outlined, color: textMid),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Post 1 (question)
                      _PostCard(
                        cardColor: card,
                        borderColor: border,
                        textDark: textDark,
                        textMid: textMid,
                        name: "Guy Hawkins",
                        flag: "🇯🇵",
                        time: "1 hour ago",
                        content:
                            "Where can I find a reliable SIM card in Giza for tourists?",
                        likes: 23,
                        dislikes: 4,
                        comments: 8,
                        withImage: false,
                      ),

                      const SizedBox(height: 12),

                      // Post 2 (short)
                      _PostCard(
                        cardColor: card,
                        borderColor: border,
                        textDark: textDark,
                        textMid: textMid,
                        name: "anonyms",
                        flag: "🇧🇷",
                        time: "3 hour ago",
                        content: "guys i think i am lost?",
                        likes: 50,
                        dislikes: 2,
                        comments: 96,
                        withImage: false,
                      ),

                      const SizedBox(height: 12),

                      // Post 3 (with image)
                      _PostCard(
                        cardColor: card,
                        borderColor: border,
                        textDark: textDark,
                        textMid: textMid,
                        name: "Mari.xd",
                        flag: "🇦🇷",
                        time: "3 hour ago",
                        content: "look what i found today on my solo trip!",
                        likes: 150,
                        dislikes: 6,
                        comments: 50,
                        withImage: true,
                        image: const _FakeImage(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.cardColor,
    required this.borderColor,
    required this.textDark,
    required this.textMid,
    required this.name,
    required this.flag,
    required this.time,
    required this.content,
    required this.likes,
    required this.dislikes,
    required this.comments,
    required this.withImage,
    this.image,
  });

  final Color cardColor;
  final Color borderColor;
  final Color textDark;
  final Color textMid;

  final String name;
  final String flag;
  final String time;
  final String content;

  final int likes;
  final int dislikes;
  final int comments;

  final bool withImage;
  final Widget? image;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const _Avatar(size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: textDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(flag, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      time,
                      style: TextStyle(
                        color: textMid,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_horiz_rounded, color: textMid),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            content,
            style: TextStyle(
              color: textDark,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1.25,
            ),
          ),

          if (withImage) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: image,
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Footer actions
          Row(
            children: [
              _MiniStat(
                icon: Icons.thumb_up_alt_outlined,
                value: likes,
                color: textMid,
              ),
              const SizedBox(width: 14),
              _MiniStat(
                icon: Icons.thumb_down_alt_outlined,
                value: dislikes,
                color: textMid,
              ),
              const SizedBox(width: 14),
              _MiniStat(
                icon: Icons.chat_bubble_outline_rounded,
                value: comments,
                color: textMid,
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          "$value",
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _IconPill extends StatelessWidget {
  const _IconPill({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.9)),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: const Color(0xFF2E1F16),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Container(
          height: size * 0.52,
          width: size * 0.52,
          decoration: BoxDecoration(
            color: const Color(0xFFE6A44A),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(
            Icons.person,
            size: size * 0.35,
            color: const Color(0xFF2E1F16),
          ),
        ),
      ),
    );
  }
}

class _FakeImage extends StatelessWidget {
  const _FakeImage();

  @override
  Widget build(BuildContext context) {
    // Replace with Image.asset(...) or Image.network(...)
    return Container(
      color: const Color(0xFFD9D0BE),
      child: const Center(child: Icon(Icons.landscape_outlined, size: 44)),
    );
  }
}
