import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final _classNameCtrl = TextEditingController();
  int _radius = 100;
  int _validMinutes = 15;
  bool _isLoading = false;
  String? _sessionId;
  DateTime? _expiresAt;

  @override
  void dispose() {
    _classNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_classNameCtrl.text.trim().isEmpty) {
      _snack('Please enter a class name', error: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final pos = await LocationService.getLocation();
      final id = await FirestoreService().createQrSession(
        className: _classNameCtrl.text.trim(),
        latitude: pos.latitude,
        longitude: pos.longitude,
        radiusMeters: _radius,
        validMinutes: _validMinutes,
      );
      setState(() {
        _sessionId = id;
        _expiresAt = DateTime.now().add(Duration(minutes: _validMinutes));
      });
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: const Color(0xFF7C3AED),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
              title: const Text('QR Check-in',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF4F6AF5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Settings card
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(Icons.class_outlined, 'Class Name'),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _classNameCtrl,
                          decoration: const InputDecoration(
                            hintText: 'e.g. CS301 – Data Structures',
                            hintStyle:
                                TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _label(Icons.radar_rounded, 'Allowed Radius'),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: _radius.toDouble(),
                                min: 50,
                                max: 500,
                                divisions: 9,
                                activeColor: const Color(0xFF7C3AED),
                                label: '$_radius m',
                                onChanged: (v) =>
                                    setState(() => _radius = v.round()),
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: Text('$_radius m',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF7C3AED))),
                            ),
                          ],
                        ),
                        _label(Icons.timer_outlined, 'Valid For'),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: [5, 10, 15, 30, 60].map((m) {
                            final sel = m == _validMinutes;
                            return ChoiceChip(
                              label: Text('${m}min'),
                              selected: sel,
                              selectedColor:
                                  const Color(0xFF7C3AED).withOpacity(0.15),
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? const Color(0xFF7C3AED)
                                    : Colors.grey,
                              ),
                              onSelected: (_) =>
                                  setState(() => _validMinutes = m),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _generate,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.qr_code_2_rounded),
                      label: Text(_isLoading ? 'Generating...' : 'Generate QR Code',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  // QR display
                  if (_sessionId != null) ...[
                    const SizedBox(height: 24),
                    _card(
                      child: Column(
                        children: [
                          const Text('Scan to Check In',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Color(0xFF1A1A2E))),
                          const SizedBox(height: 4),
                          Text(
                            _classNameCtrl.text,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          QrImageView(
                            data: _sessionId!,
                            version: QrVersions.auto,
                            size: 220,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          _expiryBadge(),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _expiryBadge() {
    if (_expiresAt == null) return const SizedBox.shrink();
    final remaining = _expiresAt!.difference(DateTime.now());
    final expired = remaining.isNegative;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: expired
            ? const Color(0xFFEF4444).withOpacity(0.1)
            : const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: expired
              ? const Color(0xFFEF4444).withOpacity(0.4)
              : const Color(0xFF10B981).withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            expired ? Icons.timer_off_rounded : Icons.timer_rounded,
            size: 14,
            color: expired ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          ),
          const SizedBox(width: 6),
          Text(
            expired
                ? 'Expired'
                : 'Expires at ${_expiresAt!.hour.toString().padLeft(2, '0')}:${_expiresAt!.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color:
                  expired ? const Color(0xFFEF4444) : const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: child,
      );

  Widget _label(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF7C3AED)),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
        ],
      );
}
