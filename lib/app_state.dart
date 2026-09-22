// Shared, in-memory app data. Screens listen to this so that changing a log or
// the stats updates everything that depends on them (the Oil life tile, the
// log list...) without each screen keeping its own copy.
//
// NOTE: this is memory only for now; it resets when the app restarts because
// the local storage layer isn't built yet.

import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'calc/maintenance_math.dart';
import 'data/vehicle_reference.dart';
import 'maintenance_record.dart';
import 'scheduled_maintenance.dart';
import 'vehicle_stats.dart';

class AppState extends ChangeNotifier {
  VehicleStats _stats = placeholderStats;
  final List<MaintenanceRecord> _records = [...placeholderRecords];
  final List<ScheduledMaintenance> _scheduled = [...placeholderScheduled];

  VehicleStats get stats => _stats;

  /// Newest first.
  List<MaintenanceRecord> get records => UnmodifiableListView(_records);

  List<ScheduledMaintenance> get scheduled => UnmodifiableListView(_scheduled);

  void setStats(VehicleStats stats) {
    _stats = stats;
    notifyListeners();
  }

  void addRecord(MaintenanceRecord record) {
    _records.add(record);
    _records.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  void removeRecord(String id) {
    _records.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  void addScheduled(ScheduledMaintenance item) {
    _scheduled.add(item);
    notifyListeners();
  }

  /// Scheduled items on or after [now], soonest first.
  List<ScheduledMaintenance> upcomingScheduled(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = _scheduled.where((m) => !m.date.isBefore(today)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return upcoming;
  }

  /// Everything scheduled on one calendar day.
  List<ScheduledMaintenance> scheduledOn(DateTime date) => _scheduled
      .where(
        (m) =>
            m.date.year == date.year &&
            m.date.month == date.month &&
            m.date.day == date.day,
      )
      .toList();

  /// Every odometer reading we know about: the stats entry plus each log that
  /// recorded a mileage.
  List<OdometerReading> get odometerReadings => [
    OdometerReading(_stats.updated, _stats.mileage),
    for (final r in _records)
      if (r.mileage > 0) OdometerReading(r.date, r.mileage),
  ];

  /// The most recent record of any kind, by date, or null with no records.
  MaintenanceRecord? get lastService {
    MaintenanceRecord? best;
    for (final r in _records) {
      if (best == null || r.date.isAfter(best.date)) best = r;
    }
    return best;
  }

  /// The most recent log of a given service type (by date), or null.
  MaintenanceRecord? latestOf(String serviceTypeId) {
    MaintenanceRecord? best;
    for (final r in _records) {
      if (r.serviceTypeId != serviceTypeId) continue;
      if (best == null || r.date.isAfter(best.date)) best = r;
    }
    return best;
  }

  MileageEstimate? mileageEstimate(DateTime now) =>
      estimateMileage(odometerReadings, now);

  /// Best current-mileage guess for pre-filling a form: the estimate if one
  /// can be computed, otherwise the last mileage the user entered directly.
  int currentMileageEstimate(DateTime now) =>
      mileageEstimate(now)?.miles ?? _stats.mileage;

  /// Life left for an interval service (e.g. 'oil_change'), or null when there
  /// is nothing honest to compute: no log of that service, no interval on
  /// record, or no odometer reading.
  ServiceLife? lifeFor(ServiceType type, DateTime now) {
    final last = latestOf(type.id);
    if (last == null || type.intervals.isEmpty) return null;
    final interval = type.intervals.first;
    final mileage = mileageEstimate(now);
    if (mileage == null) return null;

    final result = computeLife(
      lastServiceMiles: last.mileage,
      lastServiceDate: last.date,
      currentMiles: mileage.miles,
      now: now,
      intervalMiles: interval['miles'] as int?,
      intervalMonths: interval['months'] as int?,
      milesPerDay: mileage.milesPerDay,
    );
    if (result == null) return null;
    return ServiceLife(
      result: result,
      lastService: last,
      mileage: mileage,
      intervalMiles: interval['miles'] as int?,
      intervalMonths: interval['months'] as int?,
      intervalStatus: (interval['status'] as String?) ?? type.intervalStatus,
    );
  }
}

/// A computed [LifeResult] plus what it was based on, so the UI can explain it.
class ServiceLife {
  final LifeResult result;
  final MaintenanceRecord lastService;
  final MileageEstimate mileage;
  final int? intervalMiles;
  final int? intervalMonths;
  final String intervalStatus; // e.g. 'third_party_unverified'

  const ServiceLife({
    required this.result,
    required this.lastService,
    required this.mileage,
    required this.intervalMiles,
    required this.intervalMonths,
    required this.intervalStatus,
  });

  bool get isProvisional => intervalStatus != 'official';
}
