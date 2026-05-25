import 'package:flutter/material.dart';

/// Single source of truth for date-of-birth validation across the signup flow.
/// Used by [SignupScreen] (email/password) and [CompleteProfileScreen] (social
/// login DOB collection). Centralising this matters because the previous two
/// copies disagreed on leap years — `complete_profile_screen.dart` hand-rolled
/// a `monthsWith30Days` table while `signup_screen.dart` used
/// `DateUtils.getDaysInMonth`. The hand-rolled version accepted Feb 29 in
/// non-leap years.
class DobValidator {
  DobValidator._();

  static const int minAge = 16;

  static const List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// 1-based month index (1=Jan, 12=Dec). Returns 0 if [monthName] is not a
  /// known month — callers should treat 0 as invalid.
  static int monthIndex(String monthName) => months.indexOf(monthName) + 1;

  /// Day strings (`'1'` … `'31'`) valid for the selected month/year. Falls
  /// back to a 31-day list when month or year is unset so the picker still
  /// renders something useful. Handles leap years correctly via
  /// `DateUtils.getDaysInMonth`.
  static List<String> daysFor({String? monthName, String? year}) {
    if (monthName == null || year == null) {
      return List.generate(31, (i) => '${i + 1}');
    }
    final mIdx = monthIndex(monthName);
    final y = int.tryParse(year);
    if (mIdx == 0 || y == null) {
      return List.generate(31, (i) => '${i + 1}');
    }
    final days = DateUtils.getDaysInMonth(y, mIdx);
    return List.generate(days, (i) => '${i + 1}');
  }

  /// Validates a year/month/day triple and returns either the parsed DOB or an
  /// error string suitable for showing directly to the user. The error is
  /// `null` only when the DOB is fully valid and the age is ≥ [minAge].
  ///
  /// Validation order matches what users expect: presence → parse → calendar
  /// reality (Feb 30, Apr 31, …) → age gate.
  static ({DateTime? dob, String? error}) validate({
    required String? monthName,
    required String? day,
    required String? year,
  }) {
    if (monthName == null || day == null || year == null) {
      return (dob: null, error: 'Please select your date of birth.');
    }
    final mIdx = monthIndex(monthName);
    final d = int.tryParse(day);
    final y = int.tryParse(year);
    if (mIdx == 0 || d == null || y == null) {
      return (dob: null, error: 'Invalid date of birth.');
    }
    final maxDay = DateUtils.getDaysInMonth(y, mIdx);
    if (d < 1 || d > maxDay) {
      return (
        dob: null,
        error: '$monthName $y has only $maxDay days.',
      );
    }
    final dob = DateTime(y, mIdx, d);
    if (calculateAge(dob) < minAge) {
      return (
        dob: null,
        error: 'You must be at least $minAge years old to use this app.',
      );
    }
    return (dob: dob, error: null);
  }

  /// Year picker values, newest first. Defaults to the [minAge]-year offset so
  /// underage years aren't even pickable — UX matches the existing
  /// `signup_screen.dart` picker. Default span (85) covers ages 16–100.
  static List<String> yearsList({int span = 85, int offsetYears = minAge}) {
    final now = DateTime.now().year;
    return List.generate(span, (i) => '${now - offsetYears - i}');
  }

  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}
