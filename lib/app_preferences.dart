// Appearance preferences: units and dark/light mode. Stored for real (and
// persists for the session, same as everything else pending local storage),
// but NOT yet applied anywhere:
//  * Units: every mileage in the app (stats, logs, the calendar, the
//    reference data) is hardcoded to miles regardless of this setting.
//    Actually converting would mean touching every place a distance is
//    formatted or entered.
//  * Dark mode: the app's whole palette (AppColors in main.dart) is a set of
//    `static const` colors used inside many `const` widgets. Making this
//    toggle actually re-theme the app means turning those into theme-aware,
//    non-const lookups — a much bigger, separate change, not something to do
//    as a side effect of adding a settings toggle.
// See CLAUDE.md's "Deferred work" section.

enum DistanceUnit { miles, kilometers }

class AppPreferences {
  final DistanceUnit units;
  final bool darkMode;

  const AppPreferences({this.units = DistanceUnit.miles, this.darkMode = true});

  AppPreferences copyWith({DistanceUnit? units, bool? darkMode}) {
    return AppPreferences(
      units: units ?? this.units,
      darkMode: darkMode ?? this.darkMode,
    );
  }
}

// Defaults: miles, dark mode on — matching the app's current, only behavior.
const placeholderPreferences = AppPreferences();
