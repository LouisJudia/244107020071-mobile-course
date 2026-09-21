// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:week4_api/main.dart';
import 'package:week4_api/data/paged_posts.dart';

class _TestPagedPostsNotifier extends PagedPostsNotifier {
  @override
  PagedPostsState build() => const PagedPostsState(hasMore: false);
}

void main() {
  testWidgets('halaman posts dapat dirender', (WidgetTester tester) async {
    // ProviderScope diperlukan karena halaman memakai provider Riverpod.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pagedPostsProvider.overrideWith(_TestPagedPostsNotifier.new),
        ],
        child: const MyApp(),
      ),
    );

    // Memastikan halaman utama aplikasi berhasil dibuat.
    expect(find.text('Posts Paged'), findsOneWidget);
  });
}
