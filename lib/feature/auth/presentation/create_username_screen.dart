import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../home/tabs/navigator/home_wrapper.dart';

class CreateUsernameScreen extends StatefulWidget {
  const CreateUsernameScreen({super.key});

  @override
  State<CreateUsernameScreen> createState() => _CreateUsernameScreenState();
}

class _CreateUsernameScreenState extends State<CreateUsernameScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  // null = not checked yet, true = available, false = taken/invalid
  bool? _isAvailable;
  String? _errorMessage;
  bool _isChecking = false;
  bool _isSaving = false;

  Timer? _debounce;

  static final _validPattern = RegExp(r'^[a-z0-9_]+$');

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    // Sanitise to lowercase + allowed chars only
    final sanitised = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (sanitised != raw) {
      _controller.value = _controller.value.copyWith(
        text: sanitised,
        selection: TextSelection.collapsed(offset: sanitised.length),
      );
    }

    // Reset state while user is typing
    setState(() {
      _isAvailable = null;
      _errorMessage = null;
      _isChecking = false;
    });

    _debounce?.cancel();

    if (sanitised.isEmpty) return;

    // Inline format validation (no async needed)
    final formatError = _formatError(sanitised);
    if (formatError != null) {
      setState(() => _errorMessage = formatError);
      return;
    }

    // Debounce Firestore check
    setState(() => _isChecking = true);
    _debounce = Timer(const Duration(milliseconds: 500), () => _checkAvailability(sanitised));
  }

  String? _formatError(String value) {
    if (value.length < 3) return "Too short — minimum 3 characters";
    if (value.length > 20) return "Too long — maximum 20 characters";
    if (!_validPattern.hasMatch(value)) return "Only lowercase letters, numbers, and underscores";
    return null;
  }

  Future<void> _checkAvailability(String username) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (!mounted) return;

      setState(() {
        _isChecking = false;
        _isAvailable = query.docs.isEmpty;
        _errorMessage = query.docs.isEmpty ? null : "That username is already taken";
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _isAvailable = null;
        _errorMessage = "Couldn't check availability — try again";
      });
    }
  }

  Future<void> _confirm() async {
    final username = _controller.text.trim();

    // Final guard before saving
    final formatError = _formatError(username);
    if (formatError != null) {
      setState(() => _errorMessage = formatError);
      return;
    }
    if (_isAvailable != true) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'username': username});

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeWrapper()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = "Failed to save — please try again";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final surface = theme.colorScheme.surface;
    final bg = theme.scaffoldBackgroundColor;
    final patternOpacity = isDark ? 0.20 : 0.40;

    final canConfirm = _isAvailable == true && !_isSaving;

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
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // Heading
                Text(
                  "Choose your\nusername",
                  style: TextStyle(
                    fontSize: 34,
                    fontFamily: "Marcellus",
                    color: onSurface,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "This is how others will find you in the community. You can change it later in your profile.",
                  style: TextStyle(
                    fontSize: 15,
                    color: onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 48),

                // Input
                Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.white.withOpacity(0.10)
                            : Colors.black.withOpacity(0.10),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(
                      color: _errorMessage != null
                          ? Colors.red
                          : _isAvailable == true
                              ? Colors.green
                              : (isDark ? Colors.white10 : Colors.black12),
                      width: _errorMessage != null || _isAvailable == true ? 1.5 : 1,
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
                            fontSize: 20,
                            fontFamily: "Marcellus",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: true,
                          autocorrect: false,
                          enableSuggestions: false,
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 18,
                            fontFamily: "Marcellus",
                          ),
                          onChanged: _onChanged,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 18),
                            hintText: "your_handle",
                            hintStyle: TextStyle(
                              color: onSurface.withOpacity(0.35),
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _buildStatusIcon(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Feedback row
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _buildFeedback(onSurface),
                ),

                const Spacer(),

                // Confirm button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: canConfirm ? _confirm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      disabledBackgroundColor: primary.withOpacity(0.35),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            "Continue",
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: "Marcellus",
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (_isChecking) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    if (_isAvailable == true) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 22);
    }
    if (_errorMessage != null) {
      return const Icon(Icons.cancel, color: Colors.red, size: 22);
    }
    return const SizedBox.shrink();
  }

  Widget _buildFeedback(Color onSurface) {
    if (_errorMessage != null) {
      return Row(
        key: const ValueKey('error'),
        children: [
          const SizedBox(width: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ],
      );
    }
    if (_isAvailable == true) {
      return Row(
        key: const ValueKey('ok'),
        children: [
          const SizedBox(width: 8),
          Text(
            "@${_controller.text} is available!",
            style: const TextStyle(color: Colors.green, fontSize: 13),
          ),
        ],
      );
    }
    if (_controller.text.isEmpty) {
      return Padding(
        key: const ValueKey('hint'),
        padding: const EdgeInsets.only(left: 8),
        child: Text(
          "3–20 characters · letters, numbers, underscores only",
          style: TextStyle(
            color: onSurface.withOpacity(0.45),
            fontSize: 13,
          ),
        ),
      );
    }
    return const SizedBox.shrink(key: ValueKey('empty'));
  }
}
