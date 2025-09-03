import 'dart:math';

/// Decide whether to show label for a given day on the X axis.
/// Guarantees day 1 and the last day label appear, and roughly 6 divisions in total.
bool shouldShowXAxisLabel(int day, int daysInMonth) {
  assert(day >= 1 && day <= daysInMonth);
  if (day == 1 || day == daysInMonth) return true;
  final step = max(1, ((daysInMonth - 1) / 6).ceil());
  return (day - 1) % step == 0;
}
