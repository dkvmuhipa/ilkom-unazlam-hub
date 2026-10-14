import 'package:flutter/material.dart';

import '../../../core/services/course_schedule_service.dart';
import '../../../core/widgets/scale_button.dart';
import '../../../models/models.dart';

class ScheduleDaySelector extends StatelessWidget {
  final String selectedDay;
  final List<String> days;
  final List<Course> allCourses;
  final ValueChanged<String> onDaySelected;

  const ScheduleDaySelector({
    super.key,
    required this.selectedDay,
    required this.days,
    required this.allCourses,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayName = CourseScheduleService.getDayName(now);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: days.map((day) {
          final isSelected = day == selectedDay;
          final isToday = day == todayName;
          final count = day == 'Semua'
              ? allCourses.length
              : allCourses
                  .where((c) =>
                      c.hari.trim().toLowerCase() == day.toLowerCase())
                  .length;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ScaleButton(
              onTap: () => onDaySelected(day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF1E40AF), Color(0xFF4338CA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF1E40AF)
                        : (isToday
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFFE2E8F0)),
                    width: isToday && !isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF1E40AF).withValues(alpha: 0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isToday) ...[
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isToday
                                ? const Color(0xFF047857)
                                : const Color(0xFF334155)),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.2)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
