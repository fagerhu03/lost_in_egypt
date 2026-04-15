import 'package:flutter/material.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/solo_trip/presention/widgets/customize_plan_card.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/solo_trip/presention/widgets/plan_card.dart';
import '../../../../../../../../theme/theme.dart';
import '../../../../navigator/widget/account_menu_button.dart';
import '../../../../navigator/widget/search_header.dart';

class SoloTripPage extends StatelessWidget {
  final String? profileImageUrl;
  final VoidCallback onSignOut;

  const SoloTripPage({
    super.key,
    required this.profileImageUrl,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;

    final sectionColor = isDark
        ? AppColors.darkPatternOverlay
        : const Color(0xFFFFFEF0);

    final titleColor = isDark ? AppColors.darkText : AppColors.lightBox;

    final patternOpacity = isDark ? 0.1 : 0.4;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: bgColor)),
          Positioned.fill(
            child: Opacity(
              opacity: patternOpacity,
              child: Image.asset(
                'assets/pattern_comp.png',
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeat,
                errorBuilder: (_, __, ___) => Container(),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [                        IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.chevron_left_rounded,
                        color: titleColor, size: 30,
                      ),
                    ),
                      Expanded(child:
                      SearchHeader(onSignOut: onSignOut)),
                      const SizedBox(width: 12),
                      AccountMenuButton(
                        profileImageUrl: profileImageUrl,
                        onSignOut: onSignOut,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        const SizedBox(height: 6),
                        const CustomizePlanCard(),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
                          decoration: BoxDecoration(
                            color: sectionColor,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Recommended Plans",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 18),
                              PlanCard(
                                title: "Islamic tour",
                                location: "Giza",
                                rating: 4,
                                image: "assets/images/islamic_tour.png",
                                onTap: () {},
                              ),
                              const SizedBox(height: 16),
                              PlanCard(
                                title: "Coastal tour",
                                location: "Alexandria",
                                rating: 3,
                                image: "assets/images/coastal_tour.png",
                                onTap: () {},
                              ),
                              const SizedBox(height: 16),
                              PlanCard(
                                title: "Greek tour",
                                location: "Alexandria",
                                rating: 3,
                                image: "assets/images/greek_tour.png",
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
