import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymobApiService {
  static const String baseUrl = 'https://accept.paymob.com/api';
  
  final String apiKey = dotenv.env['PAYMOB_API_KEY'] ?? '';
  final String integrationIdCard = dotenv.env['PAYMOB_INTEGRATION_ID_CARD'] ?? '';
  final String integrationIdMobileWallet = dotenv.env['PAYMOB_INTEGRATION_ID_WALLET'] ?? '';

  Future<String> _getAuthenticationToken() async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/tokens'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'api_key': apiKey}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['token'];
    } else {
      throw Exception('Failed to authenticate with Paymob');
    }
  }

  Future<String> _registerOrder({
    required String authToken,
    required String amountCents,
    required String currency,
    required String merchantOrderId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ecommerce/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "auth_token": authToken,
        "delivery_needed": "false",
        "amount_cents": amountCents,
        "currency": currency,
        "merchant_order_id": merchantOrderId,
        "items": []
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['id'].toString();
    } else {
      throw Exception('Failed to register order with Paymob');
    }
  }

  Future<String> _getPaymentKey({
    required String authToken,
    required String orderId,
    required String amountCents,
    required String currency,
    required String integrationId,
    required Map<String, dynamic> billingData,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/acceptance/payment_keys'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "auth_token": authToken,
        "amount_cents": amountCents,
        "expiration": 3600,
        "order_id": orderId,
        "billing_data": billingData,
        "currency": currency,
        "integration_id": integrationId
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['token'];
    } else {
      throw Exception('Failed to obtain payment key from Paymob');
    }
  }

  // Exposed Entrypoint for UI logic
  Future<String> generatePaymentToken({
    required double price,
    required String currency,
    required String orderId,
    required Map<String, dynamic> billingData,
    required bool isMobileWallet,
  }) async {
    try {
      final authToken = await _getAuthenticationToken();
      final amountCents = (price * 100).toInt().toString();

      final paymobOrderId = await _registerOrder(
        authToken: authToken,
        amountCents: amountCents,
        currency: currency,
        merchantOrderId: orderId,
      );

      final integrationId = isMobileWallet ? integrationIdMobileWallet : integrationIdCard;

      final paymentKey = await _getPaymentKey(
        authToken: authToken,
        orderId: paymobOrderId,
        amountCents: amountCents,
        currency: currency,
        integrationId: integrationId,
        billingData: billingData,
      );

      return paymentKey;
    } catch (e) {
      throw Exception('Payment Initialization Error: $e');
    }
  }
}
