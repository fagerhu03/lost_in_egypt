import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';

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
    final sanitised = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (sanitised != raw) {
      _controller.value = _controller.value.copyWith(
        text: sanitised,
        selection: TextSelection.collapsed(offset: sanitised.length),
      );
    }

    setState(() {
      _isAvailable = null;
      _errorMessage = null;
      _isChecking = false;
    });

    _debounce?.cancel();

    if (sanitised.isEmpty) return;

    final formatError = _formatError(sanitised);
    if (formatError != null) {
      setState(() => _errorMessage = formatError);
      return;
    }

    setState(() => _isChecking = true);
    _debounce = Timer(const Duration(milliseconds: 500), () => _checkAvailability(sanitised));
  }

  String? _formatError(String value) {
    final l = AppLocalizations.of(context);
    if (value.length < 3) return l.usernameTooShort;
    if (value.length > 20) return l.usernameTooLong;
    if (!_validPattern.hasMatch(value)) return l.usernameInvalidChars;
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
        _errorMessage =
            query.docs.isEmpty ? null : AppLocalizations.of(context).usernameTaken;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _isAvailable = null;
        _errorMessage = AppLocalizations.of(context).usernameCheckFailed;
      });
    }
  }

  Future<void> _confirm() async {
    final username = _controller.text.trim();

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
      final db = FirebaseFirestore.instance;
      final claimRef = db.collection('usernames').doc(username);
      final userRef = db.collection('users').doc(uid);

      await db.runTransaction((tx) async {
        final claimSnap = await tx.get(claimRef);
        if (claimSnap.exists) {
          throw FirebaseException(
            plugin: 'firestore',
            code: 'already-exists',
            message: 'Username was just taken — please choose another.',
          );
        }
        tx.set(claimRef, {'uid': uid});
        tx.update(userRef, {'username': username});
      });

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeWrapper()),
        (route) => false,
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      setState(() {
        _isSaving = false;
        _errorMessage = e.code == 'already-exists'
            ? l.usernameTakenJustNow
            : l.usernameSaveFailed;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = AppLocalizations.of(context).usernameSaveFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
            padding: EdgeInsets.symmetric(horizontal: 28.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 60.h),

                Text(
                  l.usernameTitle,
                  style: TextStyle(
                    fontSize: 34.sp,
                    fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                    color: onSurface,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  l.usernameSubtitle,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(height: 48.h),

                // Input field
                Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(25.r),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : Colors.black.withValues(alpha: 0.10),
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
                        padding: EdgeInsetsDirectional.only(start: 20.w),
                        child: Text(
                          "@",
                          style: TextStyle(
                            color: primary,
                            fontSize: 20.sp,
                            fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
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
                            fontSize: 18.sp,
                            fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                          ),
                          onChanged: _onChanged,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 18.h),
                            hintText: "your_handle",
                            hintStyle: TextStyle(
                              color: onSurface.withValues(alpha: 0.35),
                              fontSize: 18.sp,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.only(end: 16.w),
                        child: _buildStatusIcon(),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _buildFeedback(onSurface),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 54.h,
                  child: ElevatedButton(
                    onPressed: canConfirm ? _confirm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      disabledBackgroundColor: primary.withValues(alpha: 0.35),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 24.r,
                            height: 24.r,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            l.commonContinue,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 32.h),
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
        width: 18.r,
        height: 18.r,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    if (_isAvailable == true) {
      return Icon(Icons.check_circle, color: Colors.green, size: 22.r);
    }
    if (_errorMessage != null) {
      return Icon(Icons.cancel, color: Colors.red, size: 22.r);
    }
    return const SizedBox.shrink();
  }

  Widget _buildFeedback(Color onSurface) {
    final l = AppLocalizations.of(context);
    if (_errorMessage != null) {
      return Row(
        key: const ValueKey('error'),
        children: [
          SizedBox(width: 8.w),
          Text(
            _errorMessage!,
            style: TextStyle(color: Colors.red, fontSize: 13.sp),
          ),
        ],
      );
    }
    if (_isAvailable == true) {
      return Row(
        key: const ValueKey('ok'),
        children: [
          SizedBox(width: 8.w),
          Text(
            l.usernameAvailable(_controller.text),
            style: TextStyle(color: Colors.green, fontSize: 13.sp),
          ),
        ],
      );
    }
    if (_controller.text.isEmpty) {
      return Padding(
        key: const ValueKey('hint'),
        padding: EdgeInsetsDirectional.only(start: 8.w),
        child: Text(
          l.usernameRules,
          style: TextStyle(
            color: onSurface.withValues(alpha: 0.45),
            fontSize: 13.sp,
          ),
        ),
      );
    }
    return const SizedBox.shrink(key: ValueKey('empty'));
  }
}
