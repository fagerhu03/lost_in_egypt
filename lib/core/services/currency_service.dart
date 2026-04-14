import 'package:flutter/foundation.dart';
import '../../feature/home/tabs/more/data/currency_repository.dart';

/// Converts EGP prices to the user's preferred currency.
/// Caches the EGP rate map in memory so tour cards don't re-fetch repeatedly.
class CurrencyService {
  static final CurrencyService instance = CurrencyService._();
  CurrencyService._();

  final CurrencyRepository _repo = CurrencyRepository();
  Map<String, double>? _egpRates;

  /// Returns the price converted from EGP to [toCurrency].
  /// Returns the original EGP amount if [toCurrency] is 'EGP' or on any error.
  Future<double> convertFromEGP(double amountEGP, String toCurrency) async {
    if (toCurrency == 'EGP') return amountEGP;
    try {
      _egpRates ??= await _repo.getRates('EGP');
      final rate = _egpRates![toCurrency];
      if (rate == null) return amountEGP;
      return amountEGP * rate;
    } catch (e) {
      debugPrint('CurrencyService: failed to convert – $e');
      return amountEGP;
    }
  }

  /// Call this when the user changes their preferred currency so the next
  /// conversion re-fetches rates if needed.
  void invalidateCache() => _egpRates = null;

  /// Formats a converted amount for display.
  /// Whole-unit currencies (JPY, KWD, etc.) show 0 decimals; others show 2.
  static String format(double amount, String currency) {
    final noDecimals = {'JPY', 'KWD', 'BHD', 'OMR'};
    final decimals = noDecimals.contains(currency) ? 0 : 2;
    return '$currency ${amount.toStringAsFixed(decimals)}';
  }
}
