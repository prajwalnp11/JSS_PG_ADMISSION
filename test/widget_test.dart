import 'package:flutter_test/flutter_test.dart';
import 'package:pg_admission_app/main.dart';

void main() {
  testWidgets('Smoke test JSS admission app', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const JssAdmissionApp());

    // Verify that our dashboard title is shown.
    expect(find.text('JSS COLLEGE OF ARTS, COMMERCE & SCIENCE'), findsOneWidget);
  });
}
