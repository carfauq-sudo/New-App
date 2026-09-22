// Pure calculations for maintenance data: no screens, no storage, no clocks
// (the current time is always passed in). That keeps them fast, easy to test,
// and safe to call from anywhere.

import 'dart:math' as math;

/// One odometer reading the user gave us (from stats or a log).
class OdometerReading {
  final DateTime date;
  final int miles;

  const OdometerReading(this.date, this.miles);
}

/// The app has no live odometer, so today's mileage is an estimate: the latest
/// reading plus (average miles per day since) x (days since that reading).
class MileageEstimate {
  final int miles;
  final double milesPerDay; // 0 when there isn't enough history to know
  final DateTime basedOnDate; // date of the latest real reading
  final int basedOnMiles;

  /// True when we projected past the latest reading rather than using it as is.
  bool get isProjected => miles != basedOnMiles;

  const MileageEstimate({
    required this.miles,
    required this.milesPerDay,
    required this.basedOnDate,
    required this.basedOnMiles,
  });
}

/// Estimates today's mileage. Returns null when there are no readings.
///
/// The driving rate uses only readings from the year before the latest one
/// (old data shouldn't drag on a recent change in driving), and only when they
/// span at least [minSpanDays] days and actually increase; otherwise we don't
/// extrapolate at all and just use the latest reading.
MileageEstimate? estimateMileage(
  List<OdometerReading> readings,
  DateTime now, {
  int minSpanDays = 14,
}) {
  if (readings.isEmpty) return null;
  final sorted = [...readings]..sort((a, b) => a.date.compareTo(b.date));
  final latest = sorted.last;

  final windowStart = latest.date.subtract(const Duration(days: 365));
  final recent = sorted.where((r) => !r.date.isBefore(windowStart)).toList();
  final first = recent.first;

  final spanDays = latest.date.difference(first.date).inDays;
  final rate = (spanDays >= minSpanDays && latest.miles > first.miles)
      ? (latest.miles - first.miles) / spanDays
      : 0.0;

  final daysSince = math.max(0, now.difference(latest.date).inDays);
  return MileageEstimate(
    miles: latest.miles + (rate * daysSince).round(),
    milesPerDay: rate,
    basedOnDate: latest.date,
    basedOnMiles: latest.miles,
  );
}

/// How much of a service interval is left. See [computeLife].
class LifeResult {
  /// 0.0 (used up) to 1.0 (brand new).
  final double fractionLeft;
  final int milesUsed;
  final int? milesRemaining; // null if there's no mileage interval
  final DateTime? dueDate; // earliest of the mileage and month limits
  final bool limitedByMonths; // true when time, not miles, runs out first
  final bool overdue;

  const LifeResult({
    required this.fractionLeft,
    required this.milesUsed,
    required this.milesRemaining,
    required this.dueDate,
    required this.limitedByMonths,
    required this.overdue,
  });

  int get percentLeft => (fractionLeft * 100).round();
}

/// Life left for an interval item (oil change, tire rotation...). "Whichever
/// comes first": the item is as used up as the larger of the miles fraction and
/// the months fraction. Either interval may be missing, but not both (then
/// there's nothing to compute and this returns null).
LifeResult? computeLife({
  required int lastServiceMiles,
  required DateTime lastServiceDate,
  required int currentMiles,
  required DateTime now,
  int? intervalMiles,
  int? intervalMonths,
  double milesPerDay = 0,
}) {
  if (intervalMiles == null && intervalMonths == null) return null;

  final milesUsed = math.max(0, currentMiles - lastServiceMiles);
  final milesFraction = intervalMiles == null ? 0.0 : milesUsed / intervalMiles;

  final daysUsed = math.max(0, now.difference(lastServiceDate).inDays);
  final monthsFraction = intervalMonths == null
      ? 0.0
      : (daysUsed / 30.4375) / intervalMonths;

  final used = math.max(milesFraction, monthsFraction);
  final milesRemaining = intervalMiles == null
      ? null
      : math.max(0, intervalMiles - milesUsed);

  // Due date: whichever limit is reached first.
  final candidates = <DateTime>[];
  if (milesRemaining != null) {
    if (milesRemaining == 0) {
      candidates.add(now);
    } else if (milesPerDay > 0) {
      candidates.add(
        now.add(Duration(days: (milesRemaining / milesPerDay).ceil())),
      );
    }
  }
  if (intervalMonths != null) {
    candidates.add(addMonths(lastServiceDate, intervalMonths));
  }
  candidates.sort();

  return LifeResult(
    fractionLeft: (1 - used).clamp(0.0, 1.0),
    milesUsed: milesUsed,
    milesRemaining: milesRemaining,
    dueDate: candidates.isEmpty ? null : candidates.first,
    limitedByMonths: monthsFraction > milesFraction,
    overdue: used >= 1,
  );
}

/// Adds calendar months, clamping the day (Jan 31 + 1 month = Feb 28/29).
DateTime addMonths(DateTime d, int months) {
  final total = d.month - 1 + months;
  final year = d.year + total ~/ 12;
  final month = total % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, math.min(d.day, lastDay), d.hour, d.minute);
}
