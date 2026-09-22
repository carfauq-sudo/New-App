// Smoke test: the app starts and shows the home page with a computed Oil tile.

import 'package:flutter_test/flutter_test.dart';
import 'package:new_app/main.dart';

void main() {
  testWidgets('home page shows the vehicle and the computed Oil tile', (
    tester,
  ) async {
    await tester.pumpWidget(const MaintenanceGoApp());

    // The reference data (oil interval) loads in the background, like it does
    // in the real app. Give it real time to finish, then redraw. Until it
    // arrives the tile shows a dash and nothing is blocked.
    expect(find.text('—'), findsOneWidget);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('My vehicle'), findsOneWidget);
    expect(find.text('Maintenance logs'), findsOneWidget);
    expect(find.text('Oil (est.)'), findsOneWidget);
    // Computed from the placeholder oil-change log (39,100 mi -> 42,180 mi).
    expect(find.text('69%'), findsOneWidget);
  });
}
