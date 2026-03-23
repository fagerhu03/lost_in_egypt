import 'package:flutter/material.dart';
import 'package:flutter_paymob/flutter_paymob.dart';
import 'package:flutter_paymob/paymob_response.dart';

/// Thin wrapper around the flutter_paymob SDK.
/// Provides named methods for each payment type.
///
/// NOTE: We use the direct return value of payWithCard / payWithWallet
/// (which comes from Navigator.pop inside the WebView) rather than the
/// onPayment callback. The package wraps onPayment in addPostFrameCallback,
/// which causes it to fire *after* the await resolves — making any Completer
/// pattern race-prone. The Navigator.pop return value is immediate and reliable.
class PaymobPaymentService {
  PaymobPaymentService._();
  static final PaymobPaymentService instance = PaymobPaymentService._();

  /// Pay via credit/debit card – opens Paymob's embedded WebView.
  Future<PaymentPaymobResponse?> payWithCard({
    required BuildContext context,
    required double amountEGP,
    String currency = 'EGP',
  }) async {
    final result = await FlutterPaymob.instance.payWithCard(
      context: context,
      currency: currency,
      amount: amountEGP,
    );
    return result as PaymentPaymobResponse?;
  }

  /// Pay via mobile wallet (Vodafone Cash, Orange, etc.)
  Future<PaymentPaymobResponse?> payWithWallet({
    required BuildContext context,
    required double amountEGP,
    required String phoneNumber,
    String currency = 'EGP',
  }) async {
    final result = await FlutterPaymob.instance.payWithWallet(
      context: context,
      currency: currency,
      amount: amountEGP,
      number: phoneNumber,
    );
    return result as PaymentPaymobResponse?;
  }
}
