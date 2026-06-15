import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/feature/home/tabs/more/data/currency_repository.dart';
import 'package:lost_in_egypt/core/utils/error_handler.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final CurrencyRepository _repository = CurrencyRepository();

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
    FocusManager.instance.primaryFocus?.unfocus();

    try {
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
        _showError(ErrorHandler.handleGenericError(e));
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
      _convertedAmount = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;
    final patternOpacity = isDark ? 0.1 : 0.4;

    final bg = theme.scaffoldBackgroundColor;
    final surface = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        image: DecorationImage(
          image: const AssetImage("assets/pattern_comp.png"),
          fit: BoxFit.cover,
          repeat: ImageRepeat.repeat,
          opacity: patternOpacity,
        ),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          size: 20.r,
                          color: textColor,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        "Currency Converter",
                        style: TextStyle(
                          fontSize: 30.sp,
                          fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                          color: textColor.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 40.h),

                  // From Currency
                  Text(
                    "From",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _buildCurrencyDropdown(
                    surfaceColor: surface,
                    textColor: textColor,
                    value: _fromCurrency,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _fromCurrency = value);
                        _convertedAmount = null;
                      }
                    },
                  ),

                  SizedBox(height: 10.h),

                  // Swap Button
                  Center(
                    child: Material(
                      color: primary,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.hardEdge,
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.1),
                      child: InkWell(
                        onTap: _swapCurrencies,
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 50.r,
                          height: 50.r,
                          child: Icon(
                            Icons.swap_vert,
                            color: Colors.white,
                            size: 24.r,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // To Currency
                  Text(
                    "To",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _buildCurrencyDropdown(
                    surfaceColor: surface,
                    textColor: textColor,
                    value: _toCurrency,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _toCurrency = value);
                        _convertedAmount = null;
                      }
                    },
                  ),

                  SizedBox(height: 40.h),

                  // Amount Input
                  Text(
                    "Amount",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: "Enter amount",
                      hintStyle: TextStyle(
                        color: textColor.withValues(alpha: 0.4),
                      ),
                      filled: true,
                      fillColor: surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 16.h,
                      ),
                      suffixIcon: _amountController.text.isNotEmpty
                          ? IconButton(
                        onPressed: () {
                          _amountController.clear();
                          setState(() {
                            _convertedAmount = null;
                          });
                        },
                        icon: Icon(
                          Icons.close,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      )
                          : null,
                    ),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16.sp,
                      fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _convert(),
                    onChanged: (_) => setState(() {
                      _convertedAmount = null;
                    }),
                  ),

                  SizedBox(height: 40.h),

                  // Convert Button
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: _isConverting ? null : _convert,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        disabledBackgroundColor: primary.withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        elevation: 4,
                      ),
                      child: _isConverting
                          ? SizedBox(
                        width: 24.w,
                        height: 24.h,
                        child: const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        "Convert",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 40.h),

                  // Result Section
                  if (_convertedAmount != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24.r),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
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
                              fontSize: 14.sp,
                              fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                              color: textColor.withValues(alpha: 0.6),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            "${_convertedAmount!.toStringAsFixed(2)} $_toCurrency",
                            style: TextStyle(
                              fontSize: 28.sp,
                              fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            "${_amountController.text} $_fromCurrency",
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                              color: textColor.withValues(alpha: 0.5),
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
    ));
  }

  Widget _buildCurrencyDropdown({
    required String value,
    required Function(String?) onChanged,
    required Color surfaceColor,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
        borderRadius: BorderRadius.circular(20.r),
        items: currencies.map((currency) {
          return DropdownMenuItem<String>(
            value: currency,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Text(
                currency,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                  color: textColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
