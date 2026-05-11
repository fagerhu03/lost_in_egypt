import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lost_in_egypt/core/services/currency_controller.dart';
import 'package:lost_in_egypt/core/services/currency_service.dart';
import '../../domain/entities/tour_entity.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/usecases/book_tour_usecase.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/di/service_locator.dart';
import '../../data/datasources/paymob_api_service.dart';
import '../../../../feature/home/notification/domain/services/local_notification_service.dart';
import 'booking_history_screen.dart';
import '../../../../core/services/recommendation_service.dart';
import '../../../../core/utils/error_handler.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final TourEntity tour;

  const BookingConfirmationScreen({Key? key, required this.tour}) : super(key: key);

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final Uuid _uuid = const Uuid();
  bool _isLoading = false;
  String _selectedPaymentMethod = 'card';
  final TextEditingController _walletPhoneController = TextEditingController();
  int _quantity = 1;

  double get _totalPrice => widget.tour.price * _quantity;

  @override
  void dispose() {
    _walletPhoneController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please log in to book.', isError: true);
      return;
    }

    if (_selectedPaymentMethod == 'wallet') {
      final phone = _walletPhoneController.text.trim();
      final egyptianMobileRegex = RegExp(r'^01[0125][0-9]{8}$');
      if (!egyptianMobileRegex.hasMatch(phone)) {
        _showSnackBar('Please enter a valid Egyptian mobile number (e.g. 01XXXXXXXXX).', isError: true);
        return;
      }
    }

    // Pre-check capacity before opening payment gateway
    try {
      final tourDoc = await FirebaseFirestore.instance
          .collection('tours').doc(widget.tour.id).get();
      final currentCap = (tourDoc.data()?['maxAttendees'] as num?)?.toInt() ?? 0;
      if (currentCap < _quantity) {
        if (currentCap <= 0) {
          _showSnackBar('Sorry, this tour is now fully booked.', isError: true);
        } else {
          _showSnackBar(
            'Only $currentCap seat${currentCap == 1 ? '' : 's'} remaining. Please reduce your selection.',
            isError: true,
          );
          if (mounted) setState(() => _quantity = currentCap);
        }
        return;
      }
    } catch (_) {}

    setState(() => _isLoading = true);

    try {
      switch (_selectedPaymentMethod) {
        case 'card':
        case 'apple_pay':
          final response = await PaymobPaymentService.instance.payWithCard(
            context: context,
            amountEGP: _totalPrice,
          );
          if (response != null && (response.success ||
                response.responseCode == 'APPROVED' ||
                response.responseCode == '00' ||
                (response.transactionID != null && response.transactionID!.isNotEmpty))) {
            await _onPaymentSuccess(response.transactionID ?? _uuid.v4(), user.uid);
          } else {
            if (mounted) {
              setState(() => _isLoading = false);
              _showSnackBar(response?.message ?? 'Payment was cancelled or failed.', isError: true);
            }
          }
          break;

        case 'wallet':
          final response = await PaymobPaymentService.instance.payWithWallet(
            context: context,
            amountEGP: _totalPrice,
            phoneNumber: _walletPhoneController.text.trim(),
          );
          if (response != null && (response.success ||
                response.responseCode == 'APPROVED' ||
                response.responseCode == '00' ||
                (response.transactionID != null && response.transactionID!.isNotEmpty))) {
            await _onPaymentSuccess(response.transactionID ?? _uuid.v4(), user.uid);
          } else {
            if (mounted) {
              setState(() => _isLoading = false);
              _showSnackBar(response?.message ?? 'Wallet payment failed.', isError: true);
            }
          }
          break;

        case 'kiosk':
          // Fawry/Kiosk generates a reference number — user pays at a kiosk later
          _showSnackBar('Kiosk payment coming soon!');
          setState(() => _isLoading = false);
          break;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(ErrorHandler.handleGenericError(e), isError: true);
      }
    }
  }

  Future<void> _onPaymentSuccess(String transactionId, String userId) async {
    final booking = BookingEntity(
      id: _uuid.v4(),
      tourId: widget.tour.id,
      userId: userId,
      guideId: widget.tour.guideId,
      status: 'confirmed',
      paymentReference: transactionId,
      paymentStatus: 'paid',
      date: widget.tour.meetingTime,
      createdAt: DateTime.now(),
      quantity: _quantity,
      totalAmountEGP: _totalPrice,
    );

    final useCase = sl<BookTourUseCase>();
    final result = await useCase(booking);

    // Send notification to the guide
    _notifyGuide(userId);
    // Notify tourist + schedule reminder
    _notifyTouristAndScheduleReminder(userId);

    if (mounted) {
      setState(() => _isLoading = false);
      result.fold(
        (l) => _showSnackBar('Booking Error: ${l.message}', isError: true),
        (r) {
          RecommendationService.recordSignal(
            placeId: widget.tour.id,
            placeName: widget.tour.title,
            types: ['tourist_attraction'],
            tags: ['cultural', 'adventure'],
            signalType: 'booking',
            source: 'booking',
          );
          _showSuccessDialog();
        },
      );
    }
  }

  Future<void> _notifyTouristAndScheduleReminder(String touristId) async {
    try {
      // In-app notification for the tourist
      await FirebaseFirestore.instance
          .collection('users')
          .doc(touristId)
          .collection('notifications')
          .add({
        'recipientId': touristId,
        'senderId': 'system',
        'senderName': 'Lost in Egypt',
        'senderAvatar': '',
        'title': 'Booking Confirmed!',
        'message': 'Your spot on "${widget.tour.title}" is confirmed. See you there!',
        'type': 'booking_confirmed',
        'deepLinkTargetId': widget.tour.id,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Schedule a local reminder 1 hour before the tour
      final reminderTime = widget.tour.meetingTime.subtract(const Duration(hours: 1));
      await LocalNotificationService().scheduleNotification(
        id: widget.tour.id.hashCode.abs() % 100000,
        title: 'Tour starting soon!',
        body: '"${widget.tour.title}" starts in 1 hour. Head to ${widget.tour.meetingLocationName}.',
        scheduledDate: reminderTime,
        payload: widget.tour.id,
      );
    } catch (e) {
      debugPrint('Error notifying tourist: $e');
    }
  }

  Future<void> _notifyGuide(String travelerId) async {
    try {
      final travelerDoc = await FirebaseFirestore.instance.collection('users').doc(travelerId).get();
      final travelerData = travelerDoc.data();
      final travelerName = travelerData?['firstName'] ?? 'A traveler';
      final travelerAvatar = travelerData?['profileImageUrl'] ?? '';

      final notifRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.tour.guideId)
          .collection('notifications')
          .doc();

      await notifRef.set({
        'recipientId': widget.tour.guideId,
        'senderId': travelerId,
        'senderName': travelerName,
        'senderAvatar': travelerAvatar,
        'title': 'New Booking!',
        'message': '$travelerName booked your tour "${widget.tour.title}"',
        'type': 'booking',
        'deepLinkTargetId': widget.tour.id,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error notifying guide: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFC79A00).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Color(0xFFC79A00), size: 64),
            ),
            const SizedBox(height: 16),
            const Text('Booking Confirmed!', textAlign: TextAlign.center),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your spot on "${widget.tour.title}" is reserved!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<String>(
              valueListenable: CurrencyController.currency,
              builder: (context, currency, _) {
                return FutureBuilder<double>(
                  future: CurrencyService.instance.convertFromEGP(_totalPrice, currency),
                  builder: (context, snap) {
                    final label = snap.hasData
                        ? CurrencyService.format(snap.data!, currency)
                        : snap.hasError
                            ? 'EGP ${_totalPrice.toStringAsFixed(0)} ΓÜá'
                            : 'EGP ${_totalPrice.toStringAsFixed(0)}';
                    return Text(
                      '$label paid successfully.',
                      style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55)),
                    );
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC79A00),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BookingHistoryScreen()),
                  );
                },
                child: const Text('View My Bookings',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
            children: [
              // ── Order Summary ──
              _buildSectionTitle('Order Summary'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(theme, isDark),
                child: Column(
                  children: [
                    // Tour info
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: widget.tour.images.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: widget.tour.images.first, 
                                  width: 60, 
                                  height: 60, 
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(width: 60, height: 60, color: Theme.of(context).colorScheme.surfaceContainerHighest),
                                  errorWidget: (context, url, err) => Container(width: 60, height: 60, color: Theme.of(context).colorScheme.surfaceContainerHighest, child: const Icon(Icons.landscape)),
                                )
                              : Container(width: 60, height: 60, color: Theme.of(context).colorScheme.surfaceContainerHighest, child: const Icon(Icons.landscape)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.tour.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(
                                widget.tour.meetingLocationName,
                                style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // Quantity selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Guests', style: TextStyle(fontSize: 15)),
                        Row(
                          children: [
                            _quantityButton(Icons.remove, () {
                              if (_quantity > 1) setState(() => _quantity--);
                            }),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                            _quantityButton(Icons.add, () {
                              if (_quantity < widget.tour.maxAttendees) setState(() => _quantity++);
                            }),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // Price breakdown
                    ValueListenableBuilder<String>(
                      valueListenable: CurrencyController.currency,
                      builder: (context, currency, _) {
                        return FutureBuilder<double>(
                          future: CurrencyService.instance.convertFromEGP(widget.tour.price, currency),
                          builder: (context, snap) {
                            final unitLabel = snap.hasData
                                ? CurrencyService.format(snap.data!, currency)
                                : snap.hasError
                                    ? 'EGP ${widget.tour.price.toStringAsFixed(0)} ΓÜá'
                                    : 'EGP ${widget.tour.price.toStringAsFixed(0)}';
                            final totalLabel = snap.hasData
                                ? CurrencyService.format(snap.data! * _quantity, currency)
                                : snap.hasError
                                    ? 'EGP ${_totalPrice.toStringAsFixed(0)} ΓÜá'
                                    : 'EGP ${_totalPrice.toStringAsFixed(0)}';
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('$_quantity × $unitLabel'),
                                Text(
                                  totalLabel,
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primary),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Payment Method ──
              _buildSectionTitle('Payment Method'),
              const SizedBox(height: 12),
              _buildPaymentOption(
                title: 'Credit / Debit Card',
                subtitle: 'Visa, Mastercard, Meeza',
                icon: Icons.credit_card,
                value: 'card',
                theme: theme,
              ),
              _buildPaymentOption(
                title: 'Mobile Wallet',
                subtitle: 'Vodafone Cash, Orange, Etisalat',
                icon: Icons.phone_android,
                value: 'wallet',
                theme: theme,
              ),
              _buildPaymentOption(
                title: 'Apple Pay',
                subtitle: 'iOS only • Coming soon',
                icon: Icons.apple,
                value: 'apple_pay',
                theme: theme,
                enabled: false, // Enable when Apple Pay integration is live
              ),
              _buildPaymentOption(
                title: 'Fawry / Kiosk',
                subtitle: 'Pay at any 172,000+ Fawry outlets',
                icon: Icons.receipt_long,
                value: 'kiosk',
                theme: theme,
                enabled: false, // Enable when kiosk integration is created
              ),

              // Wallet phone input
              if (_selectedPaymentMethod == 'wallet') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _walletPhoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Wallet Phone Number',
                    hintText: '01XXXXXXXXX',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── Security Badge ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: primary.withOpacity(isDark ? 0.08 : 0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_user, color: primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Payments are processed securely by Paymob. Your card details are never stored locally.',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Processing payment...', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<String>(
                valueListenable: CurrencyController.currency,
                builder: (context, currency, _) {
                  return FutureBuilder<double>(
                    future: CurrencyService.instance.convertFromEGP(_totalPrice, currency),
                    builder: (context, snap) {
                      final displayLabel = snap.hasData
                          ? CurrencyService.format(snap.data!, currency)
                          : snap.hasError
                              ? 'EGP ${_totalPrice.toStringAsFixed(0)} ΓÜá'
                              : 'EGP ${_totalPrice.toStringAsFixed(0)}';
                      final showEgpNote = currency != 'EGP' && snap.hasData;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total', style: TextStyle(fontSize: 16)),
                              Text(
                                displayLabel,
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primary),
                              ),
                            ],
                          ),
                          if (showEgpNote)
                            Text(
                              'Charged as EGP ${_totalPrice.toStringAsFixed(0)} via Paymob',
                              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _processPayment,
                  icon: const Icon(Icons.lock),
                  label: const Text('Pay Securely', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
  }

  BoxDecoration _cardDecoration(ThemeData theme, bool isDark) {
    return BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
      boxShadow: [
        BoxShadow(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required ThemeData theme,
    bool enabled = true,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.08),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: RadioListTile<String>(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : theme.colorScheme.onSurface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: isSelected ? theme.colorScheme.primary : Colors.grey, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: theme.colorScheme.onSurface)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  ],
                ),
              ),
            ],
          ),
          value: value,
          groupValue: _selectedPaymentMethod,
          activeColor: theme.colorScheme.primary,
          onChanged: enabled
              ? (val) {
                  if (val != null) setState(() => _selectedPaymentMethod = val);
                }
              : null,
        ),
      ),
    );
  }
}
