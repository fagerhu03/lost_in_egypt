import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../bloc/create_tour_cubit.dart';
import '../bloc/create_tour_state.dart';
import 'package:intl/intl.dart';
import 'package:lost_in_egypt/core/widgets/shimmer_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lost_in_egypt/core/di/service_locator.dart';
import 'package:lost_in_egypt/core/utils/map_style_helper.dart';
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

  DateTime? _selectedMeetingTime;
  final List<String> _selectedWeekdays = [];
  final List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final List<File> _selectedImages = [];
  List<String> _existingImages = [];
  final ImagePicker _picker = ImagePicker();

  List<MapItem> _availablePlaces = [];
  bool _isLoadingPlaces = true;
  GoogleMapController? _previewMapController;
  String? _mapStyle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MapStyleHelper.getStyle(context).then((style) {
      if (mounted) setState(() => _mapStyle = style);
    });
  }

  @override
  void dispose() {
    _previewMapController?.dispose();
    _titleController.dispose();
    _descController.dispose();
    _destInputController.dispose();
    _priceController.dispose();
    _maxAttendeesController.dispose();
    super.dispose();
  }

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
      _selectedMeetingTime = t.meetingTime;

      if (t.frequency != 'One-Time') {
        _selectedWeekdays.addAll(t.frequency.split(', '));
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

  Future<void> _pickDateTime() async {
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
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
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
    if (_selectedMeetingTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a meeting time.')),
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
        const SnackBar(content: Text('Max attendees must be greater than zero.')),
      );
      return;
    }

    final freqString = _selectedWeekdays.isEmpty ? 'One-Time' : _selectedWeekdays.join(', ');

    if (widget.tourToEdit != null) {
      context.read<CreateTourCubit>().updateTour(
        tourId: widget.tourToEdit!.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        destinations: _destinations,
        price: price,
        meetingLatitude: _selectedLat!,
        meetingLongitude: _selectedLng!,
        meetingTime: _selectedMeetingTime!,
        frequency: freqString,
        meetingLocationName: _selectedLocationName ?? "Meeting Location",
        imageFiles: _selectedImages,
        oldImages: _existingImages,
        maxAttendees: attendees,
      );
    } else {
      context.read<CreateTourCubit>().submitTour(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        destinations: _destinations,
        price: price,
        meetingLatitude: _selectedLat!,
        meetingLongitude: _selectedLng!,
        meetingTime: _selectedMeetingTime!,
        frequency: freqString,
        meetingLocationName: _selectedLocationName ?? "Meeting Location",
        imageFiles: _selectedImages,
        maxAttendees: attendees,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

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
            padding: EdgeInsets.all(16.r),
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
                  SizedBox(height: 16.h),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    maxLines: 3,
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: 16.h),
                  Text('Destinations (Max 5)', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8.h),
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
                          margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            side: BorderSide(color: borderColor),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                            title: Text(_destinations[index], style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
                            leading: CircleAvatar(
                              radius: 12.r,
                              backgroundColor: const Color(0xFFC79A00),
                              child: Text('${index + 1}', style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
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
                                          borderRadius: BorderRadius.circular(8.r),
                                          side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                        ),
                                        child: SizedBox(
                                          height: 200.h,
                                          width: MediaQuery.of(context).size.width - 80.w,
                                          child: ListView.builder(
                                            padding: EdgeInsets.zero,
                                            itemCount: options.length,
                                            itemBuilder: (BuildContext context, int index) {
                                              final MapItem option = options.elementAt(index);
                                              return InkWell(
                                                onTap: () => onSelected(option),
                                                child: Padding(
                                                  padding: EdgeInsets.all(16.r),
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
                              SizedBox(width: 8.w),
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
                  SizedBox(height: 16.h),
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
                      SizedBox(width: 16.w),
                      Expanded(
                        child: TextFormField(
                          controller: _maxAttendeesController,
                          decoration: const InputDecoration(labelText: 'Max Attendees', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  if (_selectedLat != null && _selectedLng != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Meeting Location', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8.h),
                        if (_selectedLocationName != null && _selectedLocationName!.isNotEmpty) ...[
                          Text(
                            _selectedLocationName!,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4.h),
                        ],
                        if (_selectedAddress != null && _selectedAddress!.isNotEmpty) ...[
                          Text(
                            _selectedAddress!,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 4.h),
                        ],
                        Text(
                          '${_selectedLat!.toStringAsFixed(6)}, ${_selectedLng!.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Container(
                          height: 160.h,
                          margin: EdgeInsets.only(bottom: 16.h),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
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
                                zoomControlsEnabled: false,
                                mapToolbarEnabled: false,
                                myLocationButtonEnabled: false,
                                style: _mapStyle,
                                onMapCreated: (controller) {
                                  _previewMapController = controller;
                                },
                              ),
                              Positioned(
                                top: 8.h, right: 8.w,
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
                        borderRadius: BorderRadius.circular(12.r),
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
                  SizedBox(height: 16.h),
                  ListTile(
                    title: Text(_selectedMeetingTime == null
                        ? 'Select Meeting Time'
                        : 'Meeting Time: ${DateFormat('yyyy-MM-dd HH:mm').format(_selectedMeetingTime!)}'),
                    trailing: const Icon(Icons.calendar_today),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: isDark ? Colors.grey.shade600 : Colors.grey),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    onTap: _pickDateTime,
                  ),
                  SizedBox(height: 16.h),
                  Text('Schedule Frequency (Days)', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 4.h,
                    children: _weekdays.map((day) {
                      final isSelected = _selectedWeekdays.contains(day);
                      return ChoiceChip(
                        label: Text(
                          day,
                          style: TextStyle(
                            color: isSelected ? Colors.black : textColor,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFFC79A00),
                        backgroundColor: isDark ? Colors.grey.shade800 : null,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedWeekdays.add(day);
                            } else {
                              _selectedWeekdays.remove(day);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 24.h),
                  Text(widget.tourToEdit != null ? 'Edit Tour Images' : 'Tour Images', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: textColor, fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'])),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      ..._existingImages.map((url) => Stack(
                            children: [
                              ShimmerImage(
                                url: url,
                                width: 80.r,
                                height: 80.r,
                                fit: BoxFit.cover,
                                fallbackIcon: Icons.error,
                                fallbackBackgroundColor: Colors.grey.withValues(alpha: 0.2),
                                fallbackIconSize: 20.r,
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
                                    child: Icon(Icons.close, color: Colors.white, size: 18.r),
                                  ),
                                ),
                              ),
                            ],
                          )),
                      ..._selectedImages.map((file) => Stack(
                            children: [
                              Image.file(file, width: 80.r, height: 80.r, fit: BoxFit.cover),
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
                                    child: Icon(Icons.close, color: Colors.white, size: 18.r),
                                  ),
                                ),
                              ),
                            ],
                          )),
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 80.r,
                          height: 80.r,
                          color: isDark ? Colors.white10 : Colors.grey.withAlpha(50),
                          child: Icon(Icons.add_a_photo, color: isDark ? Colors.white54 : Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      backgroundColor: const Color(0xFFC79A00),
                    ),
                    child: Text(widget.tourToEdit != null ? 'Save Changes' : 'Create Tour', style: TextStyle(fontSize: 18.sp, color: Colors.white)),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
