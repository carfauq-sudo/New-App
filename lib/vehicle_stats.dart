// Live-ish stats about the vehicle (the kind you read off the dashboard).
// User-entered for now; the plan is to fill these in from dashboard photos
// later (needs camera access and a way to read the photo).

class VehicleStats {
  final int mileage; // odometer reading
  final double avgMpg;
  final int oilLifePercent; // 0-100
  final int tirePsi;
  final DateTime updated; // when the user last entered these

  const VehicleStats({
    required this.mileage,
    required this.avgMpg,
    required this.oilLifePercent,
    required this.tirePsi,
    required this.updated,
  });
}

// Placeholder values shown until the user enters their own.
final placeholderStats = VehicleStats(
  mileage: 42180,
  avgMpg: 22.4,
  oilLifePercent: 60,
  tirePsi: 35,
  updated: DateTime(2026, 9, 21),
);
