import 'package:flutter_test/flutter_test.dart';
import 'package:matchnotes/presentation/x_axis_labels.dart';

void main() {
  group('shouldShowXAxisLabel', () {
    test('always shows day 1 and last day for 30-day month', () {
      const days = 30;
      expect(shouldShowXAxisLabel(1, days), isTrue);
      expect(shouldShowXAxisLabel(days, days), isTrue);
    });

    test('always shows day 1 and last day for 31-day month', () {
      const days = 31;
      expect(shouldShowXAxisLabel(1, days), isTrue);
      expect(shouldShowXAxisLabel(days, days), isTrue);
    });

    test('roughly six divisions for 30-day month', () {
      const days = 30;
      final shown = [
        for (var d = 1; d <= days; d++)
          if (shouldShowXAxisLabel(d, days)) d,
      ];
      // Should include 1 and 30
      expect(shown.first, 1);
      expect(shown.last, 30);
      // Keep label count reasonable (~<=8)
      expect(shown.length <= 8, isTrue);
      expect(shown.length >= 4, isTrue);
    });

    test('roughly six divisions for 31-day month', () {
      const days = 31;
      final shown = [
        for (var d = 1; d <= days; d++)
          if (shouldShowXAxisLabel(d, days)) d,
      ];
      // Should include 1 and 31
      expect(shown.first, 1);
      expect(shown.last, 31);
      // Keep label count reasonable (~<=8)
      expect(shown.length <= 8, isTrue);
      expect(shown.length >= 4, isTrue);
    });
  });
}
