import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/shimmer_avatar.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;
  String? _lastScanned;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null) return;
    final bookingId = barcode.rawValue;
    if (bookingId == null || bookingId.isEmpty) return;
    if (_processing || bookingId == _lastScanned) return;

    setState(() {
      _processing = true;
      _lastScanned = bookingId;
    });
    await _controller.stop();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!mounted) return;
      if (!doc.exists) {
        _showResult(context, valid: false, message: 'Booking not found');
        return;
      }

      final data = doc.data()!;
      final status = data['status'] ?? '';
      final tourId = data['tourId'] ?? '';
      final userId = data['userId'] ?? '';

      // Fetch tour + tourist info in parallel
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('tours').doc(tourId).get(),
        FirebaseFirestore.instance.collection('users').doc(userId).get(),
      ]);

      final tourData = results[0].data();
      final userData = results[1].data();

      if (!mounted) return;
      _showBookingSheet(
        context,
        bookingId: bookingId,
        bookingData: data,
        tourData: tourData,
        userData: userData,
        alreadyCheckedIn: status == 'checked_in' || status == 'partially_checked_in',
      );
    } catch (e) {
      if (!mounted) return;
      _showResult(context, valid: false, message: ErrorHandler.handleGenericError(e));
    }
  }

  void _showResult(BuildContext context, {required bool valid, required String message}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              valid ? Icons.check_circle : Icons.error,
              size: 64.r,
              color: valid ? Colors.green : Colors.red,
            ),
            SizedBox(height: 12.h),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resumeScanner();
            },
            child: const Text('Scan Another'),
          ),
        ],
      ),
    );
  }

  void _showBookingSheet(
    BuildContext context, {
    required String bookingId,
    required Map<String, dynamic> bookingData,
    Map<String, dynamic>? tourData,
    Map<String, dynamic>? userData,
    required bool alreadyCheckedIn,
  }) {
    if (!mounted) return;
    final status = bookingData['status'] ?? '';
    final isValid = status == 'confirmed' || status == 'checked_in' ||
        status == 'partially_checked_in';
    final theme = Theme.of(context);

    final tourTitle = tourData?['title'] ?? 'Unknown Tour';
    final tourDate = (bookingData['date'] as Timestamp?)?.toDate();
    final quantity = (bookingData['quantity'] as num?)?.toInt() ?? 1;
    final totalEGP = (bookingData['totalAmountEGP'] as num?)?.toDouble() ?? 0;
    final alreadyCheckedInCount =
        (bookingData['checkedInCount'] as num?)?.toInt() ??
        (status == 'checked_in' ? quantity : 0);
    final remaining = quantity - alreadyCheckedInCount;

    final firstName = userData?['firstName'] ?? '';
    final lastName = userData?['lastName'] ?? '';
    final touristName = '$firstName $lastName'.trim();
    final username = userData?['username'] ?? '';
    final avatar = userData?['profileImageUrl'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        int checkingIn = remaining > 0 ? remaining : 0;
        return StatefulBuilder(
          builder: (ctx, setBS) => Padding(
            padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 40.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Validity indicator
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: (isValid ? Colors.green : Colors.red).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isValid ? Icons.verified : Icons.cancel,
                          color: isValid ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          remaining == 0
                              ? 'All Tickets Checked In'
                              : status == 'partially_checked_in'
                                  ? 'Partially Checked In ($alreadyCheckedInCount/$quantity)'
                                  : isValid
                                      ? 'Valid Ticket'
                                      : 'Invalid Ticket (${status.toUpperCase()})',
                          style: TextStyle(
                            color: isValid ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Tourist info
                Row(
                  children: [
                    ShimmerAvatar(
                      url: avatar,
                      radius: 30.r,
                      iconSize: 28.r,
                    ),
                    SizedBox(width: 14.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          touristName.isNotEmpty ? touristName : 'Unknown Traveler',
                          style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold),
                        ),
                        if (username.isNotEmpty)
                          Text(
                            '@$username',
                            style: TextStyle(
                                fontSize: 13.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                          ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                const Divider(),
                SizedBox(height: 12.h),

                // Booking details
                _SheetRow(Icons.tour_outlined, 'Tour', tourTitle),
                if (tourDate != null)
                  _SheetRow(Icons.calendar_today, 'Date',
                      DateFormat('EEE, MMM d · h:mm a').format(tourDate)),
                _SheetRow(Icons.confirmation_number_outlined, 'Tickets',
                    '$quantity ticket${quantity > 1 ? 's' : ''}'
                    '${alreadyCheckedInCount > 0 ? ' · $alreadyCheckedInCount checked in' : ''}'),
                _SheetRow(Icons.payments_outlined, 'Amount',
                    'EGP ${totalEGP.toStringAsFixed(0)}'),
                _SheetRow(Icons.receipt_outlined, 'Booking ID',
                    bookingId.substring(0, 8).toUpperCase()),

                // Partial check-in stepper (only when tickets remain)
                if (isValid && remaining > 0 && quantity > 1) ...[
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Text(
                        'Check in how many?',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: checkingIn > 1
                            ? () => setBS(() => checkingIn--)
                            : null,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(
                        width: 32.w,
                        child: Text(
                          '$checkingIn',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 18.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: checkingIn < remaining
                            ? () => setBS(() => checkingIn++)
                            : null,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ],

                SizedBox(height: 16.h),

                // Check-in button
                if (isValid && remaining > 0)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(quantity == 1
                          ? 'Check In Tourist'
                          : 'Check In $checkingIn of $remaining Remaining'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      onPressed: () async {
                        try {
                          final newCheckedIn = alreadyCheckedInCount + checkingIn;
                          final newStatus = newCheckedIn >= quantity
                              ? 'checked_in'
                              : 'partially_checked_in';
                          await FirebaseFirestore.instance
                              .collection('bookings')
                              .doc(bookingId)
                              .update({
                            'status': newStatus,
                            'checkedInCount': newCheckedIn,
                          });
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            _showResult(
                              context,
                              valid: true,
                              message: newStatus == 'checked_in'
                                  ? 'All $quantity tickets checked in!'
                                  : '$checkingIn ticket${checkingIn > 1 ? 's' : ''} checked in.\n${quantity - newCheckedIn} remaining.',
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            _showResult(context, valid: false, message: ErrorHandler.handleGenericError(e));
                          }
                        }
                      },
                    ),
                  ),
                if (!isValid || remaining == 0)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _resumeScanner();
                      },
                      child: const Text('Scan Another'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ).then((_) => _resumeScanner());
  }

  void _resumeScanner() {
    setState(() {
      _processing = false;
      _lastScanned = null;
    });
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Ticket QR'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Overlay with cutout
          IgnorePointer(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(color: theme.colorScheme.primary),
              child: const SizedBox.expand(),
            ),
          ),
          // Label
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.only(bottom: 48.h),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Text(
                'Point camera at tourist\'s QR ticket',
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
              ),
            ),
          ),
          if (_processing)
            Container(
              color: Colors.black38,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scanner overlay painter
// ─────────────────────────────────────────────────────────────────────────────

class _ScannerOverlayPainter extends CustomPainter {
  final Color color;
  const _ScannerOverlayPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const cutoutSize = 260.0;
    final cx = size.width / 2;
    final cy = size.height / 2 - 40;
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: cutoutSize, height: cutoutSize);

    final paint = Paint()..color = Colors.black54;
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    // Corner markers
    final cornerPaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const cornerLen = 24.0;
    const r = 8.0;

    // top-left
    canvas.drawLine(Offset(rect.left + r, rect.top), Offset(rect.left + cornerLen, rect.top), cornerPaint);
    canvas.drawLine(Offset(rect.left, rect.top + r), Offset(rect.left, rect.top + cornerLen), cornerPaint);
    // top-right
    canvas.drawLine(Offset(rect.right - cornerLen, rect.top), Offset(rect.right - r, rect.top), cornerPaint);
    canvas.drawLine(Offset(rect.right, rect.top + r), Offset(rect.right, rect.top + cornerLen), cornerPaint);
    // bottom-left
    canvas.drawLine(Offset(rect.left + r, rect.bottom), Offset(rect.left + cornerLen, rect.bottom), cornerPaint);
    canvas.drawLine(Offset(rect.left, rect.bottom - cornerLen), Offset(rect.left, rect.bottom - r), cornerPaint);
    // bottom-right
    canvas.drawLine(Offset(rect.right - cornerLen, rect.bottom), Offset(rect.right - r, rect.bottom), cornerPaint);
    canvas.drawLine(Offset(rect.right, rect.bottom - cornerLen), Offset(rect.right, rect.bottom - r), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet row helper
// ─────────────────────────────────────────────────────────────────────────────

class _SheetRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SheetRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Icon(icon, size: 18.r, color: theme.colorScheme.primary),
          SizedBox(width: 10.w),
          Text('$label: ', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.55), fontSize: 13.sp)),
          Expanded(
            child: Text(value,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
