// Tests for the "Current Vehicle" feature: the placeholder vehicle registry
// and AppState's currentVehicle selection.

import 'package:flutter_test/flutter_test.dart';
import 'package:new_app/app_state.dart';
import 'package:new_app/vehicle.dart';

void main() {
  test('exactly one vehicle is registered right now', () {
    expect(vehicles, hasLength(1));
  });

  test('the placeholder vehicle is the 2026 Tacoma SR5', () {
    expect(vehicles.first.displayName, '2026 Toyota Tacoma SR5');
  });

  test('vehicle ids are unique', () {
    expect(vehicles.map((v) => v.id).toSet().length, vehicles.length);
  });

  test('a fresh vehicle has no license plate, color, or notes', () {
    expect(vehicles.first.licensePlate, isEmpty);
    expect(vehicles.first.color, isEmpty);
    expect(vehicles.first.notes, isEmpty);
  });

  group('Vehicle.copyWith', () {
    test('changes only the given fields', () {
      final original = vehicles.first;
      final updated = original.copyWith(licensePlate: 'ABC 1234');

      expect(updated.licensePlate, 'ABC 1234');
      expect(updated.year, original.year);
      expect(updated.make, original.make);
      expect(updated.model, original.model);
      expect(updated.trim, original.trim);
      expect(updated.id, original.id); // id is never editable
      expect(updated.imagePath, original.imagePath);
    });

    test('with nothing given returns an equivalent vehicle', () {
      final original = vehicles.first;
      final same = original.copyWith();
      expect(same.displayName, original.displayName);
      expect(same.licensePlate, original.licensePlate);
    });
  });

  group('AppState.currentVehicle', () {
    test('defaults to the first registered vehicle', () {
      expect(AppState().currentVehicle, vehicles.first);
    });

    test('setCurrentVehicle updates it and notifies listeners', () {
      final state = AppState();
      var calls = 0;
      state.addListener(() => calls++);

      // Only one vehicle exists today, so this is a no-op switch in practice,
      // but the path must still work correctly for when a second one exists.
      state.setCurrentVehicle(vehicles.first);

      expect(state.currentVehicle, vehicles.first);
      expect(calls, 1);
    });
  });

  group('AppState.updateVehicle', () {
    test('saves the edited fields into vehiclesList', () {
      final state = AppState();
      final edited = state.vehiclesList.first.copyWith(
        licensePlate: 'MTG-4517',
        color: 'Magnetic Gray Metallic',
        notes: 'Bought used with 12,000 miles on it.',
      );

      state.updateVehicle(edited);

      final saved = state.vehiclesList.first;
      expect(saved.licensePlate, 'MTG-4517');
      expect(saved.color, 'Magnetic Gray Metallic');
      expect(saved.notes, 'Bought used with 12,000 miles on it.');
    });

    test('updates currentVehicle too when editing the selected vehicle', () {
      final state = AppState();
      final edited = state.currentVehicle.copyWith(licensePlate: 'XYZ-999');

      state.updateVehicle(edited);

      expect(state.currentVehicle.licensePlate, 'XYZ-999');
    });

    test('notifies listeners on a successful update', () {
      final state = AppState();
      var calls = 0;
      state.addListener(() => calls++);

      state.updateVehicle(state.currentVehicle.copyWith(color: 'Black'));

      expect(calls, 1);
    });

    test('an unknown vehicle id is silently ignored', () {
      final state = AppState();
      var calls = 0;
      state.addListener(() => calls++);
      final before = state.vehiclesList.first.licensePlate;

      state.updateVehicle(
        const Vehicle(
          id: 'not_a_real_vehicle',
          year: 2000,
          make: 'Nobody',
          model: 'Nothing',
          trim: 'N/A',
          imagePath: 'assets/images/tacoma.png',
        ),
      );

      expect(state.vehiclesList.first.licensePlate, before);
      expect(calls, 0);
    });
  });
}
