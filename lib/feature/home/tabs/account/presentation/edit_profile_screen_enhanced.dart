import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import 'package:lost_in_egypt/feature/auth/data/models/user.dart';
import 'package:lost_in_egypt/feature/auth/presentation/phone_verif/phone_verification_screen.dart';
import '../../camera/widgets/badge_unlock_dialog.dart';
import '../domain/badge_constants.dart';
import 'package:lost_in_egypt/core/utils/image_utils.dart';
import 'package:lost_in_egypt/core/utils/error_handler.dart';
import 'package:lost_in_egypt/feature/home/tabs/community/data/repositories/firebase_community_repository.dart';

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
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _bioController = TextEditingController();
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();

  String? _usernameError;
  String? _instagramError;
  String? _twitterError;

  String _selectedFlagEmoji = '';

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

      final fileToUpload = await ImageUtils.compressImage(_selectedImage!) ?? _selectedImage!;
      final uploadTask = ref.putFile(fileToUpload);

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
        _usernameController.text = _currentUser!.username;
        _emailController.text = _currentUser!.email;
        _nationalityController.text = _currentUser!.nationality;
        // Extract the flag emoji from the stored nationality string (format: "🇺🇸 United States")
        final nat = _currentUser!.nationality;
        if (nat.length >= 4 && nat.codeUnitAt(0) == 0xD83C) {
          _selectedFlagEmoji = nat.substring(0, 4);
        }
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

    // Validate social handles
    final igVal = _instagramController.text.trim();
    final twVal = _twitterController.text.trim();
    String? igErr;
    String? twErr;
    if (igVal.isNotEmpty && !RegExp(r'^[a-zA-Z0-9._]{1,30}$').hasMatch(igVal)) {
      igErr = 'Instagram: letters, numbers, . and _ only (max 30)';
    }
    if (twVal.isNotEmpty && !RegExp(r'^[a-zA-Z0-9._]{1,15}$').hasMatch(twVal)) {
      twErr = 'Twitter/X: letters, numbers, . and _ only (max 15)';
    }
    if (igErr != null || twErr != null) {
      setState(() { _instagramError = igErr; _twitterError = twErr; });
      return;
    }

    // Validate username before saving
    final newUsername = _usernameController.text.trim().toLowerCase();
    final usernameErr = await _validateUsername(newUsername);
    if (usernameErr != null) {
      setState(() => _usernameError = usernameErr);
      return;
    }
    setState(() => _usernameError = null);

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
        username: newUsername,
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

      final db = FirebaseFirestore.instance;
      final userRef = db.collection('users').doc(updatedUser.id);
      final usernameChanged = newUsername != _currentUser!.username;

      if (usernameChanged) {
        // Atomically release old handle and claim new one
        final oldClaimRef = db.collection('usernames').doc(_currentUser!.username);
        final newClaimRef = db.collection('usernames').doc(newUsername);
        await db.runTransaction((tx) async {
          final newClaimSnap = await tx.get(newClaimRef);
          if (newClaimSnap.exists && newClaimSnap.data()?['uid'] != updatedUser.id) {
            throw FirebaseException(
              plugin: 'firestore',
              code: 'already-exists',
              message: 'Username was just taken.',
            );
          }
          if (_currentUser!.username.isNotEmpty) tx.delete(oldClaimRef);
          tx.set(newClaimRef, {'uid': updatedUser.id});
          tx.set(userRef, {
            ...updatedUser.toMap(),
            if (_selectedFlagEmoji.isNotEmpty) 'nationalityFlag': _selectedFlagEmoji,
          }, SetOptions(merge: true));
        });
      } else {
        await userRef
            .set({
              ...updatedUser.toMap(),
              if (_selectedFlagEmoji.isNotEmpty) 'nationalityFlag': _selectedFlagEmoji,
            }, SetOptions(merge: true))
            .timeout(const Duration(seconds: 10));
      }

      if ((isPhoneAdded || isPhoneChanged) && _completePhoneNumber.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(updatedUser.id)
            .update({'phoneVerified': true});
      }

      await _firebaseUser?.updateDisplayName("$fName $lName");

      // Refresh flag on community posts in background (fire-and-forget)
      FirebaseCommunityRepository().refreshUserPostsFlag(updatedUser.id);

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
    } on FirebaseException catch (e) {
      if (e.code == 'already-exists') {
        setState(() => _usernameError = "That username was just taken — try another");
      } else {
        _showError(ErrorHandler.handleGenericError(e));
      }
    } catch (e) {
      _showError(ErrorHandler.handleGenericError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _requestLanguageAddition() async {
    if (_firebaseUser == null) return;

    setState(() => _isLoading = true);
    try {
      final existingQuery = await FirebaseFirestore.instance
          .collection('admin_requests')
          .where('userId', isEqualTo: _firebaseUser!.uid)
          .where('type', isEqualTo: 'language_addition')
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingQuery.docs.isNotEmpty) {
        _showError("You already have a pending language request.");
        setState(() => _isLoading = false);
        return;
      }
    } catch (e) {
      _showError(ErrorHandler.handleGenericError(e));
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = false);

    final TextEditingController newLangController = TextEditingController();
    final bool? shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Language Addition', style: TextStyle(fontFamily: 'Marcellus')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "By Egyptian law, guides require official certification to guide in specific languages. "
              "Please enter the language you wish to add. An admin will verify your syndicate/MOTA records.",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newLangController,
              decoration: const InputDecoration(
                hintText: "e.g., Spanish, German, Italian",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newLangController.text.trim().isNotEmpty) {
                 Navigator.pop(ctx, true);
              }
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );

    if (shouldSubmit == true && _firebaseUser != null) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection('admin_requests').add({
          'type': 'language_addition',
          'userId': _firebaseUser!.uid,
          'requestedLanguage': newLangController.text.trim(),
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'userEmail': _currentUser?.email,
          'userName': "${_currentUser?.firstName} ${_currentUser?.lastName}",
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Request submitted! An admin will review it shortly."),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        _showError(ErrorHandler.handleGenericError(e));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  /// Validates username format and checks Firestore uniqueness.
  /// Returns an error string or null if valid.
  Future<String?> _validateUsername(String username) async {
    if (username.isEmpty) return "Username cannot be empty";
    if (username.length < 3) return "Username must be at least 3 characters";
    if (username.length > 20) return "Username must be 20 characters or fewer";
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(username)) {
      return "Only lowercase letters, numbers, and underscores";
    }
    // Skip uniqueness check if unchanged
    if (username == _currentUser?.username) return null;
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) return "Username is already taken";
    return null;
  }

  int _computeProfileCompletion() {
    if (_currentUser == null) return 0;
    int filled = 0;
    // 1. Profile photo
    if (_selectedImage != null || _currentUser!.profileImageUrl.isNotEmpty) filled++;
    // 2. Full name (first + last parts)
    final nameParts = _fullNameController.text.trim().split(' ');
    if (nameParts.length >= 2 && nameParts[0].isNotEmpty && nameParts[1].isNotEmpty) filled++;
    // 3. Username
    if (_usernameController.text.trim().isNotEmpty) filled++;
    // 4. Bio
    if (_bioController.text.trim().isNotEmpty) filled++;
    // 5. Nationality
    if (_nationalityController.text.trim().isNotEmpty) filled++;
    // 6. Phone verified
    if (_currentUser!.phoneVerified) filled++;
    // 7. At least 1 interest
    if (_selectedInterests.isNotEmpty) filled++;
    // 8. Instagram or Twitter
    if (_instagramController.text.trim().isNotEmpty || _twitterController.text.trim().isNotEmpty) filled++;
    return filled;
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

    return Container(
      decoration: BoxDecoration(
        color: bg,
        image: DecorationImage(
          image: const AssetImage("assets/pattern_comp.png"),
          fit: BoxFit.cover,
          repeat: ImageRepeat.repeat,
          opacity: patternOpacity,
        ),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
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
                      const SizedBox(height: 20),

                      // Profile completion indicator
                      Builder(builder: (context) {
                        final completed = _computeProfileCompletion();
                        final pct = (completed / 8 * 100).round();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Profile Completion",
                                  style: TextStyle(
                                    color: onSurface.withOpacity(0.7),
                                    fontSize: 13,
                                    fontFamily: 'Marcellus',
                                  ),
                                ),
                                Text(
                                  "$pct%",
                                  style: TextStyle(
                                    color: primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Marcellus',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: completed / 8,
                                backgroundColor: primary.withOpacity(0.12),
                                valueColor: AlwaysStoppedAnimation<Color>(primary),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 20),

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

                      _buildLabel("Username", onSurface),
                      _buildUsernameField(surface, onSurface, fieldShadow, borderColor, primary),
                      if (_usernameError != null) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            _usernameError!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
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
                        hint: "username (no @)",
                        surface: surface,
                        onSurface: onSurface,
                        shadow: fieldShadow,
                        borderColor: borderColor,
                        maxLength: 30,
                        errorText: _instagramError,
                        onChanged: (_) => setState(() => _instagramError = null),
                      ),
                      const SizedBox(height: 20),

                      _buildLabel("Twitter/X", onSurface),
                      _buildSocialField(
                        controller: _twitterController,
                        hint: "username (no @)",
                        surface: surface,
                        onSurface: onSurface,
                        shadow: fieldShadow,
                        borderColor: borderColor,
                        maxLength: 15,
                        errorText: _twitterError,
                        onChanged: (_) => setState(() => _twitterError = null),
                      ),
                      const SizedBox(height: 30),
                      
                      if (_currentUser?.isVerifiedGuide == true) ...[
                        _buildSectionTitle("Guide Credentials", onSurface),
                        _buildLabel("Certified Languages (Locked)", onSurface),
                        _buildLanguagesField(surface, onSurface, fieldShadow, borderColor),
                        const SizedBox(height: 30),
                      ],

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
    ));
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
                _selectedFlagEmoji = country.flagEmoji;
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
        _currentUser?.role == 'admin'
            ? '👑 Admin'
            : _currentUser?.isVerifiedGuide == true
                ? '🧭 Verified Guide'
                : '🧳 Tourist',
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

  Widget _buildLanguagesField(
      Color surface,
      Color onSurface,
      BoxShadow shadow,
      Color borderColor,
      ) {
    final TextEditingController langsController = TextEditingController(
      text: _currentUser?.certifiedLanguages.isNotEmpty == true 
        ? _currentUser!.certifiedLanguages.join(', ') 
        : "None certified yet.",
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildField(
          controller: langsController,
          surface: surface,
          onSurface: onSurface,
          shadow: shadow,
          borderColor: borderColor,
          readOnly: true,
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _requestLanguageAddition,
            icon: Icon(Icons.add_circle_outline, size: 18, color: Theme.of(context).colorScheme.primary),
            label: Text(
              "Request New Language",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField(
      Color surface,
      Color onSurface,
      BoxShadow shadow,
      Color borderColor,
      Color primary,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [shadow],
        border: Border.all(
          color: _usernameError != null ? Colors.red : borderColor,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              "@",
              style: TextStyle(
                color: primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _usernameController,
              style: TextStyle(color: onSurface),
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (value) {
                // Auto-lowercase
                final lower = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
                if (lower != value) {
                  _usernameController.value = _usernameController.value.copyWith(
                    text: lower,
                    selection: TextSelection.collapsed(offset: lower.length),
                  );
                }
                if (_usernameError != null) setState(() => _usernameError = null);
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                hintText: "your_handle",
                hintStyle: TextStyle(color: onSurface.withOpacity(0.45)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialField({
    required TextEditingController controller,
    required String hint,
    required Color surface,
    required Color onSurface,
    required BoxShadow shadow,
    required Color borderColor,
    int maxLength = 30,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [shadow],
            border: Border.all(color: hasError ? Colors.red : borderColor),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(color: onSurface),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._]')),
              LengthLimitingTextInputFormatter(maxLength),
            ],
            onChanged: (val) {
              if (hasError) setState(() {});
              onChanged?.call(val);
            },
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              hintText: hint,
              hintStyle: TextStyle(color: onSurface.withOpacity(0.45)),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
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
          _buildVerificationItem(
            "Email", 
            _currentUser?.emailVerified ?? false,
            onResend: () async {
              try {
                if (_firebaseUser != null && !_firebaseUser!.emailVerified) {
                  await _firebaseUser!.sendEmailVerification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Verification email sent! Check your inbox."),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ErrorHandler.handleGenericError(e)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 8),
          _buildVerificationItem(
            "Phone",
            _currentUser?.phoneVerified ?? false,
            onVerify: (_currentUser?.phoneVerified ?? true)
                ? null
                : () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PhoneVerificationScreen(),
                      ),
                    );
                    if (result == true && mounted) {
                      setState(() {
                        _currentUser = _currentUser?.copyWith(phoneVerified: true);
                      });
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationItem(
    String label,
    bool isVerified, {
    VoidCallback? onResend,
    VoidCallback? onVerify,
  }) {
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
        if (!isVerified && onResend != null) ...[
          const Spacer(),
          TextButton(
            onPressed: onResend,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              "Resend",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        if (!isVerified && onVerify != null) ...[
          const Spacer(),
          TextButton(
            onPressed: onVerify,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              "Verify now",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
    _usernameController.dispose();
    _emailController.dispose();
    _nationalityController.dispose();
    _bioController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    super.dispose();
  }
}
