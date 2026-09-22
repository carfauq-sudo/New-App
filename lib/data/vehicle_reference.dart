// Read-only reference data about the vehicle, loaded from the manufacturer's
// owner's manual (see assets/data/toyota_tacoma_2026.json).
//
// Design rules, so this data can grow without slowing the app down:
//  * The data is a bundled, read-only asset. It is NOT the user's records.
//    Logs, the schedule, and stats live elsewhere and refer to reference items
//    by id only (e.g. a log's service type is "oil_change").
//  * It loads once, lazily, and is parsed off the UI thread. Screens should
//    never wait on it: show the screen first, fill in the details when the
//    future completes, and cope with it being missing.
//  * Every fact carries the manual page it came from, so the UI can cite it.
//  * The loader is behind a small class, so the JSON can later be swapped for
//    SQLite (or a server) without touching the screens.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One fact from the manual, e.g. "Engine oil viscosity: SAE 0W-20".
class SpecItem {
  final String id;
  final String category;
  final String label;
  final String value;
  final int page; // printed page number in the manual
  final String? notes;
  final List<String> appliesTo; // model codes or conditions; empty = all

  const SpecItem({
    required this.id,
    required this.category,
    required this.label,
    required this.value,
    required this.page,
    this.notes,
    this.appliesTo = const [],
  });

  factory SpecItem.fromJson(Map<String, dynamic> j) => SpecItem(
    id: j['id'] as String,
    category: j['category'] as String,
    label: j['label'] as String,
    value: j['value'] as String,
    page: j['page'] as int,
    notes: j['notes'] as String?,
    appliesTo: (j['applies_to'] as List?)?.cast<String>() ?? const [],
  );
}

/// One tire/wheel combination the truck can have (types A-D at 17", A-C at 18").
class TireConfig {
  final String id;
  final String label;
  final String tireSize;
  final String spareTireSize;
  final int pressurePsi;
  final int? sparePressurePsi; // null = the manual gives none
  final String wheelSize;
  final String spareWheelSize;
  final int? lugTorqueSteelFtLbf; // null = the manual gives none
  final int? lugTorqueAluminumFtLbf;
  final int page;

  const TireConfig({
    required this.id,
    required this.label,
    required this.tireSize,
    required this.spareTireSize,
    required this.pressurePsi,
    required this.sparePressurePsi,
    required this.wheelSize,
    required this.spareWheelSize,
    required this.lugTorqueSteelFtLbf,
    required this.lugTorqueAluminumFtLbf,
    required this.page,
  });

  factory TireConfig.fromJson(Map<String, dynamic> j) {
    final torque = j['lug_torque_ftlbf'] as Map<String, dynamic>;
    return TireConfig(
      id: j['id'] as String,
      label: j['label'] as String,
      tireSize: j['tire_size'] as String,
      spareTireSize: j['spare_tire_size'] as String,
      pressurePsi: j['pressure_psi'] as int,
      sparePressurePsi: j['spare_pressure_psi'] as int?,
      wheelSize: j['wheel_size'] as String,
      spareWheelSize: j['spare_wheel_size'] as String,
      lugTorqueSteelFtLbf: torque['steel'] as int?,
      lugTorqueAluminumFtLbf: torque['aluminum'] as int?,
      page: j['page'] as int,
    );
  }
}

/// A how-to, e.g. checking the engine oil.
class Procedure {
  final String id;
  final String title;
  final List<String> steps;
  final List<String> warnings;
  final String? notes;
  final int page;

  const Procedure({
    required this.id,
    required this.title,
    required this.steps,
    required this.warnings,
    required this.page,
    this.notes,
  });

  factory Procedure.fromJson(Map<String, dynamic> j) => Procedure(
    id: j['id'] as String,
    title: j['title'] as String,
    steps: (j['steps'] as List).cast<String>(),
    warnings: (j['warnings'] as List?)?.cast<String>() ?? const [],
    notes: j['notes'] as String?,
    page: j['page'] as int,
  );
}

/// One of the manual's routine "General maintenance" checks.
class GeneralCheck {
  final String id;
  final String area; // engine_compartment / interior / exterior
  final String item;
  final List<String> checkPoints;
  final int page;

  const GeneralCheck({
    required this.id,
    required this.area,
    required this.item,
    required this.checkPoints,
    required this.page,
  });

