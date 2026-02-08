import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:country_picker/country_picker.dart';
import 'dart:io';
import '../../../auth/data/models/user.dart';
import '../../../auth/phone_verif/phone_verification_screen.dart';

class EditProfileScreenEnhanced extends StatefulWidget {
  const EditProfileScreenEnhanced({super.key});

  @override
  State<EditProfileScreenEnhanced> createState() =>
      _EditProfileScreenEnhancedState();
}

class _EditProfileScreenEnhancedState extends State<EditProfileScreenEnhanced> {
  final User? _firebaseUser = FirebaseAuth.instance.currentUser;

  // Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _bioController = TextEditingController();
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();

  // State variables
  String _completePhoneNumber = "";
  String _isoCode = "EG";
  String _selectedRole = "tourist";
  List<String> _selectedInterests = [];
  bool _isLoading = false;
  UserModel? _currentUser;
  File? _selectedImage;
  bool _isUploadingImage = false;

  final List<String> _availableInterests = [
    '🏛️ History',
    '🍽️ Food',
    '🥾 Hiking',
    '📸 Photography',
    '🏖️ Beach',
    '🎨 Art',
    '🕌 Architecture',
    '🌴 Nature',
    '🚴 Adventure',
    '🛍️ Shopping',
    '🎭 Culture',
    '🌅 Sunset',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<bool> _uploadProfileImage() async {
    if (_selectedImage == null || _firebaseUser == null) return false;

    setState(() => _isUploadingImage = true);

    try {
      final filename =
          'profile_${_firebaseUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(filename);

      final uploadTask = ref.putFile(_selectedImage!);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint('Upload progress: $progress%');
      });

      // ✅ FIX: Use whenComplete and timeout to prevent hanging
      await uploadTask.whenComplete(() {}).timeout(const Duration(seconds: 45));
      final imageUrl = await ref.getDownloadURL();

      // Update Firestore with new image URL
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_firebaseUser!.uid)
          .update({'profileImageUrl': imageUrl});

