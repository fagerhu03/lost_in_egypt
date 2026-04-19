import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../bloc/create_tour_cubit.dart';
import '../bloc/create_tour_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lost_in_egypt/core/di/service_locator.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/map_repository.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';
import '../../domain/entities/tour_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:lost_in_egypt/feature/home/notification/data/datasources/notifications_data_source.dart';
import 'package:lost_in_egypt/feature/home/notification/data/models/notification_model.dart';

class CreateTourScreen extends StatefulWidget {
  final TourEntity? tourToEdit;

  const CreateTourScreen({super.key, this.tourToEdit});

  @override
  State<CreateTourScreen> createState() => _CreateTourScreenState();
}

class _CreateTourScreenState extends State<CreateTourScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _destInputController = TextEditingController();
  List<String> _destinations = [];
  final _priceController = TextEditingController();
  final _maxAttendeesController = TextEditingController(text: "10");

  double? _selectedLat;
  double? _selectedLng;
  String? _selectedLocationName;
  String? _selectedAddress;
  TextEditingController? _destController;

  // Recurrence fields
  String _recurrenceType = 'one_time'; // 'one_time' | 'daily' | 'weekly' | 'custom'
  DateTime? _selectedMeetingTime; // Used for one_time
  TimeOfDay? _selectedTimeOfDay;  // Used for all recurrence types
  int? _selectedWeeklyDay;        // Single day for 'weekly' (0=Mon...6=Sun)
  final List<int> _customDays = []; // Multi-day for 'custom' (0=Mon...6=Sun)

  final List<String> _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final List<File> _selectedImages = [];
  List<String> _existingImages = [];
  final ImagePicker _picker = ImagePicker();

  List<MapItem> _availablePlaces = [];
  bool _isLoadingPlaces = true;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
    if (widget.tourToEdit != null) {
      final t = widget.tourToEdit!;
      _titleController.text = t.title;
      _descController.text = t.description;
      _priceController.text = t.price.toString();
      _maxAttendeesController.text = t.maxAttendees.toString();
      _destinations = List.from(t.destinations);
      _selectedLocationName = t.meetingLocationName;
      _selectedLat = t.meetingLatitude;
      _selectedLng = t.meetingLongitude;
      _existingImages = List.from(t.images);
      _recurrenceType = t.recurrenceType;

      if (t.recurrenceType == 'one_time') {
        _selectedMeetingTime = t.meetingTime;
      }

      // Restore time of day
      if (t.meetingTimeOfDay.isNotEmpty) {
        final parts = t.meetingTimeOfDay.split(':');
        if (parts.length == 2) {
          _selectedTimeOfDay = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 9,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      } else {
        // Fall back to meetingTime's time
        _selectedTimeOfDay = TimeOfDay(
          hour: t.meetingTime.hour,
          minute: t.meetingTime.minute,
        );
      }

      if (t.recurrenceType == 'weekly' && t.recurrenceDays.isNotEmpty) {
        _selectedWeeklyDay = t.recurrenceDays.first;
      }
      if (t.recurrenceType == 'custom') {
        _customDays.addAll(t.recurrenceDays);
      }
    }
  }

  Future<void> _loadPlaces() async {
    try {
      final repo = sl<MapRepository>();
      final places = await repo.fetchAllMapItemsLimited();
      if (mounted) {
        setState(() {
          _availablePlaces = places;
          _isLoadingPlaces = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPlaces = false);
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _pickDateAndTime() async {
    // For one_time: pick full date + time
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _selectedMeetingTime = DateTime(
            date.year, date.month, date.day, time.hour, time.minute,
          );
          _selectedTimeOfDay = time;
        });
      }
    }
  }

  Future<void> _pickTimeOnly() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTimeOfDay ?? TimeOfDay.now(),
    );
    if (time != null && mounted) {
      setState(() => _selectedTimeOfDay = time);
    }
  }

  /// Computes the next occurrence DateTime given the recurrence pattern and a time of day.
  DateTime _computeNextOccurrence(TimeOfDay tod) {
    final now = DateTime.now();
    if (_recurrenceType == 'one_time' && _selectedMeetingTime != null) {
      return _selectedMeetingTime!;
    }

    if (_recurrenceType == 'daily') {
      var candidate = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
      if (!candidate.isAfter(now)) candidate = candidate.add(const Duration(days: 1));
      return candidate;
    }

    if (_recurrenceType == 'weekly' && _selectedWeeklyDay != null) {
      return _nextOccurrenceForDays([_selectedWeeklyDay!], tod, now);
    }

    if (_recurrenceType == 'custom' && _customDays.isNotEmpty) {
      return _nextOccurrenceForDays(_customDays, tod, now);
    }

    // Fallback: tomorrow at the given time
    return DateTime(now.year, now.month, now.day, tod.hour, tod.minute)
        .add(const Duration(days: 1));
  }

  DateTime _nextOccurrenceForDays(List<int> days, TimeOfDay tod, DateTime now) {
    // days are 0=Mon...6=Sun; DateTime.weekday: 1=Mon...7=Sun
    final sorted = List<int>.from(days)..sort();
    final nowJsDay = now.weekday - 1; // 0=Mon...6=Sun
    for (final d in sorted) {
      int daysUntil = (d - nowJsDay + 7) % 7;
      final candidate = DateTime(now.year, now.month, now.day, tod.hour, tod.minute)
          .add(Duration(days: daysUntil));
      if (candidate.isAfter(now)) return candidate;
    }
    // All days this week have passed — next week's first
    final firstDay = sorted.first;
    int daysUntil = (firstDay - nowJsDay + 7) % 7;
    if (daysUntil == 0) daysUntil = 7;
    return DateTime(now.year, now.month, now.day, tod.hour, tod.minute)
        .add(Duration(days: daysUntil));
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _buildFrequencyString() {
    switch (_recurrenceType) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        if (_selectedWeeklyDay != null) {
          return 'Weekly · ${_weekdayLabels[_selectedWeeklyDay!]}';
        }
        return 'Weekly';
      case 'custom':
        if (_customDays.isNotEmpty) {
          final sorted = List<int>.from(_customDays)..sort();
          return sorted.map((d) => _weekdayLabels[d]).join(', ');
        }
        return 'Custom';
      default:
        return 'One-Time';
    }
  }

  Future<void> _notifyAttendeesOfUpdate(String tourId, String tourTitle) async {
    try {
      final guide = FirebaseAuth.instance.currentUser;
      if (guide == null) return;

      String guideName = 'Your guide';
      String guideImage = guide.photoURL ?? '';
      final guideDoc = await FirebaseFirestore.instance
          .collection('users').doc(guide.uid).get();
      if (guideDoc.exists) {
        final d = guideDoc.data()!;
        final full = '${d['firstName'] ?? ''} ${d['lastName'] ?? ''}'.trim();
        guideName = full.isNotEmpty ? full : (d['username'] ?? guideName);
        guideImage = d['profileImageUrl'] ?? guideImage;
      }

      final bookingsSnap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('tourId', isEqualTo: tourId)
          .where('status', isEqualTo: 'confirmed')
          .get();

      final notifDs = NotificationsDataSourceImpl();
      final seen = <String>{};
      for (final doc in bookingsSnap.docs) {
        final userId = doc.data()['userId'] as String? ?? '';
        if (userId.isEmpty || userId == guide.uid || seen.contains(userId)) continue;
        seen.add(userId);
        await notifDs.sendNotification(NotificationModel(
          id: const Uuid().v4(),
          recipientId: userId,
          senderId: guide.uid,
          senderName: guideName,
          senderAvatar: guideImage,
          title: 'Tour Updated',
          message: 'updated the details for "$tourTitle"',
          type: 'tour_updated',
          deepLinkTargetId: tourId,
          isRead: false,
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      debugPrint('Failed to notify attendees of tour update: $e');
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Validate recurrence-specific inputs
    if (_recurrenceType == 'one_time' && _selectedMeetingTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a meeting date and time.')),
      );
      return;
    }
    if (_recurrenceType != 'one_time' && _selectedTimeOfDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a meeting time.')),
      );
      return;
    }
    if (_recurrenceType == 'weekly' && _selectedWeeklyDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the day of the week.')),
      );
      return;
    }
    if (_recurrenceType == 'custom' && _customDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day.')),
      );
      return;
    }
    if (_selectedImages.isEmpty && _existingImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image.')),
      );
      return;
    }
    if (_selectedLat == null || _selectedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a meeting location on the map.')),
      );
      return;
    }
    if (_destinations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one destination.')),
      );
      return;
    }

    final price = double.tryParse(_priceController.text) ?? 0.0;
    if (price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price cannot be negative.')),
      );
      return;
    }

    final attendees = int.tryParse(_maxAttendeesController.text) ?? 10;
    if (attendees <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total capacity must be greater than zero.')),
      );
      return;
    }

    // Determine meeting time anchor and next occurrence
    final tod = _recurrenceType == 'one_time'
        ? TimeOfDay(
            hour: _selectedMeetingTime!.hour,
            minute: _selectedMeetingTime!.minute,
          )
        : _selectedTimeOfDay!;

    final nextOccurrence = _computeNextOccurrence(tod);

    // meetingTime anchor: for recurring, use next occurrence date as anchor
    final meetingTime = _recurrenceType == 'one_time'
        ? _selectedMeetingTime!
        : nextOccurrence;

    final recurrenceDays = _recurrenceType == 'weekly'
        ? [_selectedWeeklyDay!]
        : _recurrenceType == 'custom'
            ? List<int>.from(_customDays)
            : <int>[];

    final freqString = _buildFrequencyString();
    final meetingTimeOfDay = _formatTimeOfDay(tod);

    if (widget.tourToEdit != null) {
      context.read<CreateTourCubit>().updateTour(
        tourId: widget.tourToEdit!.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        destinations: _destinations,
        price: price,
        meetingLatitude: _selectedLat!,
        meetingLongitude: _selectedLng!,
        meetingTime: meetingTime,
        frequency: freqString,
        meetingLocationName: _selectedLocationName ?? "Meeting Location",
        imageFiles: _selectedImages,
        oldImages: _existingImages,
        maxAttendees: attendees,
        recurrenceType: _recurrenceType,
        recurrenceDays: recurrenceDays,
        meetingTimeOfDay: meetingTimeOfDay,
        nextOccurrence: nextOccurrence,
        totalCapacity: widget.tourToEdit!.totalCapacity > 0
            ? widget.tourToEdit!.totalCapacity
            : attendees,
      );
    } else {
      context.read<CreateTourCubit>().submitTour(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        destinations: _destinations,
        price: price,
        meetingLatitude: _selectedLat!,
        meetingLongitude: _selectedLng!,
        meetingTime: meetingTime,
        frequency: freqString,
        meetingLocationName: _selectedLocationName ?? "Meeting Location",
        imageFiles: _selectedImages,
        maxAttendees: attendees,
        recurrenceType: _recurrenceType,
        recurrenceDays: recurrenceDays,
        meetingTimeOfDay: meetingTimeOfDay,
        nextOccurrence: nextOccurrence,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: Text(widget.tourToEdit != null ? 'Edit Tour' : 'Create New Tour')),
      body: BlocConsumer<CreateTourCubit, CreateTourState>(
        listener: (context, state) {
          if (state is CreateTourError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is CreateTourSuccess) {
            final isEdit = widget.tourToEdit != null;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isEdit ? 'Tour updated!' : 'Tour created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            if (isEdit) {
              _notifyAttendeesOfUpdate(widget.tourToEdit!.id, widget.tourToEdit!.title);
            }
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          if (state is CreateTourLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Tour Title', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    maxLines: 3,
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Destinations (Max 5)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_destinations.isNotEmpty)
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _destinations.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = _destinations.removeAt(oldIndex);
                          _destinations.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        return Card(
                          key: ValueKey(_destinations[index]),
                          color: Theme.of(context).colorScheme.surface,
                          elevation: 0,
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: borderColor),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            title: Text(_destinations[index], style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
                            leading: CircleAvatar(
                              radius: 12,
                              backgroundColor: const Color(0xFFC79A00),
                              child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () {
                                setState(() {
                                  _destinations.removeAt(index);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  if (_destinations.length < 5)
                    _isLoadingPlaces
                        ? const Center(child: CircularProgressIndicator())
                        : Row(
                            children: [
                              Expanded(
                                child: Autocomplete<MapItem>(
                                  optionsViewBuilder: (context, onSelected, options) {
                                    final isDark = Theme.of(context).brightness == Brightness.dark;
                                    final textColor = isDark ? Colors.white : Colors.black;
                                    return Align(
                                      alignment: Alignment.topLeft,
                                      child: Material(
                                        elevation: 4,
                                        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                        ),
                                        child: SizedBox(
                                          height: 200,
                                          width: MediaQuery.of(context).size.width - 80,
                                          child: ListView.builder(
                                            padding: EdgeInsets.zero,
                                            itemCount: options.length,
                                            itemBuilder: (BuildContext context, int index) {
                                              final MapItem option = options.elementAt(index);
                                              return InkWell(
                                                onTap: () => onSelected(option),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(16.0),
                                                  child: Text(option.title, style: TextStyle(color: textColor)),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  optionsBuilder: (TextEditingValue textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return const Iterable<MapItem>.empty();
                                    }
                                    return _availablePlaces.where((MapItem option) {
                                      return option.title.toLowerCase().contains(textEditingValue.text.toLowerCase());
                                    });
                                  },
                                  displayStringForOption: (MapItem option) => option.title,
                                  onSelected: (MapItem selection) {
                                    if (!_destinations.contains(selection.title)) {
                                      setState(() {
                                        _destinations.add(selection.title);
                                      });
                                    }
                                    Future.delayed(const Duration(milliseconds: 50), () {
                                      _destController?.clear();
                                    });
                                  },
                                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                                    _destController = controller;
                                    return TextFormField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      onEditingComplete: onEditingComplete,
                                      decoration: const InputDecoration(
                                        hintText: 'Search destination...',
                                        border: OutlineInputBorder(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.map_outlined),
                                color: const Color(0xFFC79A00),
                                onPressed: () async {
                                  final result = await Navigator.pushNamed(context, '/map_picker');
                                  if (result != null && result is Map<String, dynamic>) {
                                    final title = result['name'] ?? result['address'] ?? 'Unknown Location';
                                    if (!_destinations.contains(title)) {
                                      setState(() {
                                        _destinations.add(title);
                                      });
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(labelText: 'Price (EGP)', prefixText: 'EGP ', border: OutlineInputBorder()),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _maxAttendeesController,
                          decoration: const InputDecoration(labelText: 'Total Capacity', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_selectedLat != null && _selectedLng != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Meeting Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (_selectedLocationName != null && _selectedLocationName!.isNotEmpty) ...[
                          Text(
                            _selectedLocationName!,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (_selectedAddress != null && _selectedAddress!.isNotEmpty) ...[
                          Text(
                            _selectedAddress!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          '${_selectedLat!.toStringAsFixed(6)}, ${_selectedLng!.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 160,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Stack(
                            children: [
                              GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(_selectedLat!, _selectedLng!),
                                  zoom: 14,
                                ),
                                markers: {
                                  Marker(
                                    markerId: const MarkerId('meeting_point'),
                                    position: LatLng(_selectedLat!, _selectedLng!),
                                  ),
                                },
                                liteModeEnabled: Platform.isAndroid,
                                zoomControlsEnabled: false,
                                mapToolbarEnabled: false,
                                myLocationButtonEnabled: false,
                              ),
                              Positioned(
                                top: 8, right: 8,
                                child: FloatingActionButton.small(
                                  heroTag: 'edit_map',
                                  onPressed: () async {
                                    final result = await Navigator.pushNamed(context, '/map_picker');
                                    if (result != null && result is Map<String, dynamic>) {
                                      setState(() {
                                        _selectedLat = result['lat'];
                                        _selectedLng = result['lng'];
                                        _selectedLocationName = result['name'];
                                        _selectedAddress = result['address'];
                                      });
                                    }
                                  },
                                  child: const Icon(Icons.edit),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    ListTile(
                      title: const Text('Select Meeting Location'),
                      trailing: const Icon(Icons.map, color: Color(0xFFC79A00)),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: isDark ? Colors.grey.shade600 : Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () async {
                        final result = await Navigator.pushNamed(context, '/map_picker');
                        if (result != null && result is Map<String, dynamic>) {
                          setState(() {
                            _selectedLat = result['lat'];
                            _selectedLng = result['lng'];
                            _selectedLocationName = result['name'];
                            _selectedAddress = result['address'];
                          });
                        }
                      },
                    ),
                  const SizedBox(height: 16),

                  // ── Recurrence Type Selector ──────────────────────────────
                  const Text('Schedule Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _RecurrenceChip(
                        label: 'One-Time',
                        icon: Icons.event,
                        value: 'one_time',
                        selected: _recurrenceType == 'one_time',
                        onTap: () => setState(() => _recurrenceType = 'one_time'),
                        primary: primary,
                        textColor: textColor,
                        isDark: isDark,
                      ),
                      _RecurrenceChip(
                        label: 'Daily',
                        icon: Icons.repeat,
                        value: 'daily',
                        selected: _recurrenceType == 'daily',
                        onTap: () => setState(() => _recurrenceType = 'daily'),
                        primary: primary,
                        textColor: textColor,
                        isDark: isDark,
                      ),
                      _RecurrenceChip(
                        label: 'Weekly',
                        icon: Icons.date_range,
                        value: 'weekly',
                        selected: _recurrenceType == 'weekly',
                        onTap: () => setState(() => _recurrenceType = 'weekly'),
                        primary: primary,
                        textColor: textColor,
                        isDark: isDark,
                      ),
                      _RecurrenceChip(
                        label: 'Custom Days',
                        icon: Icons.tune,
                        value: 'custom',
                        selected: _recurrenceType == 'custom',
                        onTap: () => setState(() => _recurrenceType = 'custom'),
                        primary: primary,
                        textColor: textColor,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Recurrence-specific UI ────────────────────────────────
                  if (_recurrenceType == 'one_time') ...[
                    ListTile(
                      title: Text(_selectedMeetingTime == null
                          ? 'Select Meeting Date & Time'
                          : 'Meeting Time: ${DateFormat('yyyy-MM-dd HH:mm').format(_selectedMeetingTime!)}'),
                      trailing: const Icon(Icons.calendar_today),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: isDark ? Colors.grey.shade600 : Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onTap: _pickDateAndTime,
                    ),
                  ],

                  if (_recurrenceType == 'daily') ...[
                    ListTile(
                      title: Text(_selectedTimeOfDay == null
                          ? 'Select Meeting Time'
                          : 'Runs daily at ${_selectedTimeOfDay!.format(context)}'),
                      trailing: const Icon(Icons.access_time),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: isDark ? Colors.grey.shade600 : Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onTap: _pickTimeOnly,
                    ),
                  ],

                  if (_recurrenceType == 'weekly') ...[
                    const Text('Day of the Week', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: List.generate(_weekdayLabels.length, (i) {
                        final isSelected = _selectedWeeklyDay == i;
                        return ChoiceChip(
                          label: Text(
                            _weekdayLabels[i],
                            style: TextStyle(color: isSelected ? Colors.black : textColor),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFFC79A00),
                          backgroundColor: isDark ? Colors.grey.shade800 : null,
                          onSelected: (selected) {
                            setState(() => _selectedWeeklyDay = selected ? i : null);
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: Text(_selectedTimeOfDay == null
                          ? 'Select Meeting Time'
                          : 'Time: ${_selectedTimeOfDay!.format(context)}'),
                      trailing: const Icon(Icons.access_time),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: isDark ? Colors.grey.shade600 : Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onTap: _pickTimeOnly,
                    ),
                  ],

                  if (_recurrenceType == 'custom') ...[
                    const Text('Select Days', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: List.generate(_weekdayLabels.length, (i) {
                        final isSelected = _customDays.contains(i);
                        return ChoiceChip(
                          label: Text(
                            _weekdayLabels[i],
                            style: TextStyle(color: isSelected ? Colors.black : textColor),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFFC79A00),
                          backgroundColor: isDark ? Colors.grey.shade800 : null,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _customDays.add(i);
                              } else {
                                _customDays.remove(i);
                              }
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: Text(_selectedTimeOfDay == null
                          ? 'Select Meeting Time'
                          : 'Time: ${_selectedTimeOfDay!.format(context)}'),
                      trailing: const Icon(Icons.access_time),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: isDark ? Colors.grey.shade600 : Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onTap: _pickTimeOnly,
                    ),
                  ],

                  const SizedBox(height: 24),
                  Text(widget.tourToEdit != null ? 'Edit Tour Images' : 'Tour Images', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor, fontFamily: "Marcellus")),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._existingImages.map((url) => Stack(
                            children: [
                              CachedNetworkImage(
                                imageUrl: url,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 80, height: 80,
                                  color: Colors.grey.withOpacity(0.2),
                                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 80, height: 80,
                                  color: Colors.grey.withOpacity(0.2),
                                  child: const Icon(Icons.error, size: 20),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _existingImages.remove(url);
                                    });
                                  },
                                  child: Container(
                                    color: Colors.black54,
                                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          )),
                      ..._selectedImages.map((file) => Stack(
                            children: [
                              Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedImages.remove(file);
                                    });
                                  },
                                  child: Container(
                                    color: Colors.black54,
                                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          )),
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 80,
                          height: 80,
                          color: isDark ? Colors.white10 : Colors.grey.withAlpha(50),
                          child: Icon(Icons.add_a_photo, color: isDark ? Colors.white54 : Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFFC79A00),
                    ),
                    child: Text(widget.tourToEdit != null ? 'Save Changes' : 'Create Tour', style: const TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Small helper widget for recurrence type chip
class _RecurrenceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  final Color primary;
  final Color textColor;
  final bool isDark;

  const _RecurrenceChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
    required this.primary,
    required this.textColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFC79A00)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFC79A00) : Colors.grey.shade400,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.black : textColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.black : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
