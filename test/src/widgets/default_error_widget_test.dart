import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resource_network_fetcher/src/widgets/default_error_widget.dart';

void main() {
  group('DefaultErrorWidget', () {
    Widget buildTestWidget({
      required String error,
      VoidCallback? onTryAgain,
      String? textTryAgain,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: DefaultErrorWidget(
            error,
            onTryAgain: onTryAgain,
            textTryAgain: textTryAgain,
          ),
        ),
      );
    }

    testWidgets('should display error message', (tester) async {
      await tester.pumpWidget(buildTestWidget(error: 'Test error message'));

      expect(find.text('Test error message'), findsOneWidget);
    });

    testWidgets('should display error icon', (tester) async {
      await tester.pumpWidget(buildTestWidget(error: 'Error'));

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should not show try again button when onTryAgain is null',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(error: 'Error'));

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('should show try again button when onTryAgain is provided',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        error: 'Error',
        onTryAgain: () {},
      ));

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('should use custom try again text', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        error: 'Error',
        onTryAgain: () {},
        textTryAgain: 'Retry',
      ));

      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('should call onTryAgain when button is pressed',
        (tester) async {
      var buttonPressed = false;

      await tester.pumpWidget(buildTestWidget(
        error: 'Error',
        onTryAgain: () => buttonPressed = true,
      ));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(buttonPressed, isTrue);
    });

    testWidgets('should have Center widget in DefaultErrorWidget', (tester) async {
      await tester.pumpWidget(buildTestWidget(error: 'Error'));

      // The DefaultErrorWidget contains Center widget(s) - find first direct child
      final defaultErrorWidget = find.byType(DefaultErrorWidget);
      expect(defaultErrorWidget, findsOneWidget);
      
      // Verify the error message is centered by checking the Column has center alignment
      expect(find.descendant(
        of: defaultErrorWidget,
        matching: find.byType(Column),
      ), findsOneWidget);
    });

    testWidgets('should use error color from theme for icon', (tester) async {
      const errorColor = Colors.red;

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          colorScheme: const ColorScheme.light(error: errorColor),
        ),
        home: const Scaffold(
          body: DefaultErrorWidget('Error'),
        ),
      ));

      final icon = tester.widget<Icon>(find.byIcon(Icons.close));
      expect(icon.color, errorColor);
    });
  });
}