  factory GeneralCheck.fromJson(Map<String, dynamic> j) => GeneralCheck(
    id: j['id'] as String,
    area: j['area'] as String,
    item: j['item'] as String,
    checkPoints: (j['check_points'] as List).cast<String>(),
    page: j['page'] as int,
  );
}

/// A kind of service (oil change, tire rotation...) tying together the specs
/// and procedures that go with it. This is the id user logs point at.
///
/// [intervals] comes from a schedule source and carries its own status. The
/// owner's manual has no intervals (see `pending_sources`), so anything here is
/// third-party and unverified until Toyota's guide is loaded.
class ServiceType {
  final String id;
  final String name;
  final String category;
  final String appPart; // matches the part names used in the app's forms
  final bool diyPossible;
  final List<String> specIds;
  final String? procedureId;
  final String? resetProcedureId;
  final List<Map<String, dynamic>> intervals;
  final String intervalStatus;
  final String? notes;

  const ServiceType({
    required this.id,
    required this.name,
    required this.category,
    required this.appPart,
    required this.diyPossible,
    required this.specIds,
    required this.procedureId,
    required this.resetProcedureId,
    required this.intervals,
    required this.intervalStatus,
    this.notes,
  });

  factory ServiceType.fromJson(Map<String, dynamic> j) => ServiceType(
    id: j['id'] as String,
    name: j['name'] as String,
    category: j['category'] as String,
    appPart: j['app_part'] as String,
    diyPossible: j['diy_possible'] as bool,
    specIds: (j['spec_ids'] as List).cast<String>(),
    procedureId: j['procedure_id'] as String?,
    resetProcedureId: j['reset_procedure_id'] as String?,
    intervals: (j['intervals'] as List).cast<Map<String, dynamic>>(),
    intervalStatus: j['interval_status'] as String,
    notes: j['notes'] as String?,
  );

  bool get hasIntervals => intervals.isNotEmpty;
}

/// Where a schedule came from, and how far to trust it.
class ScheduleSource {
  final String id;
  final String title;
  final String publisher;
  final String? url;
  final bool official; // false = e.g. a dealership website
  final String trustTier; // 'official' or 'provisional'
  final bool verifiedAgainstToyotaGuide;
  final List<String> caveats;

  const ScheduleSource({
    required this.id,
    required this.title,
    required this.publisher,
    required this.url,
    required this.official,
    required this.trustTier,
    required this.verifiedAgainstToyotaGuide,
    required this.caveats,
  });

  factory ScheduleSource.fromJson(Map<String, dynamic> j) => ScheduleSource(
    id: j['id'] as String,
    title: j['title'] as String,
    publisher: j['publisher'] as String,
    url: j['url'] as String?,
    official: j['official'] as bool,
    trustTier: j['trust_tier'] as String,
    verifiedAgainstToyotaGuide: j['verified_against_toyota_guide'] as bool,
    caveats: (j['caveats'] as List).cast<String>(),
  );
}

/// One task listed at a mileage milestone (e.g. "Rotate tires" at 5,000 mi).
class ScheduleTask {
  final String text; // as written by the source
  final String kind; // task / repeat_previous / inspect_components
  final String? serviceTypeId; // set only where it clearly matches
  final String? drivetrain; // e.g. '4wd' when it only applies to 4WD
  final List<String> components;

  const ScheduleTask({
    required this.text,
    required this.kind,
    this.serviceTypeId,
    this.drivetrain,
    this.components = const [],
  });

  factory ScheduleTask.fromJson(Map<String, dynamic> j) => ScheduleTask(
    text: j['text'] as String,
    kind: j['kind'] as String,
    serviceTypeId: j['service_type_id'] as String?,
    drivetrain: j['drivetrain'] as String?,
    components: (j['components'] as List?)?.cast<String>() ?? const [],
  );
}

/// Everything a schedule says to do at one mileage.
class ScheduleMilestone {
  final int miles;
  final String sourceId;
  final List<ScheduleTask> tasks;

  const ScheduleMilestone({
    required this.miles,
    required this.sourceId,
    required this.tasks,
  });

