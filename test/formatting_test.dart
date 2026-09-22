// Tests for the small text-formatting helpers used to fix bug-scan findings:
// the hardcoded "Last service" text and the duplicated "days away" label.

import 'package:flutter_test/flutter_test.dart';
import 'package:new_app/maintenance_record.dart';
import 'package:new_app/scheduled_maintenance.dart';

void main() {
  group('relativeTimeAgo', () {
    final now = DateTime(2026, 9, 22, 10, 0);

    test('same day reads as today', () {
      expect(relativeTimeAgo(DateTime(2026, 9, 22, 2, 0), now), 'today');
    });

    test('one day back reads as yesterday', () {
      expect(relativeTimeAgo(DateTime(2026, 9, 21), now), 'yesterday');
    });

    test('under a month uses days', () {
      expect(relativeTimeAgo(DateTime(2026, 9, 10), now), '12 days ago');
    });

    test('under a year uses months, singular for one', () {
      expect(relativeTimeAgo(DateTime(2026, 6, 18), now), '3 months ago');
      expect(relativeTimeAgo(DateTime(2026, 8, 20), now), '1 month ago');
    });

    test('a year or more uses years, singular for one', () {
      expect(relativeTimeAgo(DateTime(2025, 9, 20), now), '1 year ago');
      expect(relativeTimeAgo(DateTime(2023, 1, 1), now), '4 years ago');
    });
  });

  group('relativeDaysLabel', () {
    test('zero or negative is Today, not a negative count', () {
      expect(relativeDaysLabel(0), 'Today');
      expect(relativeDaysLabel(-2), 'Today');
    });

    test('one day is Tomorrow', () {
      expect(relativeDaysLabel(1), 'Tomorrow');
    });

    test('under 60 days counts days', () {
      expect(relativeDaysLabel(6), 'in 6 days');
    });

    test('60 days or more counts months', () {
      expect(relativeDaysLabel(90), 'in 3 months');
    });
  });
}
