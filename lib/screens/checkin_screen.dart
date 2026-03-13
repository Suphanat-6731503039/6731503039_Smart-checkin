import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../services/firestore_service.dart';
import '../widgets/mood_selector.dart';

// Instructor's classroom GPS coordinates — update to match your venue.
// These could also be fetched from Firestore for dynamic configuration.
const double _classroomLat = 13.7563; // example: Bangkok
const double _classroomLon = 100.5018;
const int _classroomRadiusMeters = 200;

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _prev = TextEditingController();
  final _expect = TextEditingController();
  int _mood = 3;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_prev.text.trim().isEmpty || _expect.text.trim().isEmpty) {
      _showSnackbar('Please fill in all fields', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      // ── GPS classroom validation ──────────────────────────
      final gps = await LocationService.validateInClassroom(
        classroomLat: _classroomLat,
        classroomLon: _classroomLon,
        radiusMeters: _classroomRadiusMeters,
      );

      if (!gps.isInside) {
        _showSnackbar(
          'You are ${gps.distanceMeters.round()}m away from the classroom. '
          'Must be within ${gps.radiusMeters}m.',
          isError: true,
        );
        setState(() => _isLoading = false);
        return;
      }
      // ─────────────────────────────────────────────────────

      await FirestoreService().saveCheckIn({
        'previousTopic': _prev.text.trim(),
        'expectedTopic': _expect.text.trim(),
        'mood': _mood,
        'latitude': gps.position.latitude,
        'longitude': gps.position.longitude,
        'method': 'manual',
      });
      _showSnackbar('Check-in saved successfully! ✓');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackbar(
          e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _prev.dispose();
    _expect.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFF4F6AF5),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
              title: const Text(
                'Check-in',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4F6AF5), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24, bottom: 16),
                    child: Icon(Icons.login_rounded,
                        size: 64, color: Colors.white.withOpacity(0.15)),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // GPS info banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F6AF5).withOpacity(0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFF4F6AF5).withOpacity(0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            color: Color(0xFF4F6AF5), size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your location will be verified to ensure you\'re in the classroom.',
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF3B4FD1),
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(
                            icon: Icons.history_edu_rounded,
                            label: 'Previous Topic'),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _prev,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'What was covered in the last class?',
                            hintStyle:
                                TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(
                            icon: Icons.lightbulb_outline_rounded,
                            label: 'Expected Topic'),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _expect,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'What do you expect to learn today?',
                            hintStyle:
                                TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    child: MoodSelector(
                      selectedMood: _mood,
                      onSelected: (m) => setState(() => _mood = m),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F6AF5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Submit Check-in',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable sub-widgets ────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF4F6AF5)),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            )),
      ],
    );
  }
}
