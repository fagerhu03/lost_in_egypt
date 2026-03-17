import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_paymob/flutter_paymob.dart';
import 'package:flutter_paymob/paymob_response.dart';

/// Thin wrapper around the flutter_paymob SDK.
/// Provides named methods for each payment type.
class PaymobPaymentService {
  PaymobPaymentService._();
  static final PaymobPaymentService instance = PaymobPaymentService._();

  /// Pay via credit/debit card – opens Paymob's embedded WebView.
  Future<PaymentPaymobResponse?> payWithCard({
    required BuildContext context,
    required double amountEGP,
    String currency = 'EGP',
  }) async {
    final completer = Completer<PaymentPaymobResponse?>();
    await FlutterPaymob.instance.payWithCard(
      context: context,
      currency: currency,
      amount: amountEGP,
      onPayment: (response) {
        completer.complete(response);
      },
    );
    // If WebView was closed without completing, return null
    if (!completer.isCompleted) completer.complete(null);
    return completer.future;
  }

  /// Pay via mobile wallet (Vodafone Cash, Orange, etc.)
  Future<PaymentPaymobResponse?> payWithWallet({
    required BuildContext context,
    required double amountEGP,
    required String phoneNumber,
    String currency = 'EGP',
  }) async {
    final completer = Completer<PaymentPaymobResponse?>();
    await FlutterPaymob.instance.payWithWallet(
      context: context,
      currency: currency,
      amount: amountEGP,
      number: phoneNumber,
      onPayment: (response) {
        completer.complete(response);
      },
    );
    if (!completer.isCompleted) completer.complete(null);
    return completer.future;
  }
}