  factory ScheduleMilestone.fromJson(Map<String, dynamic> j) =>
      ScheduleMilestone(
        miles: j['miles'] as int,
        sourceId: j['source_id'] as String,
        tasks: (j['tasks'] as List)
            .map((e) => ScheduleTask.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

/// Everything loaded from one vehicle's reference file. Lookups by id are
/// constant-time (maps are built once when the data is parsed).
class VehicleReference {
  final int schemaVersion;
  final String dataVersion;
  final String sourceTitle;
  final String sourceCode;
  final List<SpecItem> specs;
  final List<TireConfig> tireConfigs;
  final List<Procedure> procedures;
  final List<GeneralCheck> generalChecks;
  final List<ServiceType> serviceTypes;
  final List<ScheduleSource> scheduleSources;
  final List<ScheduleMilestone> scheduleMilestones;
  // Which schedule the app uses until an exact VIN-based lookup replaces it.
  final String defaultScheduleSourceId;

  final Map<String, SpecItem> _specById;
  final Map<String, Procedure> _procedureById;
  final Map<String, ServiceType> _serviceById;

  VehicleReference._({
    required this.schemaVersion,
    required this.dataVersion,
    required this.sourceTitle,
    required this.sourceCode,
    required this.specs,
    required this.tireConfigs,
    required this.procedures,
    required this.generalChecks,
    required this.serviceTypes,
    required this.scheduleSources,
    required this.scheduleMilestones,
    required this.defaultScheduleSourceId,
  }) : _specById = {for (final s in specs) s.id: s},
       _procedureById = {for (final p in procedures) p.id: p},
       _serviceById = {for (final s in serviceTypes) s.id: s};

  /// Builds the data from the JSON text. Runs off the UI thread (see the
  /// loader below), so keep it free of Flutter-only calls.
  factory VehicleReference.parse(String jsonText) {
    final j = jsonDecode(jsonText) as Map<String, dynamic>;
    final source = j['source'] as Map<String, dynamic>;
    List<T> list<T>(String key, T Function(Map<String, dynamic>) f) =>
        (j[key] as List)
            .map((e) => f(e as Map<String, dynamic>))
            .toList(growable: false);
    return VehicleReference._(
      schemaVersion: j['schema_version'] as int,
      dataVersion: j['data_version'] as String,
      sourceTitle: source['title'] as String,
      sourceCode: source['document_code'] as String,
      specs: list('specs', SpecItem.fromJson),
      tireConfigs: list('tire_configs', TireConfig.fromJson),
      procedures: list('procedures', Procedure.fromJson),
      generalChecks: list('general_checks', GeneralCheck.fromJson),
      serviceTypes: list('service_types', ServiceType.fromJson),
      scheduleSources: list('schedule_sources', ScheduleSource.fromJson),
      scheduleMilestones: list(
        'schedule_milestones',
        ScheduleMilestone.fromJson,
      ),
      defaultScheduleSourceId: j['default_schedule_source_id'] as String,
    );
  }

  /// The schedule the app currently uses, and how far to trust it. Null if
  /// the data's default_schedule_source_id doesn't match any schedule_sources
  /// entry (a data-file mistake), so callers degrade gracefully instead of
  /// crashing.
  ScheduleSource? get defaultScheduleSource {
    for (final source in scheduleSources) {
      if (source.id == defaultScheduleSourceId) return source;
    }
    return null;
  }

  SpecItem? spec(String id) => _specById[id];
  Procedure? procedure(String id) => _procedureById[id];
  ServiceType? serviceType(String id) => _serviceById[id];

  List<SpecItem> specsIn(String category) =>
      specs.where((s) => s.category == category).toList(growable: false);

  /// The specs listed for a service type (e.g. all the oil specs for
  /// "oil_change"), skipping any id that isn't found.
  List<SpecItem> specsFor(ServiceType type) => [
    for (final id in type.specIds)
      if (_specById[id] != null) _specById[id]!,
  ];
}

// Top-level so it can run in a background isolate via `compute`.
VehicleReference _parseInBackground(String jsonText) =>
    VehicleReference.parse(jsonText);

/// Loads the reference data once and hands out the same result afterwards.
class ReferenceRepository {
  ReferenceRepository._();
  static final instance = ReferenceRepository._();

  static const _asset = 'assets/data/toyota_tacoma_2026.json';

  Future<VehicleReference>? _cached;

  /// Safe to call from anywhere, any number of times: the file is read and
  /// parsed once, in the background. If it fails, the error is in the future,
  /// so screens should handle that instead of crashing.
  Future<VehicleReference> load() => _cached ??= _load();

  Future<VehicleReference> _load() async {
    final text = await rootBundle.loadString(_asset);
    return compute(_parseInBackground, text);
  }
}
