import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lost_in_egypt/core/services/ai_storyteller_service.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/datasources/map_focus_service.dart';

class CameraResultSheet extends StatefulWidget {
  final PlaceModel place;

  const CameraResultSheet({super.key, required this.place});

  static void show(BuildContext context, PlaceModel place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => CameraResultSheet(place: place),
    );
  }

  @override
  State<CameraResultSheet> createState() => _CameraResultSheetState();
}

class _CameraResultSheetState extends State<CameraResultSheet> {
  String? story;
  bool isLoadingStory = false;
  bool isSpeaking = false;
  bool showFullDescription = false;
  final FlutterTts tts = FlutterTts();

  @override
  void dispose() {
    if (isSpeaking) {
      tts.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.zero,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: Image.network(
                  widget.place.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.place.title,
                    style: TextStyle(
                      fontFamily: "Marcellus",
                      fontSize: 26,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Landmark Identified",
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Description with Read More
                  if (story == null) ...[
                    Text(
                      showFullDescription
                          ? widget.place.description
                          : widget.place.description.length > 100
                              ? '${widget.place.description.substring(0, 100)}...'
                              : widget.place.description,
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6)),
                    ),
                    if (widget.place.description.length > 100)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            showFullDescription = !showFullDescription;
                          });
                        },
                        child: Text(
                          showFullDescription ? 'Read Less' : 'Read More',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ] else
                    Container(
                      height: 150,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          story!,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (story == null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoadingStory
                            ? null
                            : () async {
                                setState(() => isLoadingStory = true);
                                final storyResult = await AIStorytellerService
                                    .getLandmarkStory(widget.place.title);
                                setState(() {
                                  story = storyResult;
                                  isLoadingStory = false;
                                });
                              },
                        icon: isLoadingStory
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimary,
                                ),
                              )
                            : Icon(
                                Icons.auto_awesome,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                        label: Text(
                          isLoadingStory
                              ? "Consulting history..."
                              : "Tell me a story",
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (isSpeaking) {
                                await tts.stop();
                                setState(() => isSpeaking = false);
                              } else {
                                setState(() => isSpeaking = true);
                                await tts.speak(story!);
                                tts.setCompletionHandler(() {
                                  if (mounted) {
                                    setState(() => isSpeaking = false);
                                  }
                                });
                              }
                            },
                            icon: Icon(
                              isSpeaking ? Icons.stop : Icons.play_arrow,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            label: Text(
                              isSpeaking ? "Stop" : "Listen to Story",
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            MapFocusService.instance.tabSwitchNotifier.value =
                                2;
                            MapFocusService.instance.triggerFocus(widget.place);
                          },
                          icon: Icon(
                            Icons.map_outlined,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          label: Text(
                            "Show on Map",
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "Done",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
