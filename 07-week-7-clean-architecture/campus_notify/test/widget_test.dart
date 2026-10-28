import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_notify/main.dart';

void main() {
  testWidgets('CampusNotifyApp loads login page smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: CampusNotifyApp()));

    expect(find.text('Campus Notify'), findsOneWidget);
  });
}
