import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/tour_entity.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/usecases/book_tour_usecase.dart';
import '../bloc/explorer_tours_cubit.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/di/service_locator.dart';
import '../../data/datasources/paymob_api_service.dart';

// Note: A real app would embed a WebView here via webview_flutter. 
// For structural completeness, we provide the UI flow and URL generation logic.

class BookingConfirmationScreen extends StatefulWidget {
  final TourEntity tour;

  const BookingConfirmationScreen({Key? key, required this.tour}) : super(key: key);

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final PaymobApiService _paymobService = PaymobApiService();
  final Uuid _uuid = const Uuid();
  bool _isLoading = false;
  String _selectedPaymentMethod = 'card'; // 'card' or 'wallet' or 'fawry'

  Future<void> _processPayment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to book.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final orderId = _uuid.v4().substring(0, 16); // Paymob requires shorter order IDs

      // 1. Generate Payment Token via Paymob
      final paymentKey = await _paymobService.generatePaymentToken(
        price: widget.tour.price,
        currency: 'EGP', // Or map from tour
        orderId: orderId,
        isMobileWallet: _selectedPaymentMethod == 'wallet',
        billingData: {
          "email": user.email ?? "tourist@test.com",
          "first_name": "Tourist",
          "last_name": "User",
          "phone_number": "+201111111111",
          "city": "Cairo",
          "country": "EG",
          "street": "123 Street",
        },
      );

      // 2. Here we would launch a WebView targeting:
      // https://accept.paymob.com/api/acceptance/iframes/{{IFRAME_ID}}?payment_token=$paymentKey
      // For this workflow, we will simulate a successful payment return.
      
      await _simulateSuccessfulPaymentReturn(orderId, user.uid);

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _simulateSuccessfulPaymentReturn(String orderId, String userId) async {
    final booking = BookingEntity(
      id: _uuid.v4(),
      tourId: widget.tour.id,
      userId: userId,
      guideId: widget.tour.guideId,
      status: 'confirmed',
      paymentReference: orderId,
      paymentStatus: 'paid',
      date: widget.tour.meetingTime,
      createdAt: DateTime.now(),
    );

    final useCase = sl<BookTourUseCase>();
    final result = await useCase(booking);

    if (mounted) {
      setState(() => _isLoading = false);
      result.fold(
        (l) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking Error: ${l.message}')));
        },
        (r) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Text('🎉 Booking Confirmed!'),
              content: const Text('Your payment was successful and your spot is reserved.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Back to Home'),
                )
              ],
            ),
          );
        }
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Order Summary
              const Text('Order Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(widget.tour.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                        Text('\$${widget.tour.price.toStringAsFixed(2)}'),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total (EGP equivalent)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('EGP ${(widget.tour.price * 50).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.primary)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              const Text('Payment Method (Paymob)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              _buildPaymentOption('Credit/Debit Card', Icons.credit_card, 'card', theme),
              _buildPaymentOption('Mobile Wallet (e.g., Vodafone Cash)', Icons.phone_android, 'wallet', theme),
              _buildPaymentOption('InstaPay / Fawry Kiosk', Icons.receipt_long, 'fawry', theme),

            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            )
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _isLoading ? null : _processPayment,
          child: const Text('Pay Securely', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon, String value, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedPaymentMethod == value ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.1),
          width: _selectedPaymentMethod == value ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        title: Row(
          children: [
            Icon(icon, color: _selectedPaymentMethod == value ? theme.colorScheme.primary : Colors.grey),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        value: value,
        groupValue: _selectedPaymentMethod,
        activeColor: theme.colorScheme.primary,
        onChanged: (val) {
          if (val != null) setState(() => _selectedPaymentMethod = val);
        },
      ),
    );
  }
}
