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

  group('ListViewResourceWidget', () {
    Widget buildTestWidget<T>({
      required Resource<List<T>> resource,
      Widget? loadingTile,
      required Widget Function(T data) tileMapper,
      Widget? emptyWidget,
      Future<void> Function()? refresh,
      Widget Function(NetworkException e)? errorWidget,
      List<Widget> topWidgets = const [],
      int loadingTileQuantity = 2,
      EdgeInsets? padding,
      bool shrinkWrap = true,
      String? textTryAgain,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ListViewResourceWidget<T>(
            resource: resource,
            loadingTile: loadingTile ?? const ListTile(title: Text('Loading')),
            tileMapper: tileMapper,
            emptyWidget: emptyWidget,
            refresh: refresh,
            errorWidget: errorWidget,
            topWidgets: topWidgets,
            loadingTileQuantity: loadingTileQuantity,
            padding: padding,
            shrinkWrap: shrinkWrap,
            textTryAgain: textTryAgain,
          ),
        ),
      );
    }

    group('loading state', () {
      testWidgets('should display loading tiles when resource is loading',
          (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.loading(),
          tileMapper: (data) => Text(data),
          loadingTileQuantity: 3,
        ));

        expect(find.text('Loading'), findsNWidgets(3));
      });

      testWidgets('should display default 2 loading tiles', (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.loading(),
          tileMapper: (data) => Text(data),
        ));

        expect(find.text('Loading'), findsNWidgets(2));
      });

      testWidgets('should display custom loading tile', (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.loading(),
          loadingTile: const Card(child: Text('Custom Skeleton')),
          tileMapper: (data) => Text(data),
        ));

        expect(find.text('Custom Skeleton'), findsNWidgets(2));
      });
    });

    group('success state', () {
      testWidgets('should display list items using tileMapper', (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.success(data: ['Item 1', 'Item 2', 'Item 3']),
          tileMapper: (data) => ListTile(
            key: ValueKey(data),
            title: Text(data),
          ),
        ));

        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 2'), findsOneWidget);
        expect(find.text('Item 3'), findsOneWidget);
      });

      testWidgets('should display emptyWidget when list is empty',
          (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.success(data: []),
          tileMapper: (data) => Text(data),
          emptyWidget: const Text('No items found'),
        ));

        expect(find.text('No items found'), findsOneWidget);
      });

      testWidgets('should display emptyWidget when data is null',
          (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.success(),
          tileMapper: (data) => Text(data),
          emptyWidget: const Text('Empty'),
        ));

        expect(find.text('Empty'), findsOneWidget);
      });

      testWidgets('should not show emptyWidget when emptyWidget is null',
          (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.success(data: []),
          tileMapper: (data) => Text(data),
          emptyWidget: null,
        ));

        // Should render an empty list
        expect(find.byType(ListView), findsOneWidget);
      });
    });

    group('failed state', () {
      testWidgets('should display default error widget', (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.failed(error: Exception('Load failed')),
          tileMapper: (data) => Text(data),
          refresh: () async {},
        ));

        expect(find.byIcon(Icons.close), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
      });

      testWidgets('should display custom error widget', (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.failed(error: Exception('Error')),
          tileMapper: (data) => Text(data),
          errorWidget: (e) => Text('Custom error: ${e.message}'),
        ));

        expect(find.textContaining('Custom error'), findsOneWidget);
      });

      testWidgets('should use custom textTryAgain', (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.failed(error: Exception('Error')),
          tileMapper: (data) => Text(data),
          refresh: () async {},
          textTryAgain: 'Retry',
        ));

        expect(find.text('Retry'), findsOneWidget);
      });
    });

    group('topWidgets', () {
      testWidgets('should display topWidgets before list items',
          (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.success(data: ['Item']),
          tileMapper: (data) => Text(data),
          topWidgets: [
            const Text('Header 1'),
            const Text('Header 2'),
          ],
        ));

        expect(find.text('Header 1'), findsOneWidget);
        expect(find.text('Header 2'), findsOneWidget);
        expect(find.text('Item'), findsOneWidget);
      });

      testWidgets('should display topWidgets during loading', (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.loading(),
          tileMapper: (data) => Text(data),
          topWidgets: [const Text('Header')],
        ));

        expect(find.text('Header'), findsOneWidget);
        expect(find.text('Loading'), findsNWidgets(2));
      });
    });

    group('refresh', () {
      testWidgets('should wrap with RefreshIndicator when refresh is provided',
          (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.success(data: ['Item']),
          tileMapper: (data) => Text(data),
          refresh: () async {},
        ));

        expect(find.byType(RefreshIndicator), findsOneWidget);
      });

      testWidgets('should not wrap when refresh is null', (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.success(data: ['Item']),
          tileMapper: (data) => Text(data),
        ));

        expect(find.byType(RefreshIndicator), findsNothing);
      });
    });

    group('sliver constructor', () {
      testWidgets('should work as a sliver', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                ListViewResourceWidget<String>.sliver(
                  resource: Resource.success(data: ['Sliver Item']),
                  loadingTile: const Text('Loading'),
                  tileMapper: (data) => Text(data),
                ),
              ],
            ),
          ),
        ));

        expect(find.text('Sliver Item'), findsOneWidget);
      });

      testWidgets('should display loading tiles in sliver mode', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                ListViewResourceWidget<String>.sliver(
                  resource: Resource.loading(),
                  loadingTile: const Text('Sliver Loading'),
                  tileMapper: (data) => Text(data),
                  loadingTileQuantity: 3,
                ),
              ],
            ),
          ),
        ));

        expect(find.text('Sliver Loading'), findsNWidgets(3));
      });
    });

    group('ListView properties', () {
      testWidgets('should apply padding', (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.success(data: ['Item']),
          tileMapper: (data) => Text(data),
          padding: const EdgeInsets.all(16),
        ));

        final listView = tester.widget<ListView>(find.byType(ListView));
        expect(listView.padding, const EdgeInsets.all(16));
      });

      testWidgets('should apply shrinkWrap', (tester) async {
        await tester.pumpWidget(buildTestWidget<String>(
          resource: Resource.success(data: ['Item']),
          tileMapper: (data) => Text(data),
          shrinkWrap: true,
        ));

        final listView = tester.widget<ListView>(find.byType(ListView));
        expect(listView.shrinkWrap, isTrue);
      });
    });

    group('complex types', () {
      testWidgets('should work with object types', (tester) async {
        final items = [
          _TestItem(id: 1, name: 'First'),
          _TestItem(id: 2, name: 'Second'),
        ];

        await tester.pumpWidget(buildTestWidget<_TestItem>(
          resource: Resource.success(data: items),
          tileMapper: (item) => ListTile(
            key: ValueKey(item.id),
            title: Text(item.name),
          ),
        ));

        expect(find.text('First'), findsOneWidget);
        expect(find.text('Second'), findsOneWidget);
      });
    });

    group('separatorBuilder', () {
      testWidgets('should use separatorBuilder when provided', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ListViewResourceWidget<String>(
              resource: Resource.success(data: ['A', 'B', 'C']),
              loadingTile: const SizedBox(),
              tileMapper: (data) => Text(data),
              separatorBuilder: (index, tile) => Column(
                children: [
                  tile,
                  const Divider(),
                ],
              ),
              shrinkWrap: true,
            ),
          ),
        ));

        expect(find.byType(Divider), findsNWidgets(3));
      });
    });
  });
}

class _TestItem {
  final int id;
  final String name;

  _TestItem({required this.id, required this.name});
}
