import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../qrcode/qr_generator_screen.dart';

class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  Map<String, int> _weeklyData = {};
  bool _weeklyLoading = true;

  static const _moodEmoji = ['', '😡', '🙁', '😐', '🙂', '😄'];
  static const _moodLabels = ['', 'Awful', 'Bad', 'Okay', 'Good', 'Great'];
  static const _moodColors = [
    Colors.transparent,
    Color(0xFFFF4757),
    Color(0xFFFF7F50),
    Color(0xFFFFD700),
    Color(0xFF7ED321),
    Color(0xFF00C853),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadWeekly();
  }

  Future<void> _loadWeekly() async {
    final data = await FirestoreService().getWeeklyCheckInCounts();
    if (mounted)
      setState(() {
        _weeklyData = data;
        _weeklyLoading = false;
      });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService().streamCheckIns(),
        builder: (context, snapshot) {
          final isLoading = !snapshot.hasData;
          final docs = snapshot.data?.docs ?? [];
          final total = docs.length;

          final moodCount = [0, 0, 0, 0, 0, 0];
          for (final d in docs) {
            final m = (d['mood'] as int?) ?? 0;
            if (m >= 1 && m <= 5) moodCount[m]++;
          }
          final avgMood = total == 0
              ? 0.0
              : docs.fold<double>(0, (s, d) => s + ((d['mood'] as int?) ?? 0)) /
                  total;

          return NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: const Color(0xFFF59E0B),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.qr_code_2_rounded,
                        color: Colors.white),
                    tooltip: 'Generate QR',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const QrGeneratorScreen()),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 60, bottom: 56),
                  title: const Text('Instructor Dashboard',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18)),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                bottom: TabBar(
                  controller: _tab,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Records'),
                  ],
                ),
              ),
            ],
            body: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
                : TabBarView(
                    controller: _tab,
                    children: [
                      _overviewTab(total, avgMood, moodCount),
                      _recordsTab(docs),
                    ],
                  ),
          );
        },
      ),
    );
  }

  // ── Overview tab ─────────────────────────────────────────

  Widget _overviewTab(int total, double avgMood, List<int> moodCount) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Stat cards
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total Check-ins',
                value: total.toString(),
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF4F6AF5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Avg. Mood',
                value: avgMood.toStringAsFixed(1),
                icon: Icons.sentiment_satisfied_alt_rounded,
                color: const Color(0xFF10B981),
                suffix: ' / 5',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Weekly bar chart
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(Icons.bar_chart_rounded, 'Check-ins (Last 7 Days)'),
              const SizedBox(height: 16),
              _weeklyLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFF59E0B)))
                  : _WeeklyBarChart(data: _weeklyData),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Mood distribution
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(Icons.mood_rounded, 'Mood Distribution'),
              const SizedBox(height: 16),
              ...List.generate(5, (i) {
                final idx = i + 1;
                final count = moodCount[idx];
                final pct = total == 0 ? 0.0 : count / total;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Text(_moodEmoji[idx],
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 38,
                        child: Text(_moodLabels[idx],
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: pct),
                            duration: const Duration(milliseconds: 600),
                            builder: (_, value, __) => LinearProgressIndicator(
                              value: value,
                              backgroundColor: Colors.grey.shade100,
                              valueColor:
                                  AlwaysStoppedAnimation(_moodColors[idx]),
                              minHeight: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(count.toString(),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E))),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Records tab ──────────────────────────────────────────

  Widget _recordsTab(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 52, color: Colors.grey),
            SizedBox(height: 12),
            Text('No check-ins yet',
                style: TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: docs.length,
      itemBuilder: (_, i) {
        final d = docs[i];
        final mood = ((d['mood'] as int?) ?? 0).clamp(1, 5);
        final ts = (d['timestamp'] as Timestamp?)?.toDate();
        final timeStr = ts != null
            ? '${ts.day}/${ts.month}/${ts.year}  '
                '${ts.hour.toString().padLeft(2, '0')}:'
                '${ts.minute.toString().padLeft(2, '0')}'
            : '—';
        final name = (d['displayName'] as String?) ?? 'Unknown';
        final method = (d['method'] as String?) ?? 'manual';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _moodColors[mood].withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                    child: Text(_moodEmoji[mood],
                        style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 2),
                    Text(
                      d['previousTopic'] ?? 'No topic',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(timeStr,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _moodColors[mood].withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _moodLabels[mood],
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _moodColors[mood]),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: method == 'qr'
                          ? const Color(0xFF7C3AED).withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      method == 'qr' ? '📱 QR' : '✏️ Manual',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: method == 'qr'
                              ? const Color(0xFF7C3AED)
                              : Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ──────────────────────────────────────────────

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
                offset: const Offset(0, 4))
          ],
        ),
        child: child,
      );

  Widget _sectionTitle(IconData icon, String text) => Row(
        children: [
          Icon(icon, color: const Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
        ],
      );
}

// ── Weekly bar chart (pure Flutter, no package needed) ────

class _WeeklyBarChart extends StatelessWidget {
  final Map<String, int> data;
  const _WeeklyBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    // Build last 7 days list
    final days = List.generate(7, (i) {
      final d = DateTime.now().subtract(Duration(days: 6 - i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      return _DayBar(
        label: _dayLabel(d),
        count: data[key] ?? 0,
      );
    });

    final maxVal = days.map((d) => d.count).reduce((a, b) => a > b ? a : b);
    final maxDisplay = maxVal == 0 ? 1 : maxVal;

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((d) {
          final frac = d.count / maxDisplay;
          final isToday = d.label == _dayLabel(DateTime.now());
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (d.count > 0)
                    Text(d.count.toString(),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isToday
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF4F6AF5))),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration:
                        Duration(milliseconds: 400 + days.indexOf(d) * 50),
                    curve: Curves.easeOutCubic,
                    height: (frac * 90).clamp(4, 90),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isToday
                            ? [const Color(0xFFF59E0B), const Color(0xFFFBBF24)]
                            : [
                                const Color(0xFF4F6AF5),
                                const Color(0xFF7C3AED)
                              ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(d.label,
                      style: TextStyle(
                          fontSize: 10,
                          color:
                              isToday ? const Color(0xFFF59E0B) : Colors.grey,
                          fontWeight:
                              isToday ? FontWeight.w700 : FontWeight.normal)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _dayLabel(DateTime d) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[d.weekday - 1];
  }
}

class _DayBar {
  final String label;
  final int count;
  const _DayBar({required this.label, required this.count});
}

// ── StatCard widget ────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? suffix;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800, color: color)),
              if (suffix != null)
                Text(suffix!,
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
