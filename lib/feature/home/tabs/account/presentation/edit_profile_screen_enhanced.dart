import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import 'package:lost_in_egypt/feature/auth/data/models/user.dart';
import 'package:lost_in_egypt/feature/auth/presentation/phone_verif/phone_verification_screen.dart';
import '../../camera/widgets/badge_unlock_dialog.dart';
import '../domain/badge_constants.dart';

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

  final List<String> _availableInterests = const [
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

      await uploadTask.whenComplete(() {}).timeout(const Duration(seconds: 45));
      final imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_firebaseUser!.uid)
          .update({'profileImageUrl': imageUrl});

      if (mounted) {
        setState(() {
          _currentUser = _currentUser?.copyWith(profileImageUrl: imageUrl);
          _selectedImage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Profile photo updated ✅"),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
      return true;
    } catch (e) {
      debugPrint("Upload error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
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
          .timeout(const Duration(seconds: 10));

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

    // Auto-verify email for social login users
    if (_currentUser != null && mounted) {
      final isSocialLogin = _firebaseUser!.providerData.any(
            (userInfo) =>
        userInfo.providerId == 'google.com' ||
            userInfo.providerId == 'facebook.com',
      );

      if (isSocialLogin && !_currentUser!.emailVerified) {
        try {
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

    if (_selectedImage != null) {
      final success = await _uploadProfileImage();
      if (!success) return;
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
        phoneVerified: _currentUser!.phoneVerified ||
            ((isPhoneAdded || isPhoneChanged) && _completePhoneNumber.isNotEmpty),
        emailVerified: _currentUser!.emailVerified,
        createdAt: _currentUser!.createdAt,
        visitedLandmarks: _currentUser!.visitedLandmarks,
      );

      // Easter Egg: The Hidden Vault (Imhotep)
      bool justUnlockedImhotep = false;
      if (fName.trim().toLowerCase() == 'imhotep') {
        if (!updatedUser.visitedLandmarks.contains('imhotep_secret')) {
          updatedUser.visitedLandmarks.add('imhotep_secret');
          justUnlockedImhotep = true;
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(updatedUser.id)
          .set(updatedUser.toMap(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));

      if ((isPhoneAdded || isPhoneChanged) && _completePhoneNumber.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(updatedUser.id)
            .update({'phoneVerified': true});
      }

      await _firebaseUser?.updateDisplayName("$fName $lName");

      if (mounted) {
        if (justUnlockedImhotep) {
           final badge = BadgeConstants.allBadges.firstWhere((b) => b.id == 'imhotep_secret');
           BadgeUnlockDialog.show(context, badge);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Profile Updated ✅"),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = theme.scaffoldBackgroundColor;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final patternOpacity = isDark ? 0.20 : 0.40;

    // visible shadows (dark in light, glow in dark)
    final fieldShadow = BoxShadow(
      color: isDark
          ? Colors.white.withOpacity(0.14)
          : Colors.black.withOpacity(0.12),
      blurRadius: 16,
      spreadRadius: 1,
      offset: const Offset(0, 8),
    );

    final borderColor =
    (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.10 : 0.06);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: patternOpacity,
              child: Image.asset(
                "assets/pattern_comp.png",
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeat,
                errorBuilder: (c, o, s) => const SizedBox.shrink(),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, onSurface),
                Expanded(
                  child: _isLoading
                      ? Center(
                    child: CircularProgressIndicator(color: primary),
                  )
                      : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      const SizedBox(height: 20),
                      _buildAvatar(primary, onSurface, fieldShadow),
                      const SizedBox(height: 30),

                      _buildSectionTitle("Basic Information", onSurface),
                      _buildLabel("Full name", onSurface),
                      _buildField(
                        controller: _fullNameController,
                        surface: surface,
                        onSurface: onSurface,
                        shadow: fieldShadow,
                        borderColor: borderColor,
                      ),
                      const SizedBox(height: 20),

                      _buildLabel("Email", onSurface),
                      _buildField(
                        controller: _emailController,
                        readOnly: true,
                        surface: surface,
                        onSurface: onSurface,
                        shadow: fieldShadow,
                        borderColor: borderColor,
                      ),
                      const SizedBox(height: 20),

                      _buildLabel("Role", onSurface),
                      _buildRoleSelector(surface, onSurface, fieldShadow, borderColor),
                      const SizedBox(height: 20),

                      _buildSectionTitle("Contact Information", onSurface),
                      _buildLabel("Phone number", onSurface),
                      _buildPhoneField(surface, onSurface, fieldShadow, borderColor),
                      const SizedBox(height: 20),

                      _buildLabel("Nationality", onSurface),
                      _buildNationalityPicker(
                        surface,
                        onSurface,
                        fieldShadow,
                        borderColor,
                        primary,
                      ),
                      const SizedBox(height: 30),

                      _buildSectionTitle("About You", onSurface),
                      _buildLabel("Bio", onSurface),
                      _buildBioField(surface, onSurface, fieldShadow, borderColor),
                      const SizedBox(height: 20),

                      _buildLabel("Interests", onSurface),
                      _buildInterestsTags(surface, onSurface, primary, borderColor),
                      const SizedBox(height: 30),

                      _buildSectionTitle("Social Links (Optional)", onSurface),
                      _buildLabel("Instagram", onSurface),
                      _buildSocialField(
                        controller: _instagramController,
                        hint: "@username",
                        surface: surface,
                        onSurface: onSurface,
                        shadow: fieldShadow,
                        borderColor: borderColor,
                      ),
                      const SizedBox(height: 20),

                      _buildLabel("Twitter/X", onSurface),
                      _buildSocialField(
                        controller: _twitterController,
                        hint: "@username",
                        surface: surface,
                        onSurface: onSurface,
                        shadow: fieldShadow,
                        borderColor: borderColor,
                      ),
                      const SizedBox(height: 30),

                      _buildVerificationStatus(surface, onSurface, borderColor),
                      const SizedBox(height: 40),

                      _buildSubmitButton(primary, onSurface),
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

  Widget _buildHeader(BuildContext context, Color onSurface) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new, size: 20, color: onSurface),
          ),
          Text(
            "Edit profile",
            style: TextStyle(
              fontSize: 20,
              fontFamily: "Marcellus",
              color: onSurface,
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color onSurface) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 10),
      child: Text(
        title,
        style: TextStyle(
          color: onSurface,
          fontSize: 20,
          fontFamily: "Marcellus",
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAvatar(Color primary, Color onSurface, BoxShadow shadow) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withOpacity(0.18),
              boxShadow: [shadow],
            ),
            child: ClipOval(
              child: _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.cover)
                  : (_currentUser?.profileImageUrl.isNotEmpty == true)
                  ? Image.network(
                _currentUser!.profileImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) => Center(
                  child: Icon(Icons.person, color: onSurface, size: 60),
                ),
              )
                  : Center(
                child: Icon(Icons.person, color: onSurface, size: 60),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              shape: const CircleBorder(),
              clipBehavior: Clip.hardEdge,
              elevation: 2,
              child: InkWell(
                onTap: _isUploadingImage ? null : _pickImage,
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black)
                          .withOpacity(0.08),
                    ),
                  ),
                  child: _isUploadingImage
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(primary),
                    ),
                  )
                      : Icon(
                    Icons.camera_alt_outlined,
                    size: 20,
                    color: primary,
                  ),
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

  Widget _buildLabel(String text, Color onSurface) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      text,
      style: TextStyle(
        color: onSurface.withOpacity(0.85),
        fontSize: 14,
        fontFamily: "Marcellus",
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _buildField({
    required TextEditingController controller,
    required Color surface,
    required Color onSurface,
    required BoxShadow shadow,
    required Color borderColor,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: readOnly ? surface.withOpacity(0.70) : surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: readOnly ? [] : [shadow],
        border: Border.all(
          color: readOnly ? borderColor.withOpacity(1) : borderColor,
        ),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        style: TextStyle(color: onSurface),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          suffixIcon: readOnly
              ? Icon(Icons.lock_outline, color: onSurface.withOpacity(0.7), size: 20)
              : null,
        ),
      ),
    );
  }

  Widget _buildBioField(
      Color surface,
      Color onSurface,
      BoxShadow shadow,
      Color borderColor,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [shadow],
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: _bioController,
        maxLines: 3,
        style: TextStyle(color: onSurface),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          hintText: "Tell us about yourself...",
          hintStyle: TextStyle(color: onSurface.withOpacity(0.45)),
        ),
      ),
    );
  }

  Widget _buildPhoneField(
      Color surface,
      Color onSurface,
      BoxShadow shadow,
      Color borderColor,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [shadow],
        border: Border.all(color: borderColor),
      ),
      child: IntlPhoneField(
        initialValue: _completePhoneNumber,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          counterText: "",
        ),
        initialCountryCode: _isoCode,
        style: TextStyle(color: onSurface),
        dropdownTextStyle: TextStyle(color: onSurface),
        dropdownIcon: Icon(Icons.arrow_drop_down, color: onSurface.withOpacity(0.8)),
        onChanged: (phone) {
          _completePhoneNumber = phone.completeNumber;
          _isoCode = phone.countryISOCode;
        },
      ),
    );
  }

  Widget _buildNationalityPicker(
      Color surface,
      Color onSurface,
      BoxShadow shadow,
      Color borderColor,
      Color primary,
      ) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(25),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {
          showCountryPicker(
            context: context,
            showPhoneCode: false,
            onSelect: (Country country) {
              setState(() {
                _nationalityController.text = "${country.flagEmoji} ${country.name}";
              });
            },
            countryListTheme: CountryListThemeData(
              backgroundColor: surface,
              textStyle: TextStyle(
                fontFamily: "Marcellus",
                color: onSurface,
              ),
              borderRadius: BorderRadius.circular(20),
              inputDecoration: InputDecoration(
                hintText: 'Search nationality',
                prefixIcon: Icon(Icons.search, color: onSurface.withOpacity(0.8)),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: borderColor),
                  borderRadius: BorderRadius.circular(14),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: borderColor),
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primary, width: 1.4),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(25),
        child: AbsorbPointer(
          child: _buildField(
            controller: _nationalityController,
            surface: surface,
            onSurface: onSurface,
            shadow: shadow,
            borderColor: borderColor,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector(
      Color surface,
      Color onSurface,
      BoxShadow shadow,
      Color borderColor,
      ) {
    // you can replace this later with real selector UI
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [shadow],
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Text(
        '🧳 Traveler',
        style: TextStyle(
          color: onSurface,
          fontSize: 16,
          fontFamily: 'Marcellus',
        ),
      ),
    );
  }

  Widget _buildInterestsTags(
      Color surface,
      Color onSurface,
      Color primary,
      Color borderColor,
      ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableInterests.map((interest) {
        final isSelected = _selectedInterests.contains(interest);
        return Material(
          color: isSelected ? primary : surface,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedInterests.remove(interest);
                } else {
                  _selectedInterests.add(interest);
                }
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? primary.withOpacity(0.8) : borderColor,
                ),
              ),
              child: Text(
                interest,
                style: TextStyle(
                  color: isSelected ? Colors.white : onSurface.withOpacity(0.9),
                  fontSize: 15,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSocialField({
    required TextEditingController controller,
    required String hint,
    required Color surface,
    required Color onSurface,
    required BoxShadow shadow,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [shadow],
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: onSurface),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          hintText: hint,
          hintStyle: TextStyle(color: onSurface.withOpacity(0.45)),
        ),
      ),
    );
  }

  Widget _buildVerificationStatus(Color surface, Color onSurface, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Verification Status",
            style: TextStyle(
              color: onSurface,
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

  Widget _buildSubmitButton(Color primary, Color onSurface) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
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