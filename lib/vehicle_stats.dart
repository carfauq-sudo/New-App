// Live-ish stats about the vehicle (the kind you read off the dashboard).
// User-entered for now; the plan is to fill these in from dashboard photos
// later (needs camera access and a way to read the photo).

class VehicleStats {
  final int mileage; // odometer reading
  final double avgMpg;
  final int oilLifePercent; // 0-100
  final int tirePsi; // the single reading shown/edited on the dashboard form
  final DateTime updated; // when the user last entered these

  // Per-tire pressures, for the "Tire pressures" detail sheet. Independent of
  // tirePsi above (that's a single dashboard reading; these are per-wheel and
  // not derived from it) — placeholders until dashboard photos exist.
  final int frontLeftPsi;
  final int frontRightPsi;
  final int rearLeftPsi;
  final int rearRightPsi;

  const VehicleStats({
    required this.mileage,
    required this.avgMpg,
    required this.oilLifePercent,
    required this.tirePsi,
    required this.updated,
    this.frontLeftPsi = 35,
    this.frontRightPsi = 35,
    this.rearLeftPsi = 34,
    this.rearRightPsi = 34,
  });
}

// Placeholder values shown until the user enters their own.
final placeholderStats = VehicleStats(
  mileage: 42180,
  avgMpg: 22.4,
  oilLifePercent: 60,
  tirePsi: 35,
  updated: DateTime(2026, 9, 21),
  frontLeftPsi: 35,
  frontRightPsi: 36,
  rearLeftPsi: 34,
  rearRightPsi: 34,
);
