// Tests for Appearance settings: the stored (but not yet applied) units and
// dark-mode preferences.

import 'package:flutter_test/flutter_test.dart';
import 'package:new_app/app_preferences.dart';
import 'package:new_app/app_state.dart';

void main() {
  test('defaults are miles and dark mode on', () {
    expect(placeholderPreferences.units, DistanceUnit.miles);
    expect(placeholderPreferences.darkMode, isTrue);
  });

  group('AppPreferences.copyWith', () {
    test('changes only the given field', () {
      final metric = placeholderPreferences.copyWith(
        units: DistanceUnit.kilometers,
      );
      expect(metric.units, DistanceUnit.kilometers);
      expect(metric.darkMode, placeholderPreferences.darkMode);

      final light = placeholderPreferences.copyWith(darkMode: false);
      expect(light.darkMode, isFalse);
      expect(light.units, placeholderPreferences.units);
    });
  });

  group('AppState.preferences', () {
    test('defaults to miles and dark mode on', () {
      final state = AppState();
      expect(state.preferences.units, DistanceUnit.miles);
      expect(state.preferences.darkMode, isTrue);
    });

    test('setPreferences updates it and notifies listeners', () {
      final state = AppState();
      var calls = 0;
      state.addListener(() => calls++);

      state.setPreferences(
        state.preferences.copyWith(units: DistanceUnit.kilometers),
      );

      expect(state.preferences.units, DistanceUnit.kilometers);
      expect(calls, 1);
    });
  });
}
