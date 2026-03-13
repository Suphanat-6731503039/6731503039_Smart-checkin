import 'package:flutter/material.dart';

class MoodSelector extends StatelessWidget {
  final int selectedMood;
  final Function(int) onSelected;

  const MoodSelector({
    super.key,
    required this.selectedMood,
    required this.onSelected,
  });

  static const _moods = ['😡', '🙁', '😐', '🙂', '😄'];
  static const _labels = ['Awful', 'Bad', 'Okay', 'Good', 'Great'];
  static const _colors = [
    Color(0xFFFF4757),
    Color(0xFFFF7F50),
    Color(0xFFFFD700),
    Color(0xFF7ED321),
    Color(0xFF00C853),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How are you feeling?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_moods.length, (i) {
            final value = i + 1;
            final isSelected = value == selectedMood;
            return GestureDetector(
              onTap: () => onSelected(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                width: isSelected ? 64 : 54,
                height: isSelected ? 64 : 54,
                decoration: BoxDecoration(
                  color: isSelected
                      ? _colors[i].withOpacity(0.15)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(color: _colors[i], width: 2)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _colors[i].withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_moods[i],
                        style: TextStyle(fontSize: isSelected ? 28 : 22)),
                    if (isSelected) ...[
                      const SizedBox(height: 2),
                      Text(
                        _labels[i],
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _colors[i],
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
