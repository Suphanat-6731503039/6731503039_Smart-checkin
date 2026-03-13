import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../widgets/mood_selector.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scanner = MobileScannerController();
  bool _scanned = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned || _isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    _scanned = true;
    _scanner.stop();
    _showCheckInDialog(barcode!.rawValue!);
  }

  Future<void> _showCheckInDialog(String sessionId) async {
    final prevCtrl = TextEditingController();
    final expectCtrl = TextEditingController();
    int mood = 3;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setModal) => Container(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.qr_code_scanner_rounded,
                        color: Color(0xFF4F6AF5)),
                    SizedBox(width: 8),
                    Text('QR Check-in',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E))),
                  ],
                ),
                const SizedBox(height: 20),
                _sheetField(prevCtrl, 'Previous topic covered',
                    Icons.history_edu_rounded),
                const SizedBox(height: 12),
                _sheetField(expectCtrl, 'What you expect today',
                    Icons.lightbulb_outline_rounded),
                const SizedBox(height: 16),
                MoodSelector(
                  selectedMood: mood,
                  onSelected: (m) => setModal(() => mood = m),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () async {
                            setModal(() => _isProcessing = true);
                            await _doQrCheckIn(
                              sessionId: sessionId,
                              prevTopic: prevCtrl.text.trim(),
                              expectTopic: expectCtrl.text.trim(),
                              mood: mood,
                              ctx: ctx,
                            );
                            setModal(() => _isProcessing = false);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F6AF5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Confirm Check-in',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Re-enable scanner if user dismissed without submitting
    if (mounted) {
      setState(() => _scanned = false);
      _scanner.start();
    }
  }

  Future<void> _doQrCheckIn({
    required String sessionId,
    required String prevTopic,
    required String expectTopic,
    required int mood,
    required BuildContext ctx,
  }) async {
    try {
      // Validate GPS location
      final session =
          await FirestoreService().getQrSession(sessionId);
      if (!session.exists) throw Exception('Session not found.');
      final data = session.data() as Map<String, dynamic>;

      final gpsResult = await LocationService.validateInClassroom(
        classroomLat: data['latitude'] as double,
        classroomLon: data['longitude'] as double,
        radiusMeters: (data['radiusMeters'] as int?) ?? 100,
      );

      if (!gpsResult.isInside) {
        if (mounted) Navigator.pop(ctx);
        _snack(
          'You are ${gpsResult.distanceMeters.round()}m away from class. '
          'Must be within ${gpsResult.radiusMeters}m.',
          error: true,
        );
        return;
      }

      await FirestoreService().qrCheckIn(
        sessionId: sessionId,
        latitude: gpsResult.position.latitude,
        longitude: gpsResult.position.longitude,
        mood: mood,
        previousTopic: prevTopic,
        expectedTopic: expectTopic,
      );

      if (mounted) {
        Navigator.pop(ctx);
        Navigator.pop(context);
        _snack('Check-in successful! ✓');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(ctx);
        _snack(e.toString().replaceAll('Exception: ', ''), error: true);
      }
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    ));
  }

  Widget _sheetField(
      TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      maxLines: 2,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Scan QR Code',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
            onPressed: _scanner.toggleTorch,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scanner,
            onDetect: _onDetect,
          ),
          // Overlay with scan window
          CustomPaint(
            painter: _ScanOverlayPainter(),
            child: const SizedBox.expand(),
          ),
          // Hint text
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Point camera at the instructor\'s QR code',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    final cx = size.width / 2;
    final cy = size.height / 2;
    const side = 240.0;
    final rect = Rect.fromCenter(
        center: Offset(cx, cy), width: side, height: side);

    // Draw dark overlay around scan area
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()
          ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16))),
      ),
      paint,
    );

    // Draw corner accents
    final corner = Paint()
      ..color = const Color(0xFF4F6AF5)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const cs = 24.0;
    for (final pt in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      final dx = pt == rect.topLeft || pt == rect.bottomLeft ? 1.0 : -1.0;
      final dy = pt == rect.topLeft || pt == rect.topRight ? 1.0 : -1.0;
      canvas.drawLine(pt, Offset(pt.dx + dx * cs, pt.dy), corner);
      canvas.drawLine(pt, Offset(pt.dx, pt.dy + dy * cs), corner);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
