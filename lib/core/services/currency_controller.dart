import 'package:flutter/foundation.dart';

class CurrencyController {
  static final ValueNotifier<String> currency = ValueNotifier<String>('EGP');

  static void setCurrency(String code) {
    currency.value = code;
  }
}
