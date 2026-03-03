import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../bloc/create_tour_cubit.dart';
import '../bloc/create_tour_state.dart';
import 'package:intl/intl.dart';

class CreateTourScreen extends StatefulWidget {
  const CreateTourScreen({super.key});

  @override
  State<CreateTourScreen> createState() => _CreateTourScreenState();
}

class _CreateTourScreenState extends State<CreateTourScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _destinationsController = TextEditingController();
  final _priceController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _maxAttendeesController = TextEditingController(text: "10");

  DateTime? _selectedMeetingTime;
  String _selectedFrequency = 'One-Time';

  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

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

    final price = double.tryParse(_priceController.text) ?? 0.0;
    final lat = double.tryParse(_latController.text) ?? 0.0;
    final lng = double.tryParse(_lngController.text) ?? 0.0;
    final attendees = int.tryParse(_maxAttendeesController.text) ?? 10;
    final destinations = _destinationsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    context.read<CreateTourCubit>().submitTour(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          destinations: destinations,
          price: price,
          meetingLatitude: lat,
          meetingLongitude: lng,
          meetingTime: _selectedMeetingTime!,
          frequency: _selectedFrequency,
          imageFiles: _selectedImages,
          maxAttendees: attendees,
        );
  }

  @override
  Widget build(BuildContext context) {
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
                  TextFormField(
                    controller: _destinationsController,
                    decoration: const InputDecoration(
                      labelText: 'Destinations (Comma separated)',
                      hintText: 'e.g. Pyramids, Sphinx, Cairo Museum',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
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
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latController,
                          decoration: const InputDecoration(labelText: 'Meeting Lat', border: OutlineInputBorder()),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _lngController,
                          decoration: const InputDecoration(labelText: 'Meeting Lng', border: OutlineInputBorder()),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(_selectedMeetingTime == null
                        ? 'Select Meeting Time'
                        : 'Meeting Time: ${DateFormat('yyyy-MM-dd HH:mm').format(_selectedMeetingTime!)}'),
                    trailing: const Icon(Icons.calendar_today),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onTap: _pickDateTime,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedFrequency,
                    decoration: const InputDecoration(labelText: 'Frequency', border: OutlineInputBorder()),
                    items: ['One-Time', 'Daily', 'Weekly', 'Weekends']
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedFrequency = val);
                    },
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
                          color: Colors.grey.withAlpha(50),
                          child: const Icon(Icons.add_a_photo, color: Colors.grey),
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
