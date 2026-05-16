import 'package:flutter/material.dart';
import 'package:lost_in_egypt/theme/theme.dart';
import '../../../../../../auth/data/models/user.dart';

class GuideCard extends StatelessWidget {
  final UserModel guide;

  const GuideCard({
    super.key,
    required this.guide,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleColor =
    isDark ? AppColors.darkText : AppColors.lightText;

    final labelColor = isDark
        ? AppColors.darkText.withValues(alpha: 0.65)
        : AppColors.lightText.withValues(alpha: 0.55);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // ✅ Brighter box in light mode
        color: isDark
            ? AppColors.darkBox.withValues(alpha: 0.65)
            : Color(0xffFFFEF0),

        borderRadius: BorderRadius.circular(14),

        border: Border.all(
          color: isDark
              ? AppColors.darkText.withValues(alpha: 0.12)
              : const Color(0xFFE6D8B8),
        ),

        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: isDark
                            ? const [Color(0xFF3E2C1E), Color(0xFF2A2119)]
                            : const [Color(0xFF7A4B1D), Color(0xFF4B3021)],
                      ),
                    ),
                    child: guide.profileImageUrl.isNotEmpty
                        ? Image.network(
                            guide.profileImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.person,
                              color: Color(0xFFEDE9D9),
                              size: 52,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: Color(0xFFEDE9D9),
                            size: 52,
                          ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black54 : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: Colors.red.shade300,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${guide.firstName} ${guide.lastName}'.trim(),
                      style: TextStyle(
                        fontSize: 28,
                        color: titleColor,
                        height: 0.95,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (guide.reviewCount == 0)
                      Text(
                        "New Guide", 
                        style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.w600)
                      )
                    else 
                      Row(
                        children: [
                          Text('${guide.rating.toStringAsFixed(1)} ', style: TextStyle(color: titleColor, fontSize: 16)),
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          Text(' (${guide.reviewCount})', style: TextStyle(color: labelColor, fontSize: 14)),
                        ],
                      ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 15,
                          color: titleColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          guide.nationality.isNotEmpty ? guide.nationality : 'Egypt',
                          style: TextStyle(
                            fontSize: 20,
                            color: titleColor,
                            height: 0.95,
                          ),
                        ),
                      ],
                    ),
                    // Removed contact for price
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: isDark
                ? AppColors.darkText.withValues(alpha: 0.15)
                : AppColors.lightText.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Language',
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  guide.certifiedLanguages.isNotEmpty ? guide.certifiedLanguages.join(', ') : 'Arabic, English',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Available Time',
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Flexible',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}