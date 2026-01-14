import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resource_network_fetcher/resource_network_fetcher.dart';

void main() {
  setUp(() {
    Resource.setErrorMapper(
      (e, stackTrace) => NetworkException(
        exception: e,
        message: e.toString(),
        stackTrace: stackTrace,
      ),
    );
  });

  group('ResourceWidget', () {
    Widget buildTestWidget<T>({
      required Resource<T> resource,
      Widget loadingWidget = const CircularProgressIndicator(),
      required Widget Function(T? data) doneWidget,
      Widget Function(NetworkException e)? errorWidget,
      Widget Function(NetworkException e, T? data)? errorWithDataWidget,
      Widget Function(T? data)? loadingWithDataWidget,
      bool showErrorWidget = false,
      Future<void> Function()? refresh,
      String? textTryAgain,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ResourceWidget<T>(
            resource: resource,
            loadingWidget: loadingWidget,
            doneWidget: doneWidget,
            errorWidget: errorWidget,
            errorWithDataWidget: errorWithDataWidget,
            loadingWithDataWidget: loadingWithDataWidget,
            showErrorWidget: showErrorWidget,
            refresh: refresh,
            textTryAgain: textTryAgain,
          ),
        ),
      );
    }

    group('loading state', () {
      testWidgets('should display loading widget when resource is loading', (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.loading(),
          doneWidget: (data) => Text('Done: $data'),
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.textContaining('Done'), findsNothing);
      });

      testWidgets('should display custom loading widget', (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.loading(),
          loadingWidget: const Text('Custom Loading'),
          doneWidget: (data) => const SizedBox(),
        ));

        expect(find.text('Custom Loading'), findsOneWidget);
      });

      testWidgets('should display loadingWithDataWidget when loading with data', (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.loading(data: 'cached'),
          doneWidget: (data) => Text('Done: $data'),
          loadingWithDataWidget: (data) => Text('Loading with: $data'),
        ));

        expect(find.text('Loading with: cached'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('should display regular loading when loadingWithDataWidget is null', (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.loading(data: 'cached'),
          doneWidget: (data) => Text('Done: $data'),
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('success state', () {
      testWidgets('should display doneWidget when resource is success', (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.success(data: 'Result'),
          doneWidget: (data) => Text('Success: $data'),
        ));

        expect(find.text('Success: Result'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('should handle null data in success state', (tester) async {
        await tester.pumpWidget(buildTestWidget<String?>(
          resource: Resource.success(),
          doneWidget: (data) => Text('Data is: ${data ?? 'null'}'),
        ));

        expect(find.text('Data is: null'), findsOneWidget);
      });
    });

    group('failed state', () {
      testWidgets('should display doneWidget when showErrorWidget is false (default)', (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.failed(error: Exception('Error')),
          doneWidget: (data) => Text('Done: ${data ?? 'no data'}'),
        ));

        expect(find.text('Done: no data'), findsOneWidget);
      });

      testWidgets('should display default error widget when showErrorWidget is true', (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.failed(error: Exception('Test error')),
          doneWidget: (data) => const Text('Done'),
          showErrorWidget: true,
          refresh: () async {},
        ));

        expect(find.byIcon(Icons.close), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
      });

      testWidgets('should display custom error widget', (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.failed(error: Exception('Custom error')),
          doneWidget: (data) => const Text('Done'),
          showErrorWidget: true,
          errorWidget: (e) => Text('Custom: ${e.message}'),
        ));

        expect(find.textContaining('Custom:'), findsOneWidget);
      });

      testWidgets('should display errorWithDataWidget when data is available', (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.failed(
            error: Exception('Error'),
            data: 'cached',
          ),
          doneWidget: (data) => Text('Done: $data'),
          errorWithDataWidget: (e, data) => Text('Error with data: $data'),
        ));

        expect(find.text('Error with data: cached'), findsOneWidget);
      });

      testWidgets('should use custom textTryAgain in default error widget', (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.failed(error: Exception('Error')),
          doneWidget: (data) => const Text('Done'),
          showErrorWidget: true,
          refresh: () async {},
          textTryAgain: 'Retry Now',
        ));

        expect(find.text('Retry Now'), findsOneWidget);
        expect(find.text('Try again'), findsNothing);
      });

      testWidgets('should call refresh when try again is pressed', (tester) async {
        var refreshCalled = false;

        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.failed(error: Exception('Error')),
          doneWidget: (data) => const Text('Done'),
          showErrorWidget: true,
          refresh: () async {
            refreshCalled = true;
          },
        ));

        await tester.tap(find.text('Try again'));
        await tester.pump();

        expect(refreshCalled, isTrue);
      });
    });

    group('type handling', () {
      testWidgets('should work with complex types', (tester) async {
        await tester.pumpWidget(buildTestWidget<List<int>>(
          resource: Resource.success(data: [1, 2, 3]),
          doneWidget: (data) => Text('Items: ${data?.length ?? 0}'),
        ));

        expect(find.text('Items: 3'), findsOneWidget);
      });

      testWidgets('should work with nullable types', (tester) async {
        await tester.pumpWidget(buildTestWidget<String?>(
          resource: Resource.success(data: null),
          doneWidget: (data) => Text('Value: ${data ?? 'empty'}'),
        ));

        expect(find.text('Value: empty'), findsOneWidget);
      });
    });
  });
}
