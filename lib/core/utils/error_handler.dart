import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';

/// ✅ Centralized error message handler for all Firebase exceptions
class ErrorHandler {
  // ===== FIREBASE AUTH ERRORS =====
  static String handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      // User not found
      case 'user-not-found':
        return 'No user found with this email address.';

      // Wrong password
      case 'wrong-password':
        return 'The password you entered is incorrect.';

      // User disabled
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';

      // Email already in use
      case 'email-already-in-use':
        return 'This email is already registered. Please try logging in.';

      // Weak password
      case 'weak-password':
        return 'Your password is too weak. Use at least 8 characters with letters and numbers.';

      // Invalid email
      case 'invalid-email':
        return 'The email address is invalid.';

      // Operation not allowed
      case 'operation-not-allowed':
        return 'This sign-in method is not available right now.';

      // Requires recent login
      case 'requires-recent-login':
        return 'Please log in again before changing your password.';

      // Credential already in use
      case 'credential-already-in-use':
        return 'This credential is already linked to another account.';

      // Account exists with different credential
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email.';

      // Invalid credential
      case 'invalid-credential':
        return 'The credential provided is invalid or expired.';

      // Network request failed
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      // Too many requests
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';

      // Popup blocked by browser
      case 'popup-blocked-by-browser':
        return 'Please enable popups for this app.';

      // Popup closed by user
      case 'popup-closed-by-user':
        return 'Sign-in was cancelled.';

      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }

  // ===== FIREBASE FIRESTORE ERRORS =====
  static String handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      // Permission denied
      case 'permission-denied':
        return 'You do not have permission to access this resource.';

      // Not found
      case 'not-found':
        return 'The requested document was not found.';

      // Already exists
      case 'already-exists':
        return 'This resource already exists.';

      // Invalid argument
      case 'invalid-argument':
        return 'Invalid data provided. Please check your input.';

      // Deadline exceeded
      case 'deadline-exceeded':
        return 'Request took too long. Please try again.';

      // Resource exhausted
      case 'resource-exhausted':
        return 'Too many requests. Please wait a moment and try again.';

      // Unavailable
      case 'unavailable':
        return 'Service is temporarily unavailable. Please try again later.';

      // Data loss
      case 'data-loss':
        return 'An unrecoverable error occurred.';

      // Unauthenticated
      case 'unauthenticated':
        return 'Please log in to access this resource.';

      // Network error
      case 'network-request-failed':
      case 'offline':
        return 'No internet connection. Please check your network.';

      default:
        return e.message ?? 'A database error occurred.';
    }
  }

  // ===== FIREBASE CLOUD FUNCTIONS ERRORS =====
  static String handleCloudFunctionError(FirebaseFunctionsException e) {
    switch (e.code) {
      // Invalid argument
      case 'invalid-argument':
        return 'Invalid data provided. Please try again.';

      // Not found
      case 'not-found':
        return 'The requested resource was not found.';

      // Permission denied
      case 'permission-denied':
        return 'You do not have permission to perform this action.';

      // Resource exhausted
      case 'resource-exhausted':
        return 'Too many requests. Please wait and try again.';

      // Aborted
      case 'aborted':
        return 'Operation was aborted. Please try again.';

      // Unavailable
      case 'unavailable':
        return 'The service is temporarily unavailable.';

      // Internal
      case 'internal':
        return 'An internal error occurred. Please try again.';

      // Unauthenticated
      case 'unauthenticated':
        return 'Please log in to continue.';

      // Deadline exceeded
      case 'deadline-exceeded':
        return 'Request took too long. Please try again.';

      default:
        return e.message ?? 'An error occurred.';
    }
  }

  // ===== PLATFORM EXCEPTION (Google Sign-In, Facebook, etc.) =====
  static String handlePlatformError(PlatformException e) {
    final code = e.code;
    final msg = e.message ?? '';

    // Google Sign-In error codes
    if (code == 'network_error' || msg.contains('ApiException: 7')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (code == 'sign_in_canceled' || msg.contains('12501')) {
      return 'Sign-in was cancelled.';
    }
    if (code == 'sign_in_failed' || msg.contains('12500')) {
      return 'Sign-in failed. Please try again.';
    }
    if (msg.contains('10') || code == 'developer_error') {
      return 'Sign-in configuration error. Please contact support.';
    }

    // Facebook Sign-In
    if (code == 'CANCELLED') return 'Sign-in was cancelled.';
    if (code == 'FAILED') return 'Sign-in failed. Please try again.';

    return 'Sign-in failed. Please check your connection and try again.';
  }

  // ===== GENERIC ERROR HANDLER =====
  static String handleGenericError(dynamic error) {
    if (error is FirebaseAuthException) {
      return handleAuthError(error);
    } else if (error is FirebaseException) {
      return handleFirestoreError(error);
    } else if (error is FirebaseFunctionsException) {
      return handleCloudFunctionError(error);
    } else if (error is PlatformException) {
      return handlePlatformError(error);
    } else if (error is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    } else if (error is TimeoutException) {
      return 'Request timed out. Please check your connection and try again.';
    } else {
      final s = error.toString().toLowerCase();
      if (s.contains('network') || s.contains('socket') || s.contains('connection')
          || s.contains('internet') || s.contains('host lookup')
          || s.contains('failed host') || s.contains('no address')
          || s.contains('unreachable') || s.contains('offline')) {
        return 'No internet connection. Please check your network and try again.';
      }
      if (s.contains('timeout') || s.contains('timed out')) {
        return 'Request timed out. Please check your connection and try again.';
      }
      if (s.contains('permission') || s.contains('unauthorized') || s.contains('unauthenticated')) {
        return 'You don\'t have permission to do that. Please log in again.';
      }
      return 'Something went wrong. Please try again.';
    }
  }

  // ===== NETWORK ERROR DETECTION =====
  static bool isNetworkError(dynamic error) {
    if (error is FirebaseAuthException) {
      return error.code == 'network-request-failed';
    }
    if (error is FirebaseException) {
      return error.code == 'network-request-failed' || error.code == 'offline';
    }
    return error is SocketException || error is TimeoutException;
  }

  // ===== INPUT VALIDATION ERRORS =====
  static String? validateEmail(String email) {
    if (email.isEmpty) return 'Email is required';

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    return null; // Valid
  }

  static String? validatePassword(String password) {
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      return 'Password must contain at least one letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number';
    }
    return null; // Valid
  }

  static String? validateName(String name) {
    if (name.isEmpty) return 'Name is required';
    if (name.length < 2) return 'Name must be at least 2 characters';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      return 'Name can only contain letters and spaces';
    }
    return null; // Valid
  }

  static String? validatePhoneNumber(String phone) {
    if (phone.isEmpty) return 'Phone number is required';
    if (phone.length < 10) return 'Please enter a valid phone number';
    if (!RegExp(r'^\+?[0-9]{10,}$').hasMatch(phone)) {
      return 'Phone number is invalid';
    }
    return null; // Valid
  }
}
