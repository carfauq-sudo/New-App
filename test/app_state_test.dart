// The Oil life tile's behavior, end to end without the screen: logs and stats
// go in, the computed life comes out, and it updates as they change.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:new_app/app_state.dart';
import 'package:new_app/data/vehicle_reference.dart';
import 'package:new_app/maintenance_record.dart';

void main() {
  late ServiceType oil;
  final now = DateTime(2026, 9, 21, 12);

  setUpAll(() {
    final ref = VehicleReference.parse(
      File('assets/data/toyota_tacoma_2026.json').readAsStringSync(),
    );
    oil = ref.serviceType('oil_change')!;
  });

  test(
    'placeholder data: last oil change 39,100 mi, now 42,180 -> 69% left',
    () {
      final life = AppState().lifeFor(oil, now)!;
      expect(life.lastService.id, 'r12');
      expect(life.result.milesUsed, 3080);
      expect(life.result.percentLeft, 69);
      expect(life.isProvisional, isTrue); // interval is from the dealer page
    },
  );

  test('logging a newer oil change resets the tile', () {
    final state = AppState();
    state.addRecord(
      MaintenanceRecord(
        id: 'new',
        serviceTypeId: 'oil_change',
        title: 'Oil change',
        part: 'Engine',
        kind: RecordKind.maintenance,
        date: DateTime(2026, 9, 20),
        mileage: 42100,
        performedBy: 'DIY',
        items: const [],
      ),
    );
    final life = state.lifeFor(oil, now)!;
    expect(life.lastService.id, 'new');
    expect(life.result.percentLeft, 99); // 80 of 10,000 miles used
  });

  test('deleting the only oil change leaves nothing to compute', () {
    final state = AppState()..removeRecord('r12');
    expect(state.lifeFor(oil, now), isNull);
  });

  test('changes notify listeners so the tile rebuilds', () {
    final state = AppState();
    var calls = 0;
    state.addListener(() => calls++);
    state.removeRecord('r12');
    expect(calls, 1);
  });

  test('a log that is not tagged as an oil change is ignored', () {
    final state = AppState();
    state.addRecord(
      MaintenanceRecord(
        id: 'untagged',
        title: 'Oil change (untagged)',
        part: 'Engine',
        kind: RecordKind.maintenance,
        date: DateTime(2026, 9, 20),
        mileage: 42100,
        performedBy: 'DIY',
        items: const [],
      ),
    );
    expect(state.lifeFor(oil, now)!.lastService.id, 'r12');
  });
}
