import 'package:flutter/material.dart';
import 'data/currency_repository.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final CurrencyRepository _repository = CurrencyRepository();

  // Currencies list
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

  Future<void> _convert() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    setState(() => _isConverting = true);

    try {
      // Fetch rates (Repository handles API -> Local -> Throw)
      final rates = await _repository.getRates(_fromCurrency);
      final rate = rates[_toCurrency];

      if (rate != null) {
        if (mounted) {
          setState(() {
            _convertedAmount = amount * rate;
            _isConverting = false;
          });
        }
      } else {
        if (mounted) {
          _showError('Rate not available for $_toCurrency');
          setState(() => _isConverting = false);
        }
      }
    } catch (e) {
      if (mounted) {
        // Show specific error (e.g. "Failed to load... check internet")
        _showError(e.toString().replaceAll("Exception: ", ""));
        setState(() => _isConverting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
      _convertedAmount = null; // Reset result on swap
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBE8),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.40,
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
                          fontSize: 30,
                          fontFamily: "Marcellus",
                          color: Color(0x8C4D5420),
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
                        _convertedAmount = null;
                      }
                    },
                  ),

                  const SizedBox(height: 10),

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
                        _convertedAmount = null;
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
                      fillColor: const Color(0xFFFFFEF0),
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
                                setState(() {
                                  _convertedAmount = null;
                                });
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
                    onChanged: (_) => setState(() {
                      _convertedAmount = null; // Clear result when amount changes
                    }),
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
        color: const Color(0xFFFFFEF0),
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
