import 'package:flutter/material.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  // Exchange rates (relative to USD)
  static const Map<String, double> exchangeRates = {
    'USD': 1.0,
    'EUR': 0.92,
    'GBP': 0.79,
    'EGP': 30.5,
    'SAR': 3.75,
    'AED': 3.67,
    'JOD': 0.71,
    'QAR': 3.64,
    'KWD': 0.31,
    'OMR': 0.39,
    'BHD': 0.38,
    'JPY': 149.50,
    'INR': 83.12,
    'AUD': 1.54,
    'CAD': 1.36,
    'CHF': 0.88,
  };

  final List<String> currencies = [
    'USD',
    'EUR',
    'GBP',
    'EGP',
    'SAR',
    'AED',
    'JOD',
    'QAR',
    'KWD',
    'OMR',
    'BHD',
    'JPY',
    'INR',
    'AUD',
    'CAD',
    'CHF',
  ];

  String _fromCurrency = 'USD';
  String _toCurrency = 'EGP';
  double? _convertedAmount;
  final TextEditingController _amountController = TextEditingController();
  bool _isConverting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _convert() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    setState(() => _isConverting = true);

    // Simulate API delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final fromRate = exchangeRates[_fromCurrency] ?? 1.0;
        final toRate = exchangeRates[_toCurrency] ?? 1.0;
        final result = (amount / fromRate) * toRate;

        setState(() {
          _convertedAmount = result;
          _isConverting = false;
        });
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
      if (_convertedAmount != null) {
        _convert();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2E6),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
              child: Image.asset(
                "assets/pattern_comp.png",
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeat,
                errorBuilder: (c, o, s) => Container(),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 20,
                          color: Color(0xFF714611),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Currency Converter",
                        style: TextStyle(
                          fontSize: 24,
                          fontFamily: "Marcellus",
                          color: Color(0xFF714611),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // From Currency
                  Text(
                    "From",
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: "Marcellus",
                      color: const Color(0xFF714611).withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCurrencyDropdown(
                    value: _fromCurrency,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _fromCurrency = value);
                      }
                    },
                  ),

                  const SizedBox(height: 25),

                  // Swap Button
                  Center(
                    child: GestureDetector(
                      onTap: _swapCurrencies,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC79A00),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.swap_vert,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // To Currency
                  Text(
                    "To",
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: "Marcellus",
                      color: const Color(0xFF714611).withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCurrencyDropdown(
                    value: _toCurrency,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _toCurrency = value);
                      }
                    },
                  ),

                  const SizedBox(height: 40),

                  // Amount Input
                  Text(
                    "Amount",
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: "Marcellus",
                      color: const Color(0xFF714611).withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: "Enter amount",
                      hintStyle: TextStyle(
                        color: const Color(0xFF714611).withOpacity(0.4),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFBF8F2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      suffixIcon: _amountController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _amountController.clear();
                                setState(() {});
                              },
                              child: Icon(
                                Icons.close,
                                color: const Color(0xFF714611).withOpacity(0.5),
                              ),
                            )
                          : null,
                    ),
                    style: const TextStyle(
                      color: Color(0xFF714611),
                      fontSize: 16,
                      fontFamily: "Marcellus",
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 40),

                  // Convert Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isConverting ? null : _convert,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC79A00),
                        disabledBackgroundColor: const Color(
                          0xFFC79A00,
                        ).withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 4,
                      ),
                      child: _isConverting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Convert",
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: "Marcellus",
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Result Section
                  if (_convertedAmount != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF8F2),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Result",
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: "Marcellus",
                              color: const Color(0xFF714611).withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "${_convertedAmount!.toStringAsFixed(2)} $_toCurrency",
                            style: const TextStyle(
                              fontSize: 28,
                              fontFamily: "Marcellus",
                              color: Color(0xFF714611),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "${_amountController.text} $_fromCurrency",
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: "Marcellus",
                              color: const Color(0xFF714611).withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyDropdown({
    required String value,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        isExpanded: true,
        underline: const SizedBox(),
        borderRadius: BorderRadius.circular(20),
        items: currencies.map((currency) {
          return DropdownMenuItem<String>(
            value: currency,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                currency,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: "Marcellus",
                  color: Color(0xFF714611),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
