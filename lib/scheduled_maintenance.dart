// Upcoming maintenance that has been scheduled or is coming due, shown on the
// calendar page. Placeholder data for now; later this will be generated from
// service intervals and the vehicle's maintenance history.

class ScheduledMaintenance {
  final String title;
  final String shortLabel; // fits inside a small calendar cell
  final DateTime date; // only the year/month/day matter for the calendar
  final String part;
  final int? dueMileage; // optional: not everything is due at a mileage
  final int? estimatedCents; // optional: null = no estimate yet
  final String notes;

  const ScheduledMaintenance({
    required this.title,
    required this.shortLabel,
    required this.date,
    required this.part,
    this.dueMileage,
    this.estimatedCents,
    this.notes = '',
  });
}

// Dates are fixed (not relative to "today") so the placeholder calendar looks
// the same every time. They fall in the months around September 2026.
// A day count relative to today, phrased for a countdown: "Today",
// "Tomorrow", "in N days", or "in N months" for anything further out.
// <= 0 (today, or already past due) reads as "Today" rather than a
// confusing negative count.
String relativeDaysLabel(int daysAway) {
  if (daysAway <= 0) return 'Today';
  if (daysAway == 1) return 'Tomorrow';
  if (daysAway < 60) return 'in $daysAway days';
  return 'in ${(daysAway / 30).round()} months';
}

final placeholderScheduled = <ScheduledMaintenance>[
  ScheduledMaintenance(
    title: 'Tire rotation',
    shortLabel: 'Tires',
    date: DateTime(2026, 9, 28),
    part: 'Wheels & Brakes › Wheel',
    dueMileage: 43000,
    estimatedCents: 0,
    notes: 'Every 5,000 miles. Do it yourself or have the shop do it.',
  ),
  ScheduledMaintenance(
    title: 'Brake inspection',
    shortLabel: 'Brakes',
    date: DateTime(2026, 10, 6),
    part: 'Wheels & Brakes › Brakes',
    dueMileage: 43500,
    estimatedCents: 4000,
    notes: 'Check pad thickness and rotor wear. Pads were replaced in June.',
  ),
  ScheduledMaintenance(
    title: 'Oil & filter change',
    shortLabel: 'Oil',
    date: DateTime(2026, 10, 14),
    part: 'Engine',
    dueMileage: 44000,
    estimatedCents: 7500,
    notes: 'Synthetic 0W-20. About 6 quarts.',
  ),
  ScheduledMaintenance(
    title: 'Cabin air filter',
    shortLabel: 'Filter',
    date: DateTime(2026, 10, 14),
    part: 'Interior',
    dueMileage: 44000,
    estimatedCents: 2200,
    notes: 'Easy DIY job behind the glove box.',
  ),
  ScheduledMaintenance(
    title: 'Wiper blades',
    shortLabel: 'Wipers',
    date: DateTime(2026, 10, 30),
    part: 'Windows & Tint',
    dueMileage: 45000,
    estimatedCents: 3000,
    notes: 'Replace before winter.',
  ),
  ScheduledMaintenance(
    title: 'Coolant flush',
    shortLabel: 'Coolant',
    date: DateTime(2026, 11, 12),
    part: 'Engine',
    dueMileage: 46000,
    estimatedCents: 12000,
  ),
  ScheduledMaintenance(
    title: 'Transmission fluid service',
    shortLabel: 'Trans.',
    date: DateTime(2026, 12, 3),
    part: 'Drivetrain',
    dueMileage: 48000,
    estimatedCents: 18000,
    notes: 'Drain and fill with the factory-spec fluid.',
  ),
];
