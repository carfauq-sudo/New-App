// Tests for the Profile feature: the placeholder profile and AppState's
// profile storage.

import 'package:flutter_test/flutter_test.dart';
import 'package:new_app/app_state.dart';
import 'package:new_app/user_profile.dart';

void main() {
  test('the placeholder profile is a fake sample person, not a real one', () {
    // This is source-controlled placeholder data; it must never be a real
    // person's real contact info.
    expect(placeholderProfile.name, 'Alex Morgan');
    expect(placeholderProfile.email, 'alex.morgan@example.com');
  });

  group('UserProfile.copyWith', () {
    test('changes only the given fields', () {
      final updated = placeholderProfile.copyWith(name: 'Jordan Lee');

      expect(updated.name, 'Jordan Lee');
      expect(updated.email, placeholderProfile.email);
      expect(updated.phone, placeholderProfile.phone);
      expect(updated.memberSince, placeholderProfile.memberSince);
    });

    test('memberSince is never editable through copyWith', () {
      // No memberSince parameter exists on copyWith at all — this just
      // documents that omitting every argument leaves it untouched.
      final same = placeholderProfile.copyWith();
      expect(same.memberSince, placeholderProfile.memberSince);
    });
  });

  group('AppState.profile', () {
    test('defaults to the placeholder profile', () {
      expect(AppState().profile.name, placeholderProfile.name);
    });

    test('setProfile updates it and notifies listeners', () {
      final state = AppState();
      var calls = 0;
      state.addListener(() => calls++);

      state.setProfile(placeholderProfile.copyWith(name: 'Sam Rivera'));

      expect(state.profile.name, 'Sam Rivera');
      expect(calls, 1);
    });
  });
}
