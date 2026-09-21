// Integrity checks for the reference data. If someone edits the JSON and
// breaks a link or drops a page number, this fails before the app ships.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:new_app/data/vehicle_reference.dart';

void main() {
  late VehicleReference ref;

  setUpAll(() {
    final text = File('assets/data/toyota_tacoma_2026.json').readAsStringSync();
    ref = VehicleReference.parse(text);
  });

  test('loads and has content in every section', () {
    expect(ref.sourceCode, 'OM04051U');
    expect(ref.specs, isNotEmpty);
    expect(ref.tireConfigs, isNotEmpty);
    expect(ref.procedures, isNotEmpty);
    expect(ref.generalChecks, isNotEmpty);
    expect(ref.serviceTypes, isNotEmpty);
  });

  test('ids are unique within each section', () {
    void unique(Iterable<String> ids, String what) {
      expect(ids.toSet().length, ids.length, reason: 'duplicate id in $what');
    }

    unique(ref.specs.map((e) => e.id), 'specs');
    unique(ref.tireConfigs.map((e) => e.id), 'tire_configs');
    unique(ref.procedures.map((e) => e.id), 'procedures');
    unique(ref.generalChecks.map((e) => e.id), 'general_checks');
    unique(ref.serviceTypes.map((e) => e.id), 'service_types');
  });

  test('every service type points at specs and procedures that exist', () {
    for (final t in ref.serviceTypes) {
      for (final id in t.specIds) {
        expect(ref.spec(id), isNotNull, reason: '${t.id} -> missing spec $id');
      }
      for (final id in [t.procedureId, t.resetProcedureId]) {
        if (id != null) {
          expect(
            ref.procedure(id),
            isNotNull,
            reason: '${t.id} -> missing procedure $id',
          );
        }
      }
    }
  });

  test('every fact cites a plausible manual page', () {
    final pages = [
      ...ref.specs.map((e) => e.page),
      ...ref.tireConfigs.map((e) => e.page),
      ...ref.procedures.map((e) => e.page),
      ...ref.generalChecks.map((e) => e.page),
    ];
    for (final p in pages) {
      expect(p, inInclusiveRange(1, 720));
    }
  });

  test('tire pressures are sane', () {
    for (final t in ref.tireConfigs) {
      expect(t.pressurePsi, inInclusiveRange(20, 80), reason: t.id);
    }
  });

  test('every interval and milestone cites a source that exists', () {
    final sources = {for (final s in ref.scheduleSources) s.id: s};
    for (final st in ref.serviceTypes) {
      for (final i in st.intervals) {
        final src = sources[i['source_id']];
        expect(src, isNotNull, reason: '${st.id} interval has unknown source');
        // Nothing may claim to be official unless its source really is.
        if (!src!.official) {
          expect(i['status'], isNot('official'), reason: st.id);
        }
      }
    }
    for (final m in ref.scheduleMilestones) {
      expect(sources[m.sourceId], isNotNull, reason: '${m.miles} mi');
      for (final task in m.tasks) {
        final id = task.serviceTypeId;
        if (id != null) {
          expect(ref.serviceType(id), isNotNull, reason: '${m.miles}: $id');
        }
      }
    }
  });

  test('milestones are in order and the dealer schedule is flagged', () {
    final miles = ref.scheduleMilestones.map((m) => m.miles).toList();
    expect(miles, [...miles]..sort());
    final dealer = ref.scheduleSources.first;
    expect(dealer.official, isFalse);
    expect(dealer.verifiedAgainstToyotaGuide, isFalse);
    expect(dealer.caveats, isNotEmpty);
  });

  test('default schedule is a known source and is labeled provisional', () {
    final src = ref.defaultScheduleSource;
    expect(src.official, isFalse);
    expect(src.trustTier, 'provisional');
    // Provisional data must never be labeled as verified.
    expect(src.verifiedAgainstToyotaGuide, isFalse);
  });

  test('lookups work', () {
    expect(ref.spec('oil_viscosity')!.value, 'SAE 0W-20');
    expect(
      ref.serviceType('oil_change')!.resetProcedureId,
      'reset_oil_maintenance',
    );
    expect(ref.specsFor(ref.serviceType('oil_change')!), isNotEmpty);
  });
}
