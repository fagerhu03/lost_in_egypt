import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../bloc/apply_guide_cubit.dart';
import 'package:lost_in_egypt/core/utils/page_transitions.dart';
import 'package:lost_in_egypt/main.dart'; // Import AuthGate
import '../bloc/apply_guide_state.dart';

class ApplyGuideScreen extends StatefulWidget {
  final bool isFromSignup;
  
  const ApplyGuideScreen({
    Key? key,
    this.isFromSignup = false,
  }) : super(key: key);

  @override
  State<ApplyGuideScreen> createState() => _ApplyGuideScreenState();
}

class _ApplyGuideScreenState extends State<ApplyGuideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _motaController = TextEditingController();
  final _syndicateController = TextEditingController();
  final _languagesController = TextEditingController();


  File? _motaImage;
  File? _syndicateImage;
  File? _idFrontImage;
  File? _idBackImage;
  File? _selfieImage;
  File? _profileImage;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(Function(File) onPicked) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      onPicked(File(pickedFile.path));
      setState(() {});
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_motaImage == null ||
        _syndicateImage == null ||
        _idFrontImage == null ||
        _idBackImage == null ||
        _selfieImage == null ||
        _profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required documents')),
      );
      return;
    }

    final languages = _languagesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    context.read<ApplyGuideCubit>().submitApplication(
          motaLicenseNumber: _motaController.text.trim(),
          syndicateNumber: _syndicateController.text.trim(),
          certifiedLanguages: languages,
          motaLicenseImage: _motaImage!,
          syndicateCardImage: _syndicateImage!,
          nationalIdFrontImage: _idFrontImage!,
          nationalIdBackImage: _idBackImage!,
          selfieWithIdImage: _selfieImage!,
          profileImage: _profileImage!,
        );
  }

  Widget _buildImagePicker(String title, File? imageFile, Function(File) onPicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickImage(onPicked),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(imageFile, fit: BoxFit.cover),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Tap to upload image', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.isFromSignup) {
           Navigator.of(context).pushAndRemoveUntil(
             FadePageRoute(page: const AuthGate()),
             (route) => false,
           );
           return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Apply as Guide')),
        body: BlocConsumer<ApplyGuideCubit, ApplyGuideState>(
          listener: (context, state) {
            if (state is ApplyGuideError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            } else if (state is ApplyGuideSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Application submitted successfully!')),
              );
              
              if (widget.isFromSignup) {
                 Navigator.of(context).pushAndRemoveUntil(
                   FadePageRoute(page: const AuthGate()),
                   (route) => false,
                 );
              } else {
                 Navigator.of(context).pop();
              }
            }
          },
        builder: (context, state) {
          final isLoading = state is ApplyGuideLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'To ensure user safety, all guides must provide official Egyptian credentials.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _motaController,
                    decoration: const InputDecoration(
                      labelText: 'MOTA License Number',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _syndicateController,
                    decoration: const InputDecoration(
                      labelText: 'Syndicate Membership Number',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _languagesController,
                    decoration: const InputDecoration(
                      labelText: 'Certified Languages (comma-separated)',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. English, Spanish, Arabic',
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),

                  _buildImagePicker('MOTA License Photo', _motaImage, (f) => _motaImage = f),
                  _buildImagePicker('Syndicate Card Photo', _syndicateImage, (f) => _syndicateImage = f),
                  _buildImagePicker('National ID (Front)', _idFrontImage, (f) => _idFrontImage = f),
                  _buildImagePicker('National ID (Back)', _idBackImage, (f) => _idBackImage = f),
                  _buildImagePicker('Selfie holding National ID', _selfieImage, (f) => _selfieImage = f),
                  _buildImagePicker('Professional Profile Picture', _profileImage, (f) => _profileImage = f),

                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isLoading 
                        ? const SizedBox(
                            width: 24, 
                            height: 24, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : const Text('Submit Application', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}
}
