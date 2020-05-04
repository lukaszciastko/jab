import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jab/jab.dart';
import 'package:jab_example_app/jab_example_app.dart';

void main() {
  // ignore: close_sinks
  final logger = Logger();

  group('Counter', () {
    setUp(() {
      Jab.provideForRoot([(_) => logger]);
    });

    tearDown(() {
      Jab.clearRoot();
    });

    testWidgets('Default', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(CounterApp());

      // -------------------------
      // - Open Default Counter
      // -------------------------

      // Go to Default Counter
      await tester.tap(find.text('Default Counter'));
      await tester.pumpAndSettle(Duration(seconds: 1));

      expect(logger.logs[0], "CounterApp.Jab.canCreate: CounterStore");
      expect(logger.logs[1], "CounterApp.Jab.onCreate: Instance of 'CounterStore'");

      // Verify that our counter starts at 0.00.
      expect(find.text('0.00'), findsOneWidget);
      expect(find.text('1.00'), findsNothing);

      // -------------------------
      // - Increment
      // -------------------------

      // Tap the 'Increment' button and trigger a frame.
      await tester.tap(find.byTooltip('Increment'));
      await tester.pump();

      expect(logger.logs[2], "CounterBloc.add: CounterEvent.increment");
      expect(logger.logs[3], "CounterStore.add: 1.0");

      // Verify that our counter has incremented to 1.00.
      expect(find.text('0.00'), findsNothing);
      expect(find.text('1.00'), findsOneWidget);

      // -------------------------
      // - Decrement
      // -------------------------

      // Tap the 'Decrement' button and trigger a frame.
      await tester.tap(find.byTooltip('Decrement'));
      await tester.pump();

      expect(logger.logs[4], "CounterBloc.add: CounterEvent.decrement");
      expect(logger.logs[5], "CounterStore.add: 0.0");

      // Verify that our counter has decremented to 0.00.
      expect(find.text('0.00'), findsOneWidget);
      expect(find.text('1.00'), findsNothing);

      // -------------------------
      // - Increment
      // -------------------------

      // Tap the 'Increment' button twice and trigger a frame.
      await tester.tap(find.byTooltip('Increment'));
      await tester.tap(find.byTooltip('Increment'));
      await tester.pump();

      expect(logger.logs[6], "CounterBloc.add: CounterEvent.increment");
      expect(logger.logs[7], "CounterStore.add: 1.0");
      expect(logger.logs[8], "CounterBloc.add: CounterEvent.increment");
      expect(logger.logs[9], "CounterStore.add: 2.0");

      // Verify that our counter has incremented to 2.00.
      expect(find.text('2.00'), findsOneWidget);
      expect(find.text('0.00'), findsNothing);

      // -------------------------
      // - Clear
      // -------------------------

      // Tap the 'Clear' button and trigger a frame.
      await tester.tap(find.byTooltip('Clear'));
      await tester.pump();

      expect(logger.logs[10], "CounterStore.clear");

      // Verify that our counter has cleared to 0.00.
      expect(find.text('2.00'), findsNothing);
      expect(find.text('0.00'), findsOneWidget);

      // -------------------------
      // - Go back
      // -------------------------

      // Go back
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle(Duration(seconds: 1));

      expect(logger.logs[11], "CounterBloc.close");

      // Pump a dummy Container
      await tester.pumpWidget(Container());

      expect(logger.logs[12], "CounterApp.Jab.onDispose: Instance of 'CounterStore'");
      expect(logger.logs[13], "CounterStore.close");
    });

    testWidgets('Golden', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(CounterApp());

      // -------------------------
      // - Open Golden Counter
      // -------------------------

      // Go to Default Counter
      await tester.tap(find.text('Golden Counter'));
      await tester.pumpAndSettle(Duration(seconds: 1));

      expect(logger.logs[0], "CounterApp.Jab.canCreate: CounterStore");
      expect(logger.logs[1], "CounterApp.Jab.onCreate: Instance of 'CounterStore'");

      // Verify that our counter starts at 0.00.
      expect(find.text('0.00'), findsOneWidget);
      expect(find.text('1.61'), findsNothing);

      // -------------------------
      // - Increment
      // -------------------------

      // Tap the 'Increment' button and trigger a frame.
      await tester.tap(find.byTooltip('Increment'));
      await tester.pump();

      expect(logger.logs[2], "GoldenCounterBloc.add: CounterEvent.increment");
      expect(logger.logs[3], "CounterStore.add: 1.618");

      // Verify that our counter has incremented to 1.00.
      expect(find.text('0.00'), findsNothing);
      expect(find.text('1.62'), findsOneWidget);

      // -------------------------
      // - Decrement
      // -------------------------

      // Tap the 'Decrement' button and trigger a frame.
      await tester.tap(find.byTooltip('Decrement'));
      await tester.pump();

      expect(logger.logs[4], "GoldenCounterBloc.add: CounterEvent.decrement");
      expect(logger.logs[5], "CounterStore.add: 1.0");

      // Verify that our counter has decremented to 0.00.
      expect(find.text('1.00'), findsOneWidget);
      expect(find.text('1.62'), findsNothing);

      // -------------------------
      // - Increment
      // -------------------------

      // Tap the 'Increment' button twice and trigger a frame.
      await tester.tap(find.byTooltip('Increment'));
      await tester.tap(find.byTooltip('Increment'));
      await tester.pump();

      expect(logger.logs[6], "GoldenCounterBloc.add: CounterEvent.increment");
      expect(logger.logs[7], "CounterStore.add: 1.618");
      expect(logger.logs[8], "GoldenCounterBloc.add: CounterEvent.increment");
      expect(logger.logs[9], "CounterStore.add: 2.6179240000000004");

      // Verify that our counter has incremented to 2.00.
      expect(find.text('2.62'), findsOneWidget);
      expect(find.text('1.00'), findsNothing);

      // -------------------------
      // - Clear
      // -------------------------

      // Tap the 'Clear' button and trigger a frame.
      await tester.tap(find.byTooltip('Clear'));
      await tester.pump();

      expect(logger.logs[10], "CounterStore.clear");

      // Verify that our counter has cleared to 0.00.
      expect(find.text('2.62'), findsNothing);
      expect(find.text('0.00'), findsOneWidget);

      // -------------------------
      // - Go back
      // -------------------------

      // Go back
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle(Duration(seconds: 1));

      expect(logger.logs[11], "GoldenCounterBloc.close");

      // Pump a dummy Container
      await tester.pumpWidget(Container());

      expect(logger.logs[12], "CounterApp.Jab.onDispose: Instance of 'CounterStore'");
      expect(logger.logs[13], "CounterStore.close");
    });
  });
}