      // Update local state
      if (mounted) {
        setState(() {
          _currentUser = _currentUser?.copyWith(profileImageUrl: imageUrl);
          _selectedImage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile photo updated ✅"),
            backgroundColor: Colors.green,
          ),
        );
      }
      return true;
    } catch (e) {
      debugPrint("Upload error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error uploading photo. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _loadData() async {
    if (_firebaseUser == null) return;
    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_firebaseUser!.uid)
          .get()
          .timeout(
            const Duration(seconds: 10),
          ); // ✅ FIX: Timeout prevents infinite loading

      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!, doc.id);

        _fullNameController.text =
            "${_currentUser!.firstName} ${_currentUser!.lastName}";
        _emailController.text = _currentUser!.email;
        _nationalityController.text = _currentUser!.nationality;
        _completePhoneNumber = _currentUser!.phoneNumber;
        _bioController.text = _currentUser!.bio;
        _instagramController.text = _currentUser!.instagramHandle;
        _twitterController.text = _currentUser!.twitterHandle;
        _selectedRole = _currentUser!.role;
        _selectedInterests = List.from(_currentUser!.interests);
      }
    } catch (e) {
      debugPrint("Error loading user: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    // ✅ AUTO-VERIFY: Check if logged in via Google/Facebook (Background Task)
    if (_currentUser != null && mounted) {
      bool isSocialLogin = _firebaseUser!.providerData.any(
        (userInfo) =>
            userInfo.providerId == 'google.com' ||
            userInfo.providerId == 'facebook.com',
      );

      if (isSocialLogin && !_currentUser!.emailVerified) {
        try {
          debugPrint("Auto-verifying email for social login user");
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUser!.id)
              .update({'emailVerified': true});

          if (mounted) {
            setState(() {
              _currentUser = _currentUser!.copyWith(emailVerified: true);
            });
          }
        } catch (e) {
          debugPrint("Error auto-verifying: $e");
        }
      }
    }
  }

  Future<void> _submit() async {
    if (_currentUser == null) return;

    // Upload image first if one was selected
    if (_selectedImage != null) {
      final success = await _uploadProfileImage();
      if (!success) {
        // Stop if upload failed
        return;
      }
    }

    if (_completePhoneNumber.isNotEmpty && _completePhoneNumber.length < 10) {
      _showError("Please enter a valid phone number");
      return;
    }

    final isPhoneChanged = _completePhoneNumber != _currentUser!.phoneNumber;
    final isPhoneAdded =
        _completePhoneNumber.isNotEmpty && _currentUser!.phoneNumber.isEmpty;

    if ((isPhoneAdded || isPhoneChanged) && _completePhoneNumber.isNotEmpty) {
      final bool? verified = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PhoneVerificationScreen(),
        ),
      );

      if (verified != true) {
        _showError("Phone number must be verified before saving");
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final nameParts = _fullNameController.text.trim().split(' ');
      final fName = nameParts.isNotEmpty ? nameParts.first : '';
      final lName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final updatedUser = UserModel(
        id: _currentUser!.id,
        email: _currentUser!.email,
        firstName: fName,
        lastName: lName,
        birthDate: _currentUser!.birthDate,
        role: _selectedRole,
        profileImageUrl: _currentUser!.profileImageUrl,
        phoneNumber: _completePhoneNumber,
        nationality: _nationalityController.text.trim(),
        bio: _bioController.text.trim(),
        interests: _selectedInterests,
        instagramHandle: _instagramController.text.trim(),
        twitterHandle: _twitterController.text.trim(),
        isNotificationsEnabled: _currentUser!.isNotificationsEnabled,
        isDarkMode: _currentUser!.isDarkMode,
        language: _currentUser!.language,
        phoneVerified:
            _currentUser!.phoneVerified ||
            ((isPhoneAdded || isPhoneChanged) &&
                _completePhoneNumber.isNotEmpty),
        emailVerified: _currentUser!.emailVerified,
        createdAt: _currentUser!.createdAt,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(updatedUser.id)
          .set(updatedUser.toMap(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 10)); // ✅ Timeout for save too

      if ((isPhoneAdded || isPhoneChanged) && _completePhoneNumber.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(updatedUser.id)
            .update({'phoneVerified': true});
      }

      await _firebaseUser?.updateDisplayName("$fName $lName");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile Updated ✅"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBE8),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.40,
              child: Image.asset(
                "assets/pattern_comp.png",
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFC79A00),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          children: [
                            const SizedBox(height: 20),
                            _buildAvatar(),
                            const SizedBox(height: 30),

                            // Basic Info Section
                            _buildSectionTitle("Basic Information"),
                            _buildLabel("Full name"),
                            _buildField(_fullNameController),
                            const SizedBox(height: 20),

                            _buildLabel("Email"),
                            // ✅ VISUAL HINT: Read-only visual indication
                            _buildField(_emailController, readOnly: true),
                            const SizedBox(height: 20),

                            _buildLabel("Role"),
                            _buildRoleSelector(),
                            const SizedBox(height: 20),

                            // Contact Info Section
                            _buildSectionTitle("Contact Information"),
                            _buildLabel("Phone number"),
                            _buildPhoneField(),
                            const SizedBox(height: 20),

                            _buildLabel("Nationality"),
                            _buildNationalityPicker(),
                            const SizedBox(height: 30),

                            // About Section
                            _buildSectionTitle("About You"),
                            _buildLabel("Bio"),
                            _buildBioField(),
                            const SizedBox(height: 20),

                            _buildLabel("Interests"),
                            _buildInterestsTags(),
                            const SizedBox(height: 30),

                            // Social Links Section
                            _buildSectionTitle("Social Links (Optional)"),
                            _buildLabel("Instagram"),
                            _buildSocialField(
                              _instagramController,
                              "@username",
                            ),
                            const SizedBox(height: 20),

                            _buildLabel("Twitter/X"),
                            _buildSocialField(_twitterController, "@username"),
                            const SizedBox(height: 30),

                            // Verification Status
                            _buildVerificationStatus(),
                            const SizedBox(height: 40),

                            _buildSubmitButton(),
                            const SizedBox(height: 20),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: Color(0xFF714611),
            ),
          ),
          const Text(
            "Edit profile",
            style: TextStyle(
              fontSize: 20,
              fontFamily: "Marcellus",
              color: Color(0xFF714611),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF714611),
          fontSize: 20,
          fontFamily: "Marcellus",
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF4A3B2A),
            ),
            child: ClipOval(
              child: _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.cover)
                  : _currentUser?.profileImageUrl.isNotEmpty == true
                  ? Image.network(
                      _currentUser!.profileImageUrl,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.person, color: Colors.white, size: 60),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _isUploadingImage ? null : _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFBF7ED),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: _isUploadingImage
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Color(0xFF714611)),
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt_outlined,
                        size: 20,
                        color: Color(0xFF714611),
                      ),
              ),
            ),
          ),
          if (_selectedImage != null)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => setState(() => _selectedImage = null),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF714611),
        fontSize: 14,
        fontFamily: "Marcellus",
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _buildField(
    TextEditingController controller, {
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        // ✅ VISUAL HINT: Different background for read-only
        color: readOnly
            ? Colors.grey.withOpacity(0.15)
            : const Color(0xFFFFFEF0),
        borderRadius: BorderRadius.circular(25),
        boxShadow: readOnly
            ? []
            : const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
        border: readOnly
            ? Border.all(color: Color(0xFF714611).withOpacity(0.4))
            : null,
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        style: TextStyle(
          color: readOnly ? Color(0xFF714611) : const Color(0xFF5A3E18),
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          // ✅ VISUAL HINT: Lock icon for read-only
          suffixIcon: readOnly
              ? const Icon(
                  Icons.lock_outline,
                  color: Color(0xFF714611),
                  size: 20,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildBioField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEF0),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: _bioController,
        maxLines: 3,
        style: const TextStyle(color: Color(0xFF714611)),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          hintText: "Tell us about yourself...",
          hintStyle: TextStyle(color: Color(0xFFB3A896)),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEF0),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: IntlPhoneField(
        initialValue: _completePhoneNumber,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          counterText: "",
        ),
        initialCountryCode: _isoCode,
        style: const TextStyle(color: Color(0xFF5A3E18)),
        dropdownTextStyle: const TextStyle(color: Color(0xFF5A3E18)),
        dropdownIcon: const Icon(
          Icons.arrow_drop_down,
          color: Color(0xFF5A3E18),
        ),
        onChanged: (phone) {
          _completePhoneNumber = phone.completeNumber;
          _isoCode = phone.countryISOCode;
        },
      ),
    );
  }

  Widget _buildNationalityPicker() {
    return GestureDetector(
      onTap: () {
        showCountryPicker(
          context: context,
          showPhoneCode: false,
          onSelect: (Country country) {
            setState(() {
              _nationalityController.text =
                  "${country.flagEmoji} ${country.name}";
            });
          },
          countryListTheme: CountryListThemeData(
            backgroundColor: const Color(0xFFFFFEF0),
            textStyle: const TextStyle(
              fontFamily: "Marcellus",
              color: Color(0xFF5A3E18),
            ),
            borderRadius: BorderRadius.circular(20),
            inputDecoration: const InputDecoration(
              hintText: 'Search nationality',
              prefixIcon: Icon(Icons.search, color: Color(0xFF5A3E18)),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF5A3E18)),
              ),
            ),
          ),
        );
      },
      child: AbsorbPointer(child: _buildField(_nationalityController)),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEF0),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Text(
        '🧳 Traveler',
        style: const TextStyle(
          color: Color(0xFF5A3E18),
          fontSize: 16,
          fontFamily: 'Marcellus',
        ),
      ),
    );
  }

  Widget _buildInterestsTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableInterests.map((interest) {
        final isSelected = _selectedInterests.contains(interest);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedInterests.remove(interest);
              } else {
                _selectedInterests.add(interest);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFC79A00)
                  : const Color(0xFFFFFEF0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF714611)
                    : Color(0xFFF2F1E0),
              ),
            ),
            child: Text(
              interest,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF5A3E18),
                fontSize: 16,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSocialField(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEF0),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Color(0xFF5A3E18)),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFB3A896)),
        ),
      ),
    );
  }

  Widget _buildVerificationStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEF0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Verification Status",
            style: TextStyle(
              color: Color(0xFF714611),
              fontSize: 16,
              fontFamily: "Marcellus",
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildVerificationItem("Email", _currentUser?.emailVerified ?? false),
          const SizedBox(height: 8),
          _buildVerificationItem("Phone", _currentUser?.phoneVerified ?? false),
        ],
      ),
    );
  }

  Widget _buildVerificationItem(String label, bool isVerified) {
    return Row(
      children: [
        Icon(
          isVerified ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: isVerified ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isVerified ? Colors.green : Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC79A00),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "Save Changes",
          style: TextStyle(
            fontSize: 18,
            fontFamily: "Marcellus",
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _nationalityController.dispose();
    _bioController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    super.dispose();
  }
}
