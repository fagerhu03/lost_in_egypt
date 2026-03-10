import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../bloc/create_tour_cubit.dart';
import '../bloc/create_tour_state.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lost_in_egypt/core/di/service_locator.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/map_repository.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';

class CreateTourScreen extends StatefulWidget {
  const CreateTourScreen({super.key});

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
  final ImagePicker _picker = ImagePicker();

  List<MapItem> _availablePlaces = [];
  bool _isLoadingPlaces = true;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMeetingTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a meeting time.')),
      );
      return;
    }
    if (_selectedImages.isEmpty) {
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
    final attendees = int.tryParse(_maxAttendeesController.text) ?? 10;
    final freqString = _selectedWeekdays.isEmpty ? 'One-Time' : _selectedWeekdays.join(', ');

    context.read<CreateTourCubit>().submitTour(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          destinations: _destinations,
          price: price,
          meetingLatitude: _selectedLat!,
          meetingLongitude: _selectedLng!,
          meetingTime: _selectedMeetingTime!,
          frequency: freqString,
          imageFiles: _selectedImages,
          maxAttendees: attendees,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return Scaffold(
      appBar: AppBar(title: const Text('Create New Tour')),
      body: BlocConsumer<CreateTourCubit, CreateTourState>(
        listener: (context, state) {
          if (state is CreateTourError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is CreateTourSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tour created successfully!'), backgroundColor: Colors.green),
            );
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
                          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            title: Text(_destinations[index], style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
                            leading: CircleAvatar(
                              radius: 12,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
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
                          decoration: const InputDecoration(labelText: 'Price (USD)', border: OutlineInputBorder()),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
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
                  ListTile(
                    title: Text(_selectedMeetingTime == null
                        ? 'Select Meeting Time'
                        : 'Meeting Time: ${DateFormat('yyyy-MM-dd HH:mm').format(_selectedMeetingTime!)}'),
                    trailing: const Icon(Icons.calendar_today),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: isDark ? Colors.grey.shade600 : Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onTap: _pickDateTime,
                  ),
                  const SizedBox(height: 16),
                  const Text('Schedule Frequency (Days)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
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
                  const SizedBox(height: 24),
                  const Text('Tour Images', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
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
                    child: const Text('Create Tour', style: TextStyle(fontSize: 18, color: Colors.white)),
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
