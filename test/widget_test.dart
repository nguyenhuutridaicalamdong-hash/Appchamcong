import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenhuutri/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AttendanceApp());
    expect(find.text('App Chấm Công'), findsOneWidget);
  });
}
