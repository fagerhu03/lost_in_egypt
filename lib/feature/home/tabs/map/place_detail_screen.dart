import 'package:flutter/material.dart';
import '../home/data/models/map_item_models.dart';

class PlaceDetailSheet extends StatefulWidget {
  final MapItem place;
  final VoidCallback onClose;
  final VoidCallback onShowOnMap;

  const PlaceDetailSheet({
    super.key,
    required this.place,
    required this.onClose,
    required this.onShowOnMap,
  });

  @override
  State<PlaceDetailSheet> createState() => _PlaceDetailSheetState();
}

class _PlaceDetailSheetState extends State<PlaceDetailSheet> {
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.55,
      minChildSize: 0.2,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.2, 0.55, 0.95],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15,
                spreadRadius: 5,
                offset: Offset(0, -5),
              )
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              Stack(
                children: [
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: Image.network(
                      widget.place.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.grey[100],
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Colors.white),
                        onPressed: widget.onClose,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.place.title,
                      style: const TextStyle(
                        fontFamily: "Marcellus",
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A3D2E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9E4BC),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.place.category.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4D5420),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        Text(
                          " ${widget.place.rating}",
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(
                          icon: Icons.map_outlined,
                          label: "Show on Map",
                          isPrimary: true,
                          onTap: () {
                            _sheetController.animateTo(
                              0.2,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                            widget.onShowOnMap();
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.directions,
                          label: "Directions",
                          isPrimary: false,
                          onTap: () {},
                        ),
                        _buildActionButton(
                          icon: Icons.share,
                          label: "Share",
                          isPrimary: false,
                          onTap: () {},
                        ),
                        _buildActionButton(
                          icon: Icons.bookmark_border,
                          label: "Save",
                          isPrimary: false,
                          onTap: () {},
                        ),
                      ],
                    ),
                    const Divider(height: 40, thickness: 1),
                    const Text(
                      "About",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A3D2E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.place.description.isNotEmpty
                          ? widget.place.description
                          : "Explore the ancient wonders and hidden gems of Egypt. This location offers a unique glimpse into the rich history and culture of the region.",
                      style: const TextStyle(
                        height: 1.6,
                        color: Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (widget.place.locationAddress.isNotEmpty)
                      _buildInfoTile(
                        Icons.location_on_outlined,
                        widget.place.locationAddress,
                        Colors.blue,
                      ),
                    _buildInfoTile(
                      Icons.access_time,
                      "Open • Closes 10:00 PM",
                      Colors.orange,
                    ),
                    if (widget.place.price > 0)
                      _buildInfoTile(
                        Icons.confirmation_number_outlined,
                        "${widget.place.price.toStringAsFixed(0)} EGP Entry Fee",
                        Colors.green,
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

  Widget _buildInfoTile(IconData icon, String text, Color iconColor) {
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
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isPrimary ? const Color(0xFF4D5420) : Colors.white,
              shape: BoxShape.circle,
              border: isPrimary ? null : Border.all(color: Colors.grey[300]!),
              boxShadow: [
                if (isPrimary)
                  const BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
              ],
            ),
            child: Icon(
              icon,
              color: isPrimary ? Colors.white : const Color(0xFF4D5420),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isPrimary ? const Color(0xFF4D5420) : Colors.grey[700],
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}