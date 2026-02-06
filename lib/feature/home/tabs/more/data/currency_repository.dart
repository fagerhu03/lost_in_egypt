import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyRepository {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest/';
  
  // Cache to store rates in memory: baseCurrency -> {currency: rate}
  final Map<String, Map<String, double>> _memCache = {};

  Future<Map<String, double>> getRates(String baseCurrency) async {
    // 1. Try to fetch from API
    try {
      final response = await http.get(Uri.parse('$_baseUrl$baseCurrency'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final Map<String, dynamic> ratesDynamic = data['rates'];
        
        // Convert to Map<String, double>
        final Map<String, double> rates = {};
        ratesDynamic.forEach((key, value) {
          if (value is num) {
            rates[key] = value.toDouble();
          }
        });

        // Update memory cache
        _memCache[baseCurrency] = rates;
        
        // Update local storage
        await _saveRatesLocally(baseCurrency, rates);
        
        return rates;
      }
    } catch (e) {
      debugPrint('Network error fetching rates: $e');
      // Fall through to local storage
    }

    // 2. Try to load from local storage
    try {
      final localRates = await _getLocalRates(baseCurrency);
      if (localRates != null) {
        _memCache[baseCurrency] = localRates;
        return localRates;
      }
    } catch (e) {
       debugPrint('Error reading local rates: $e');
    }

    // 3. If everything fails, throw exception (UI handles it)
    throw Exception('Failed to load exchange rates. Please check your internet connection.');
  }

  Future<void> _saveRatesLocally(String baseCurrency, Map<String, double> rates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(rates);
      await prefs.setString('currency_rates_$baseCurrency', jsonString);
    } catch (e) {
      debugPrint('Error saving rates locally: $e');
    }
  }

  Future<Map<String, double>?> _getLocalRates(String baseCurrency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('currency_rates_$baseCurrency');
      
      if (jsonString != null) {
        final Map<String, dynamic> ratesDynamic = json.decode(jsonString);
        final Map<String, double> rates = {};
        ratesDynamic.forEach((key, value) {
          if (value is num) {
            rates[key] = value.toDouble();
          }
        });
        return rates;
      }
    } catch (e) {
      debugPrint('Error parsing local rates: $e');
    }
    return null;
  }
}
