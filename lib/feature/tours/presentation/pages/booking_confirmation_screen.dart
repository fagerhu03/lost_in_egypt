import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';
import 'package:lost_in_egypt/core/services/currency_controller.dart';
import 'package:lost_in_egypt/core/services/currency_service.dart';
import '../../domain/entities/tour_entity.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/usecases/book_tour_usecase.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/widgets/shimmer_image.dart';
import '../../../../core/di/service_locator.dart';
import '../../data/datasources/paymob_api_service.dart';
import '../../../../feature/home/notification/domain/services/local_notification_service.dart';
import 'booking_history_screen.dart';
import 'tour_detail_screen.dart';
import '../../../../core/services/recommendation_mappings.dart';
import '../../../../core/services/recommendation_service.dart';
import '../../../../core/services/weather_controller.dart';
import '../../../../core/utils/error_handler.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final TourEntity tour;

  const BookingConfirmationScreen({super.key, required this.tour});

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final Uuid _uuid = const Uuid();
  bool _isLoading = false;
  String _selectedPaymentMethod = 'card';
  final TextEditingController _walletPhoneController = TextEditingController();
  int _quantity = 1;

  // "Because you booked X, you might enjoy these tours" — pulled once on
  // screen open. Same engine call as TourDetailScreen's similar tours.
  List<TourEntity> _similarTours = [];
  bool _loadingSimilar = true;

  double get _totalPrice => widget.tour.price * _quantity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSimilarTours());
  }

  Future<void> _loadSimilarTours() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('tours')
          .where('isArchived', isEqualTo: false)
          .limit(30)
          .get();
      final siblings = snap.docs
          .where((d) => d.id != widget.tour.id)
          .map((d) {
            final m = d.data();
            return TourEntity(
              id: d.id,
              guideId: m['guideId'] as String? ?? '',
              title: m['title'] as String? ?? '',
              description: m['description'] as String? ?? '',
              destinations: List<String>.from(m['destinations'] ?? []),
              price: (m['price'] as num?)?.toDouble() ?? 0,
              meetingLatitude: (m['meetingLatitude'] as num?)?.toDouble() ?? 0,
              meetingLongitude: (m['meetingLongitude'] as num?)?.toDouble() ?? 0,
              meetingTime: (m['meetingTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
              frequency: m['frequency'] as String? ?? '',
              meetingLocationName: m['meetingLocationName'] as String? ?? '',
              images: List<String>.from(m['images'] ?? []),
              maxAttendees: (m['maxAttendees'] as num?)?.toInt() ?? 0,
              rating: (m['rating'] as num?)?.toDouble() ?? 0,
              reviewCount: (m['reviewCount'] as num?)?.toInt() ?? 0,
              createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          })
          .toList();
      if (siblings.isEmpty) {
        if (mounted) setState(() => _loadingSimilar = false);
        return;
      }

      final candidates = siblings.map((t) {
        final inferred = RecommendationMappings.inferKeysFromText(
          '${t.title} ${t.destinations.join(' ')} ${t.description}',
        );
        return <String, dynamic>{
          'placeId': t.id,
          'name': t.title,
          'types': inferred['types']!,
          'tags': inferred['tags']!,
          'rating': t.rating,
          'userRatingCount': t.reviewCount,
          'lat': t.meetingLatitude,
          'lng': t.meetingLongitude,
        };
      }).toList();

      final result = await RecommendationService.recommendPlaces(
        candidates: candidates,
        context: 'similar',
        limit: 3,
        excludeSeen: false, // small tour pool — keep all candidates visible
        weather: WeatherController.weather.value,
      );
      if (!mounted) return;
      if (result == null || result.recommendations.isEmpty) {
        setState(() => _loadingSimilar = false);
        return;
      }
      final idToTour = {for (final t in siblings) t.id: t};
      final ordered = result.recommendations
          .map((r) => idToTour[r.placeId])
          .whereType<TourEntity>()
          .toList();
      setState(() {
        _similarTours = ordered;
        _loadingSimilar = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSimilar = false);
    }
  }

  @override
  void dispose() {
    _walletPhoneController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    final l10n = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar(l10n.bookingLoginRequired, isError: true);
      return;
    }

    if (_selectedPaymentMethod == 'wallet') {
      final phone = _walletPhoneController.text.trim();
      final egyptianMobileRegex = RegExp(r'^01[0125][0-9]{8}$');
      if (!egyptianMobileRegex.hasMatch(phone)) {
        _showSnackBar(l10n.bookingInvalidWallet, isError: true);
        return;
      }
    }

    // Pre-check capacity before opening payment gateway
    try {
      final tourDoc = await FirebaseFirestore.instance
          .collection('tours').doc(widget.tour.id).get();
      final currentCap = (tourDoc.data()?['maxAttendees'] as num?)?.toInt() ?? 0;
      if (!context.mounted) return;
      if (currentCap < _quantity) {
        if (currentCap <= 0) {
          _showSnackBar(l10n.bookingFullyBooked, isError: true);
        } else {
          _showSnackBar(
            l10n.bookingSeatsRemaining(currentCap),
            isError: true,
          );
          if (mounted) setState(() => _quantity = currentCap);
        }
        return;
      }
    } catch (_) {}

    if (!mounted) return;

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
              _showSnackBar(response?.message ?? l10n.bookingPaymentFailed, isError: true);
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
              _showSnackBar(response?.message ?? l10n.bookingWalletFailed, isError: true);
            }
          }
          break;

        case 'kiosk':
          // Fawry/Kiosk generates a reference number — user pays at a kiosk later
          _showSnackBar(l10n.bookingKioskSoon);
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
      final l10n = AppLocalizations.of(context);
      setState(() => _isLoading = false);
      result.fold(
        (l) => _showSnackBar(l10n.bookingErrorPrefix(l.message), isError: true),
        (r) {
          final inferred = RecommendationMappings.inferKeysFromText(
            '${widget.tour.title} ${widget.tour.destinations.join(' ')} ${widget.tour.description}',
          );
          RecommendationService.recordSignal(
            placeId: widget.tour.id,
            placeName: widget.tour.title,
            types: inferred['types']!,
            tags: inferred['tags']!,
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
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFFC79A00).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: const Color(0xFFC79A00), size: 64.r),
            ),
            SizedBox(height: 16.h),
            Text(l10n.bookingConfirmedTitle, textAlign: TextAlign.center),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.bookingReservedBody(widget.tour.title),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15.sp),
            ),
            SizedBox(height: 8.h),
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
                      l10n.bookingPaidSuccess(label),
                      style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BookingHistoryScreen()),
                  );
                },
                child: Text(l10n.bookingViewMyBookings,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 8.h),
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: Text(l10n.bookingBackHome),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bookingCheckoutTitle),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 160.h),
            children: [
              // ── Order Summary ──
              _buildSectionTitle(l10n.bookingOrderSummary),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: _cardDecoration(theme, isDark),
                child: Column(
                  children: [
                    // Tour info
                    Row(
                      children: [
                        ShimmerImage(
                          url: widget.tour.images.isNotEmpty
                              ? widget.tour.images.first
                              : null,
                          width: 60.r,
                          height: 60.r,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(12.r),
                          fallbackIcon: Icons.landscape,
                          fallbackBackgroundColor:
                              Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.tour.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                              SizedBox(height: 4.h),
                              Text(
                                widget.tour.meetingLocationName,
                                style: TextStyle(fontSize: 13.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 24.h),
                    // Quantity selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.bookingGuests, style: TextStyle(fontSize: 15.sp)),
                        Row(
                          children: [
                            _quantityButton(Icons.remove, () {
                              if (_quantity > 1) setState(() => _quantity--);
                            }),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Text('$_quantity', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                            ),
                            _quantityButton(Icons.add, () {
                              if (_quantity < widget.tour.maxAttendees) setState(() => _quantity++);
                            }),
                          ],
                        ),
                      ],
                    ),
                    Divider(height: 24.h),
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
                                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: primary),
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

              SizedBox(height: 28.h),

              // ── Payment Method ──
              _buildSectionTitle(l10n.bookingPaymentMethod),
              SizedBox(height: 12.h),
              RadioGroup<String>(
                groupValue: _selectedPaymentMethod,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPaymentMethod = val);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPaymentOption(
                      title: l10n.bookingPayCardTitle,
                      subtitle: l10n.bookingPayCardSub,
                      icon: Icons.credit_card,
                      value: 'card',
                      theme: theme,
                    ),
                    _buildPaymentOption(
                      title: l10n.bookingPayWalletTitle,
                      subtitle: l10n.bookingPayWalletSub,
                      icon: Icons.phone_android,
                      value: 'wallet',
                      theme: theme,
                    ),
                    _buildPaymentOption(
                      title: l10n.bookingPayApplePayTitle,
                      subtitle: l10n.bookingPayApplePaySub,
                      icon: Icons.apple,
                      value: 'apple_pay',
                      theme: theme,
                      enabled: false, // Enable when Apple Pay integration is live
                    ),
                    _buildPaymentOption(
                      title: l10n.bookingPayKioskTitle,
                      subtitle: l10n.bookingPayKioskSub,
                      icon: Icons.receipt_long,
                      value: 'kiosk',
                      theme: theme,
                      enabled: false, // Enable when kiosk integration is created
                    ),
                  ],
                ),
              ),

              // Wallet phone input
              if (_selectedPaymentMethod == 'wallet') ...[
                SizedBox(height: 16.h),
                TextField(
                  controller: _walletPhoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.bookingWalletPhoneLabel,
                    hintText: '01XXXXXXXXX',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  ),
                ),
              ],

              SizedBox(height: 24.h),

              // ── Security Badge ──
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: isDark ? 0.08 : 0.04),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_user, color: primary, size: 20.r),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        l10n.bookingSecurityNote,
                        style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Because you booked X, you might enjoy these tours ──
              if (_loadingSimilar || _similarTours.isNotEmpty) ...[
                SizedBox(height: 28.h),
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16.r, color: primary),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        l10n.bookingBecauseBooked,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                          fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  height: 160.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _loadingSimilar ? 2 : _similarTours.length,
                    itemBuilder: (_, i) {
                      if (_loadingSimilar) {
                        return Container(
                          width: 220.w,
                          margin: EdgeInsetsDirectional.only(end: 12.w),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        );
                      }
                      return Padding(
                        padding: EdgeInsetsDirectional.only(end: 12.w),
                        child: _BookingSimilarTourCard(tour: _similarTours[i]),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16.h),
                    Text(l10n.bookingProcessing, style: TextStyle(color: Colors.white, fontSize: 16.sp)),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomSheet: Container(
        padding: EdgeInsets.all(20.r),
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
                              Text(l10n.bookingTotal, style: TextStyle(fontSize: 16.sp)),
                              Text(
                                displayLabel,
                                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: primary),
                              ),
                            ],
                          ),
                          if (showEgpNote)
                            Text(
                              l10n.bookingChargedNote(_totalPrice.toStringAsFixed(0)),
                              style: TextStyle(fontSize: 11.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _processPayment,
                  icon: const Icon(Icons.lock),
                  label: Text(l10n.bookingPaySecurely, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold));
  }

  BoxDecoration _cardDecoration(ThemeData theme, bool isDark) {
    return BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16.r),
      border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
      boxShadow: [
        BoxShadow(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(8.r),
          child: Icon(icon, size: 18.r, color: Theme.of(context).colorScheme.primary),
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
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          margin: EdgeInsets.only(bottom: 10.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.08),
              width: isSelected ? 2 : 1,
            ),
          ),
        child: RadioListTile<String>(
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: isSelected ? theme.colorScheme.primary : Colors.grey, size: 22.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp, color: theme.colorScheme.onSurface)),
                    Text(subtitle, style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ),
            ],
          ),
          value: value,
          activeColor: theme.colorScheme.primary,
        ),
      ),
    ));
  }
}

// Compact card for the "Because you booked X" row at the bottom of checkout.
// Tap navigates to a fresh TourDetailScreen — booking flow stays open behind.
class _BookingSimilarTourCard extends StatelessWidget {
  final TourEntity tour;
  const _BookingSimilarTourCard({required this.tour});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TourDetailScreen(tour: tour)),
      ),
      child: Container(
        width: 220.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ShimmerImage(
              url: tour.images.isNotEmpty ? tour.images.first : null,
              fit: BoxFit.cover,
              fallbackIcon: Icons.tour,
              fallbackBackgroundColor: theme.colorScheme.primary.withValues(alpha: 0.06),
              fallbackIconColor: theme.colorScheme.primary.withValues(alpha: 0.3),
              fallbackIconSize: 36.r,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.4, 1.0],
                ),
              ),
            ),
            if (tour.rating > 0)
              Positioned(
                top: 8.h,
                right: 8.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 12.r, color: Colors.white),
                      SizedBox(width: 2.w),
                      Text(
                        tour.rating.toStringAsFixed(1),
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              bottom: 10.h,
              left: 10.w,
              right: 10.w,
              child: Text(
                tour.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
