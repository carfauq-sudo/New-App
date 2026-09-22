import 'package:flutter_test/flutter_test.dart';
import 'package:new_app/calc/maintenance_math.dart';

void main() {
  final now = DateTime(2026, 9, 21);

  group('estimateMileage', () {
    test('no readings gives null', () {
      expect(estimateMileage([], now), isNull);
    });

    test('one reading is used as is (no guessing a rate)', () {
      final e = estimateMileage([
        OdometerReading(DateTime(2026, 9, 1), 42000),
      ], now)!;
      expect(e.miles, 42000);
      expect(e.milesPerDay, 0);
      expect(e.isProjected, isFalse);
    });

    test('projects forward from the driving rate', () {
      // 1,000 miles over 100 days = 10 mi/day; latest reading 20 days ago.
      final readings = [
        OdometerReading(DateTime(2026, 6, 1), 41000),
        OdometerReading(DateTime(2026, 9, 1), 42000 - 0),
      ];
      final e = estimateMileage(readings, now)!;
      // 1000 miles / 92 days
      expect(e.milesPerDay, closeTo(1000 / 92, 0.001));
      expect(e.miles, 42000 + (1000 / 92 * 20).round());
      expect(e.isProjected, isTrue);
    });

    test('order of readings does not matter', () {
      final a = OdometerReading(DateTime(2026, 6, 1), 41000);
      final b = OdometerReading(DateTime(2026, 9, 1), 42000);
      expect(
        estimateMileage([a, b], now)!.miles,
        estimateMileage([b, a], now)!.miles,
      );
    });

    test('readings that are too close together do not set a rate', () {
      final e = estimateMileage([
        OdometerReading(DateTime(2026, 9, 10), 42000),
        OdometerReading(DateTime(2026, 9, 12), 42100),
      ], now)!;
      expect(e.milesPerDay, 0);
      expect(e.miles, 42100);
    });

    test('a mistyped, decreasing reading does not give a negative rate', () {
      final e = estimateMileage([
        OdometerReading(DateTime(2026, 3, 1), 45000),
        OdometerReading(DateTime(2026, 9, 1), 42000),
      ], now)!;
      expect(e.milesPerDay, 0);
    });

    test('never goes backwards if the latest reading is in the future', () {
      final e = estimateMileage([
        OdometerReading(DateTime(2026, 10, 1), 42500),
      ], now)!;
      expect(e.miles, 42500);
    });
  });

  group('computeLife', () {
    test('miles only: changed at 39,000, now 42,180, 10,000 interval', () {
      final r = computeLife(
        lastServiceMiles: 39000,
        lastServiceDate: DateTime(2026, 3, 12),
        currentMiles: 42180,
        now: now,
        intervalMiles: 10000,
      )!;
      expect(r.milesUsed, 3180);
      expect(r.milesRemaining, 6820);
      expect(r.percentLeft, 68);
      expect(r.overdue, isFalse);
      expect(r.limitedByMonths, isFalse);
    });

    test('whichever comes first: time can run out before miles', () {
      final r = computeLife(
        lastServiceMiles: 39000,
        lastServiceDate: DateTime(2026, 3, 21), // 6 months ago
        currentMiles: 40000,
        now: now,
        intervalMiles: 10000,
        intervalMonths: 6,
      )!;
      expect(r.limitedByMonths, isTrue);
      expect(r.fractionLeft, lessThan(0.05));
    });

    test('clamps to 0 and flags overdue', () {
      final r = computeLife(
        lastServiceMiles: 30000,
        lastServiceDate: DateTime(2025, 1, 1),
        currentMiles: 45000,
        now: now,
        intervalMiles: 10000,
      )!;
      expect(r.fractionLeft, 0);
      expect(r.percentLeft, 0);
      expect(r.overdue, isTrue);
      expect(r.milesRemaining, 0);
      expect(r.dueDate, now);
    });

    test('no interval gives null instead of a made-up number', () {
      expect(
        computeLife(
          lastServiceMiles: 1,
          lastServiceDate: now,
          currentMiles: 2,
          now: now,
        ),
        isNull,
      );
    });

    test('due date projects from the driving rate', () {
      final r = computeLife(
        lastServiceMiles: 39000,
        lastServiceDate: DateTime(2026, 3, 12),
        currentMiles: 42180,
        now: now,
        intervalMiles: 10000,
        milesPerDay: 40,
      )!;
      // 6,820 miles at 40 mi/day = 171 days
      expect(r.dueDate, now.add(const Duration(days: 171)));
    });

    test('no driving rate means no projected due date from miles', () {
      final r = computeLife(
        lastServiceMiles: 39000,
        lastServiceDate: DateTime(2026, 3, 12),
        currentMiles: 42180,
        now: now,
        intervalMiles: 10000,
      )!;
      expect(r.dueDate, isNull);
    });

    test(
      'a service recorded with a later odometer than now never goes negative',
      () {
        final r = computeLife(
          lastServiceMiles: 43000,
          lastServiceDate: DateTime(2026, 9, 1),
          currentMiles: 42180,
          now: now,
          intervalMiles: 10000,
        )!;
        expect(r.milesUsed, 0);
        expect(r.percentLeft, 100);
      },
    );
  });

  test('addMonths clamps to the end of shorter months', () {
    expect(addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
    expect(addMonths(DateTime(2026, 11, 15), 3), DateTime(2027, 2, 15));
  });
}
