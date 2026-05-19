import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:lost_in_egypt/core/constants/event_categories.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';

/// Editor screen for creating/editing an event in Firestore.
/// Used by admins to manually curate live events.
class AdminEventEditorScreen extends StatefulWidget {
  final EventModel? event;
  final String? docId;

  const AdminEventEditorScreen({super.key, this.event, this.docId});

  bool get isEditing => event != null && docId != null;

  @override
  State<AdminEventEditorScreen> createState() => _AdminEventEditorScreenState();
}

class _AdminEventEditorScreenState extends State<AdminEventEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _venueCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _imageUrlCtrl;
  late final TextEditingController _ticketLinkCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  late final TextEditingController _recurrenceCtrl;
  late final TextEditingController _ratingCtrl;
  late final TextEditingController _importanceCtrl;
  late final TextEditingController _tagsCtrl;

  String _selectedCategory = 'cultural';
  String _selectedCity = 'Cairo';
  bool _isRecurring = false;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _venueCtrl = TextEditingController(text: e?.venueName ?? '');
    _addressCtrl = TextEditingController(text: e?.locationAddress ?? '');
    _imageUrlCtrl = TextEditingController(text: e?.imagePath ?? '');
    _ticketLinkCtrl = TextEditingController(text: e?.ticketLink ?? '');
    _priceCtrl = TextEditingController(text: (e?.price ?? 0).toStringAsFixed(0));
    _durationCtrl = TextEditingController(text: e?.duration ?? '');
    _latCtrl = TextEditingController(text: (e?.coordinate.latitude ?? 30.0444).toString());
    _lngCtrl = TextEditingController(text: (e?.coordinate.longitude ?? 31.2357).toString());
    _recurrenceCtrl = TextEditingController(text: e?.recurrenceText ?? '');
    _ratingCtrl = TextEditingController(text: (e?.rating ?? 4.5).toStringAsFixed(1));
    _importanceCtrl = TextEditingController(text: (e?.importance ?? 5).toString());
    _tagsCtrl = TextEditingController(text: e?.tags.join(', ') ?? '');
    _selectedCategory = e?.eventCategory ?? 'cultural';
    _selectedCity = e?.city ?? 'Cairo';
    _isRecurring = e?.isRecurring ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _venueCtrl.dispose();
    _addressCtrl.dispose();
    _imageUrlCtrl.dispose();
    _ticketLinkCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _recurrenceCtrl.dispose();
    _ratingCtrl.dispose();
    _importanceCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final surface = theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        title: Text(
          widget.isEditing ? 'Edit Event' : 'Create Event',
          style: TextStyle(
            color: onSurface,
            fontFamily: 'Marcellus',
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        foregroundColor: onSurface,
        actions: [
          if (_saving)
            Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Center(
                child: SizedBox(
                  width: 20.r,
                  height: 20.r,
                  child: CircularProgressIndicator(
                    color: primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Save',
              onPressed: _save,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            _sectionLabel('Basic Info', onSurface),
            _textField(_titleCtrl, 'Title *', Icons.title, validator: _required),
            SizedBox(height: 12.h),
            _textField(_venueCtrl, 'Venue Name', Icons.place_outlined),
            SizedBox(height: 12.h),
            _textField(_addressCtrl, 'Address', Icons.location_on_outlined),
            SizedBox(height: 12.h),
            _textField(_descCtrl, 'Description *', Icons.description,
                maxLines: 4, validator: _required),
            SizedBox(height: 20.h),

            _sectionLabel('Category & Location', onSurface),
            // Category dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: _inputDecoration('Category', Icons.category),
              items: EventCategories.assignable.map((cat) {
                return DropdownMenuItem(
                  value: cat.id,
                  child: Text(cat.label),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v ?? 'cultural'),
            ),
            SizedBox(height: 12.h),
            // City dropdown
            DropdownButtonFormField<String>(
              value: _selectedCity,
              decoration: _inputDecoration('City', Icons.location_city),
              items: EventCategories.cities
                  .where((c) => c != 'All Cities')
                  .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCity = v ?? 'Cairo'),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(child: _textField(_latCtrl, 'Latitude', Icons.my_location,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                SizedBox(width: 12.w),
                Expanded(child: _textField(_lngCtrl, 'Longitude', Icons.my_location,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true))),
              ],
            ),
            SizedBox(height: 20.h),

            _sectionLabel('Media & Links', onSurface),
            _textField(_imageUrlCtrl, 'Image URL', Icons.image_outlined),
            SizedBox(height: 12.h),
            _textField(_ticketLinkCtrl, 'Ticket Link', Icons.confirmation_number_outlined),
            SizedBox(height: 20.h),

            _sectionLabel('Details', onSurface),
            Row(
              children: [
                Expanded(child: _textField(_priceCtrl, 'Price (EGP)', Icons.attach_money,
                    keyboardType: TextInputType.number)),
                SizedBox(width: 12.w),
                Expanded(child: _textField(_durationCtrl, 'Duration', Icons.timer_outlined)),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(child: _textField(_ratingCtrl, 'Rating (0-5)', Icons.star_outline,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                SizedBox(width: 12.w),
                Expanded(child: _textField(_importanceCtrl, 'Importance (1-10)', Icons.priority_high,
                    keyboardType: TextInputType.number)),
              ],
            ),
            SizedBox(height: 12.h),
            _textField(_tagsCtrl, 'Tags (comma-separated)', Icons.tag),
            SizedBox(height: 12.h),

            // Recurring toggle
            SwitchListTile(
              title: Text('Recurring Event', style: TextStyle(color: onSurface)),
              subtitle: Text('Happens regularly (nightly, weekly, etc.)',
                  style: TextStyle(color: onSurface.withValues(alpha: 0.5), fontSize: 12.sp)),
              value: _isRecurring,
              activeColor: primary,
              onChanged: (v) => setState(() => _isRecurring = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (_isRecurring) ...[
              SizedBox(height: 8.h),
              _textField(_recurrenceCtrl, 'Recurrence (e.g. "Nightly at 7 PM")',
                  Icons.repeat),
            ],
            SizedBox(height: 32.h),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        widget.isEditing ? 'Update Event' : 'Create Event',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Marcellus',
                        ),
                      ),
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        text,
        style: TextStyle(
          color: color.withValues(alpha: 0.6),
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20.r),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: validator,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, icon),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final data = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'venueName': _venueCtrl.text.trim(),
      'locationAddress': _addressCtrl.text.trim(),
      'imagePath': _imageUrlCtrl.text.trim(),
      'imagePaths': _imageUrlCtrl.text.trim().isNotEmpty
          ? [_imageUrlCtrl.text.trim()]
          : <String>[],
      'ticketLink': _ticketLinkCtrl.text.trim(),
      'price': double.tryParse(_priceCtrl.text) ?? 0,
      'duration': _durationCtrl.text.trim(),
      'rating': double.tryParse(_ratingCtrl.text) ?? 4.5,
      'importance': int.tryParse(_importanceCtrl.text) ?? 5,
      'coordinate': GeoPoint(
        double.tryParse(_latCtrl.text) ?? 30.0444,
        double.tryParse(_lngCtrl.text) ?? 31.2357,
      ),
      'city': _selectedCity,
      'eventCategory': _selectedCategory,
      'isRecurring': _isRecurring,
      'recurrenceText': _isRecurring ? _recurrenceCtrl.text.trim() : '',
      'tags': tags,
      'source': widget.event?.source ?? 'admin',
      'isEvent': true,
      'date': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.isEditing) {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.docId)
            .update(data);
      } else {
        await FirebaseFirestore.instance.collection('events').add(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing ? 'Event updated!' : 'Event created!',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
