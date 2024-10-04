// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:native_logger_example/main.dart';

void main() {
  testWidgets('Verify MyApp screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    expect(find.text('verbose log'), findsOneWidget);
    expect(find.text('debug log'), findsOneWidget);
    expect(find.text('info log'), findsOneWidget);
    expect(find.text('warning log'), findsOneWidget);
    expect(find.text('error log'), findsOneWidget);
    expect(find.text('fatal log'), findsOneWidget);
    expect(find.text('silent'), findsOneWidget);
    expect(find.text('exception'), findsOneWidget);
    /*
    // Verify that platform version is retrieved.
    expect(
      find.byWidgetPredicate(
        (Widget widget) => widget is Text &&
                           widget.data!.startsWith('Running on: '),
      ),
      findsOneWidget,
    );
    */
  });
}
