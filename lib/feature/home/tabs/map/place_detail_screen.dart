import 'package:flutter/material.dart';
import '../home/data/models/map_item_models.dart';

class PlaceDetailSheet extends StatefulWidget {
  final MapItem place;
  final VoidCallback onClose;
  final VoidCallback onShowOnMap;
  final VoidCallback onDirections; // ← NEW

  const PlaceDetailSheet({
    super.key,
    required this.place,
    required this.onClose,
    required this.onShowOnMap,
    required this.onDirections, // ← NEW
  });

  @override
  State<PlaceDetailSheet> createState() => _PlaceDetailSheetState();
}

class _PlaceDetailSheetState extends State<PlaceDetailSheet> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final sheetShadow = isDark
        ? BoxShadow(
            color: Colors.white.withOpacity(0.18),
            blurRadius: 26,
            spreadRadius: 2,
            offset: const Offset(0, -10),
          )
        : BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 26,
            spreadRadius: 2,
            offset: const Offset(0, -10),
          );

    final borderColor = (isDark ? Colors.white : Colors.black)
        .withOpacity(isDark ? 0.10 : 0.06);

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.55,
      minChildSize: 0.2,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.2, 0.55, 0.95],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: borderColor),
            boxShadow: [sheetShadow],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: onSurface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),

              // Image
              Stack(
                children: [
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: Image.network(
                      widget.place.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: onSurface.withOpacity(0.06),
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            color: onSurface.withOpacity(0.35),
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                            colors: [
                              Colors.black.withOpacity(0.25),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.55),
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.close,
                            size: 20, color: Colors.white),
                        onPressed: widget.onClose,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.place.title,
                      style: TextStyle(
                        fontFamily: "Marcellus",
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Category + rating
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                primary.withOpacity(isDark ? 0.18 : 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: primary.withOpacity(0.25),
                            ),
                          ),
                          child: Text(
                            widget.place.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.star,
                            size: 16, color: Colors.amber),
                        Text(
                          " ${widget.place.rating}",
                          style: TextStyle(
                            color: onSurface.withOpacity(0.65),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(
                          icon: Icons.map_outlined,
                          label: "Show on Map",
                          isPrimary: true,
                          primary: primary,
                          onSurface: onSurface,
                          isDark: isDark,
                          onTap: () {
                            _sheetController.animateTo(
                              0.2,
                              duration:
                                  const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                            widget.onShowOnMap();
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.directions,
                          label: "Directions",
                          isPrimary: false,
                          primary: primary,
                          onSurface: onSurface,
                          isDark: isDark,
                          onTap: widget.onDirections, // ← UPDATED
                        ),
                        _buildActionButton(
                          icon: Icons.share,
                          label: "Share",
                          isPrimary: false,
                          primary: primary,
                          onSurface: onSurface,
                          isDark: isDark,
                          onTap: () {},
                        ),
                        _buildActionButton(
                          icon: Icons.bookmark_border,
                          label: "Save",
                          isPrimary: false,
                          primary: primary,
                          onSurface: onSurface,
                          isDark: isDark,
                          onTap: () {},
                        ),
                      ],
                    ),

                    Divider(
                      height: 40,
                      thickness: 1,
                      color: onSurface.withOpacity(0.10),
                    ),

                    // About
                    Text(
                      "About",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.place.description.isNotEmpty
                          ? widget.place.description
                          : "Explore the ancient wonders and hidden gems of Egypt. "
                              "This location offers a unique glimpse into the rich "
                              "history and culture of the region.",
                      style: TextStyle(
                        height: 1.6,
                        color: onSurface.withOpacity(0.85),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info tiles
                    if (widget.place.locationAddress.isNotEmpty)
                      _buildInfoTile(
                        icon: Icons.location_on_outlined,
                        text: widget.place.locationAddress,
                        iconColor: primary,
                        onSurface: onSurface,
                      ),
                    _buildInfoTile(
                      icon: Icons.access_time,
                      text: "Open • Closes 10:00 PM",
                      iconColor: Colors.orange,
                      onSurface: onSurface,
                    ),
                    if (widget.place.price > 0)
                      _buildInfoTile(
                        icon: Icons.confirmation_number_outlined,
                        text:
                            "${widget.place.price.toStringAsFixed(0)} EGP Entry Fee",
                        iconColor: Colors.green,
                        onSurface: onSurface,
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String text,
    required Color iconColor,
    required Color onSurface,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: onSurface.withOpacity(0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
    required Color primary,
    required Color onSurface,
    required bool isDark,
  }) {
    final bg = isPrimary ? primary : Colors.transparent;

    final border = Border.all(
      color: isPrimary
          ? Colors.transparent
          : onSurface.withOpacity(isDark ? 0.18 : 0.20),
    );

    final buttonShadow = isPrimary
        ? [
            BoxShadow(
              color: (isDark ? Colors.white : Colors.black)
                  .withOpacity(0.14),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            )
          ]
        : <BoxShadow>[];

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: isPrimary ? null : border,
              boxShadow: buttonShadow,
            ),
            child: Icon(
              icon,
              color: isPrimary ? Colors.white : primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isPrimary ? primary : onSurface.withOpacity(0.70),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}