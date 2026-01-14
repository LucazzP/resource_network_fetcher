import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:resource_network_fetcher/src/widgets/default_error_widget.dart';

import '../app_exception.dart';
import '../resource.dart';
import '../status.dart';

/// A widget that displays a list based on a [Resource<List<T>>]'s state.
///
/// [ListViewResourceWidget] automatically handles the three states of a [Resource]:
/// - Loading: Shows [loadingTile] repeated [loadingTileQuantity] times
/// - Success: Shows list items using [tileMapper]
/// - Failed: Shows an error widget
///
/// This widget simplifies displaying lists that are loaded asynchronously,
/// handling loading skeletons, empty states, and errors automatically.
///
/// ## Basic Usage
///
/// ```dart
/// ListViewResourceWidget<Todo>(
///   resource: todosResource,
///   loadingTile: TodoSkeleton(),
///   tileMapper: (todo) => TodoTile(todo: todo),
///   emptyWidget: Text('No todos yet'),
/// )
/// ```
///
/// ## With Pull-to-Refresh
///
/// ```dart
/// ListViewResourceWidget<Todo>(
///   resource: todosResource,
///   loadingTile: TodoSkeleton(),
///   tileMapper: (todo) => TodoTile(todo: todo),
///   refresh: () => controller.loadTodos(),
/// )
/// ```
///
/// ## Variants
///
/// - Default constructor: Standard [ListView]
/// - [ListViewResourceWidget.sliver]: For use inside [CustomScrollView]
/// - [ListViewResourceWidget.reorderable]: For drag-and-drop reordering
///
/// See also:
/// - [ResourceWidget] for displaying single resources
/// - [Resource] for the state wrapper class
class ListViewResourceWidget<T> extends StatelessWidget {
  /// Whether to render as a sliver instead of a regular widget.
  ///
  /// When true, the widget can be used inside a [CustomScrollView].
  final bool useSliver;

  /// The resource containing the list data and its current state.
  final Resource<List<T>> resource;

  /// A widget to display for each item during loading state.
  ///
  /// This widget is displayed [loadingTileQuantity] times as skeleton/placeholder
  /// content while the actual data is being loaded.
  final Widget? loadingTile;

  /// A builder function to create loading tiles dynamically.
  ///
  /// Used in reorderable lists where each tile needs a unique key.
  final Widget Function()? loadingTileBuilder;

  /// Maps each data item to its corresponding list tile widget.
  ///
  /// This function is called for each item in the list when the resource
  /// is in success state.
  final Widget Function(T data) tileMapper;

  /// Optional builder for adding separators between list items.
  ///
  /// Receives the item index and the widget created by [tileMapper],
  /// allowing you to wrap or modify the tile.
  final Widget Function(int index, Widget tile)? separatorBuilder;

  /// Widget shown when the list is empty (success state with no items).
  ///
  /// If null, an empty list is rendered with no special indication.
  final Widget? emptyWidget;

  /// Callback for pull-to-refresh functionality.
  ///
  /// When provided for non-sliver widgets, wraps the list in a
  /// [RefreshIndicator].
  final Future<void> Function()? refresh;

  /// Padding around the list content.
  final EdgeInsets? padding;

  /// Widgets to display at the top of the list before the data items.
  ///
  /// These widgets are always shown regardless of the resource state.
  final List<Widget> topWidgets;

  /// Custom error widget builder for failed states.
  ///
  /// If not provided, [DefaultErrorWidget] is used.
  final Widget Function(NetworkException e)? errorWidget;

  /// The axis along which the list scrolls.
  ///
  /// Defaults to [Axis.vertical].
  final Axis scrollDirection;

  /// Whether the list scrolls in reverse direction.
  final bool reverse;

  /// Controller for the scrollable widget.
  final ScrollController? controller;

  /// Whether this is the primary scroll view in the widget tree.
  final bool? primary;

  /// Physics for the scrollable widget.
  final ScrollPhysics? physics;

  /// Whether the list should shrink-wrap its content.
  final bool shrinkWrap;

  /// Whether to wrap each child in an [AutomaticKeepAlive].
  final bool addAutomaticKeepAlives;

  /// Whether to wrap each child in a [RepaintBoundary].
  final bool addRepaintBoundaries;

  /// Whether to wrap each child with an [IndexedSemantics].
  final bool addSemanticIndexes;

  /// The cache extent for the scrollable widget.
  final double? cacheExtent;

  /// The number of children that contribute to the semantics.
  final int? semanticChildCount;

  /// Configuration for drag start behavior.
  final DragStartBehavior dragStartBehavior;

  /// Keyboard dismiss behavior for the scrollable.
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// Restoration ID for state restoration.
  final String? restorationId;

  /// Clip behavior for the list.
  final Clip clipBehavior;

  /// Fixed extent for each item (for performance optimization).
  final double? itemExtent;

  /// Whether this list supports drag-and-drop reordering.
  final bool reorderableList;

  /// Callback when items are reordered via drag-and-drop.
  final ReorderCallback? onReorder;

  /// Number of loading tiles to show during loading state.
  ///
  /// Defaults to 2.
  final int loadingTileQuantity;

  /// Custom text for the "Try Again" button in error state.
  final String? textTryAgain;

  /// Creates a standard [ListViewResourceWidget].
  ///
  /// Example:
  /// ```dart
  /// ListViewResourceWidget<Todo>(
  ///   resource: todosResource,
  ///   loadingTile: TodoSkeleton(),
  ///   tileMapper: (todo) => TodoTile(todo: todo),
  ///   loadingTileQuantity: 5,
  ///   emptyWidget: Text('No todos'),
  ///   refresh: () => controller.refresh(),
  /// )
  /// ```
  const ListViewResourceWidget({
    super.key,
    this.useSliver = false,
    required this.resource,
    required this.loadingTile,
    required this.tileMapper,
    this.refresh,
    this.emptyWidget,
    this.padding,
    this.topWidgets = const [],
    this.errorWidget,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.itemExtent,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.cacheExtent,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.loadingTileQuantity = 2,
    this.separatorBuilder,
    this.textTryAgain,
  })  : reorderableList = false,
        onReorder = null,
        loadingTileBuilder = null;

  /// Creates a reorderable [ListViewResourceWidget] with drag-and-drop support.
  ///
  /// Items can be reordered by long-pressing and dragging. The [onReorder]
  /// callback is required and called when an item is dropped in a new position.
  ///
  /// Example:
  /// ```dart
  /// ListViewResourceWidget<Todo>.reorderable(
  ///   resource: todosResource,
  ///   loadingTileBuilder: () => TodoSkeleton(key: UniqueKey()),
  ///   tileMapper: (todo) => TodoTile(key: ValueKey(todo.id), todo: todo),
  ///   onReorder: (oldIndex, newIndex) => controller.reorder(oldIndex, newIndex),
  /// )
  /// ```
  const ListViewResourceWidget.reorderable({
    super.key,
    required this.resource,
    required this.loadingTileBuilder,
    required this.tileMapper,
    required this.onReorder,
    this.refresh,
    this.emptyWidget,
    this.topWidgets = const [],
    this.errorWidget,
    this.padding,
    this.controller,
    this.scrollDirection = Axis.vertical,
    this.shrinkWrap = false,
    this.loadingTileQuantity = 2,
    this.separatorBuilder,
    this.physics,
    this.reverse = false,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.dragStartBehavior = DragStartBehavior.start,
    this.restorationId,
    this.cacheExtent,
    this.clipBehavior = Clip.hardEdge,
    this.primary,
    this.textTryAgain,
    this.useSliver = false,
  })  : itemExtent = null,
        semanticChildCount = null,
        addAutomaticKeepAlives = true,
        addRepaintBoundaries = true,
        addSemanticIndexes = true,
        reorderableList = onReorder != null,
        loadingTile = null;

  /// Creates a sliver version of [ListViewResourceWidget].
  ///
  /// Use this constructor when you need to include the list inside a
  /// [CustomScrollView] with other slivers.
  ///
  /// Example:
  /// ```dart
  /// CustomScrollView(
  ///   slivers: [
  ///     SliverAppBar(title: Text('Todos')),
  ///     ListViewResourceWidget<Todo>.sliver(
  ///       resource: todosResource,
  ///       loadingTile: TodoSkeleton(),
  ///       tileMapper: (todo) => TodoTile(todo: todo),
  ///     ),
  ///   ],
  /// )
  /// ```
  const ListViewResourceWidget.sliver({
    super.key,
    this.useSliver = true,
    required this.resource,
    required this.loadingTile,
    required this.tileMapper,
    this.refresh,
    this.separatorBuilder,
    this.emptyWidget,
    this.topWidgets = const [],
    this.errorWidget,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.loadingTileQuantity = 2,
    this.textTryAgain,
  })  : padding = null,
        scrollDirection = Axis.vertical,
        reverse = false,
        controller = null,
        primary = null,
        physics = null,
        shrinkWrap = false,
        itemExtent = null,
        cacheExtent = null,
        semanticChildCount = null,
        dragStartBehavior = DragStartBehavior.start,
        keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
        restorationId = null,
        clipBehavior = Clip.hardEdge,
        reorderableList = false,
        onReorder = null,
        loadingTileBuilder = null;

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (useSliver) {
      if (reorderableList) {
        child = SliverReorderableList(
          onReorder: onReorder ?? (a, b) {},
          itemBuilder: _itemBuilder,
          itemCount: _listLenght,
          proxyDecorator: _proxyDecorator,
        );
      } else {
        child = SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return _generateListBuilder(resource, topWidgets, index);
            },
            childCount: _listLenght,
            addAutomaticKeepAlives: addAutomaticKeepAlives,
            addRepaintBoundaries: addRepaintBoundaries,
            addSemanticIndexes: addSemanticIndexes,
          ),
        );
      }
    } else if (reorderableList) {
      child = ReorderableListView.builder(
        itemBuilder: (context, index) {
          return _generateListBuilder(resource, topWidgets, index);
        },
        itemCount: _listLenght,
        onReorder: onReorder ?? (a, b) {},
        shrinkWrap: shrinkWrap,
        padding: padding,
        scrollDirection: scrollDirection,
        physics: physics,
        scrollController: controller,
        cacheExtent: cacheExtent,
        reverse: reverse,
        keyboardDismissBehavior: keyboardDismissBehavior,
        dragStartBehavior: dragStartBehavior,
        restorationId: restorationId,
        clipBehavior: clipBehavior,
        primary: primary,
        proxyDecorator: _proxyDecorator,
        header: topWidgets.length == 1
            ? topWidgets.first
            : scrollDirection == Axis.vertical
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: topWidgets,
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: topWidgets,
                  ),
      );
    } else {
      child = ListView.builder(
        itemBuilder: (context, index) {
          return _generateListBuilder(resource, topWidgets, index);
        },
        itemCount: _listLenght,
        padding: padding,
        scrollDirection: scrollDirection,
        reverse: reverse,
        controller: controller,
        primary: primary,
        physics: physics,
        shrinkWrap: shrinkWrap,
        itemExtent: itemExtent,
        addAutomaticKeepAlives: addAutomaticKeepAlives,
        addRepaintBoundaries: addRepaintBoundaries,
        addSemanticIndexes: addSemanticIndexes,
        cacheExtent: cacheExtent,
        semanticChildCount: semanticChildCount,
        dragStartBehavior: dragStartBehavior,
        keyboardDismissBehavior: keyboardDismissBehavior,
        restorationId: restorationId,
        clipBehavior: clipBehavior,
      );
    }
    if (refresh != null && !useSliver) {
      return RefreshIndicator(
        onRefresh: refresh!,
        child: child,
      );
    }
    return child;
  }

  /// Calculates the total number of items to display in the list.
  int get _listLenght {
    var lenght = 0;

    if (!reorderableList) {
      lenght += topWidgets.length;
    }

    switch (resource.status) {
      case Status.loading:
        lenght += loadingTileQuantity;
        break;
      case Status.success:
        if (emptyWidget != null && (resource.data == null || (resource.data ?? []).isEmpty)) {
          lenght++;
        } else {
          lenght += resource.data?.length ?? 0;
        }
        break;
      case Status.failed:
        lenght++;
        break;
    }

    return lenght;
  }

  /// Builds the widget for a given index based on the resource state.
  Widget _generateListBuilder(
    Resource<List<T>> resource,
    List<Widget> topWidgets,
    int index,
  ) {
    final data = resource.data ?? [];

    if (!reorderableList) {
      if (index < topWidgets.length) {
        return topWidgets[index];
      }

      index = index - topWidgets.length;
    }

    switch (resource.status) {
      case Status.loading:
        if (loadingTile != null) {
          return loadingTile!;
        }
        if (loadingTileBuilder != null) {
          return loadingTileBuilder!();
        }
        break;
      case Status.success:
        if (emptyWidget != null && (resource.data == null || (resource.data ?? []).isEmpty)) {
          return emptyWidget ?? const SizedBox.shrink();
        }
        final widget = tileMapper(data[index]);
        if (separatorBuilder != null) {
          return separatorBuilder!(index, widget);
        }
        return widget;
      case Status.failed:
        return errorWidget != null
            ? errorWidget!(resource.error ?? const NetworkException())
            : DefaultErrorWidget(
                resource.message,
                onTryAgain: refresh,
                textTryAgain: textTryAgain,
                key: UniqueKey(),
              );
    }
    return const SizedBox.shrink();
  }

  /// Decorator for the dragged item during reordering.
  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final animValue = Curves.easeInOut.transform(animation.value);
        final elevation = lerpDouble(0, 6, animValue)!;
        return Material(
          elevation: elevation,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Builds items for reorderable lists with platform-specific drag handles.
  Widget _itemBuilder(BuildContext context, int index) {
    final item = _generateListBuilder(resource, topWidgets, index);
    assert(() {
      if (item.key == null) {
        throw FlutterError(
          'Every item of ReorderableListView must have a key.',
        );
      }
      return true;
    }());

    // TODO(goderbauer): The semantics stuff should probably happen inside
    //   _ReorderableItem so the widget versions can have them as well.
    final itemGlobalKey = _ReorderableListViewChildGlobalKey(item.key!, this);

    switch (Theme.of(context).platform) {
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
        switch (scrollDirection) {
          case Axis.horizontal:
            return Stack(
              key: itemGlobalKey,
              children: <Widget>[
                item,
                Positioned.directional(
                  textDirection: Directionality.of(context),
                  start: 0,
                  end: 0,
                  bottom: 8,
                  child: Align(
                    alignment: AlignmentDirectional.bottomCenter,
                    child: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
                  ),
                ),
              ],
            );
          case Axis.vertical:
            return Stack(
              key: itemGlobalKey,
              children: <Widget>[
                item,
                Positioned.directional(
                  textDirection: Directionality.of(context),
                  top: 0,
                  bottom: 0,
                  end: 8,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
                  ),
                ),
              ],
            );
        }

      case TargetPlatform.iOS:
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return ReorderableDelayedDragStartListener(
          key: itemGlobalKey,
          index: index,
          child: item,
        );
    }
  }
}

/// A global key for reorderable list view children.
///
/// Uses [==] instead of [identical] for comparing objects used to generate widgets.
@optionalTypeArgs
class _ReorderableListViewChildGlobalKey extends GlobalObjectKey {
  /// Creates a global key for a reorderable list view child.
  const _ReorderableListViewChildGlobalKey(this.subKey, this.state) : super(subKey);

  /// The key of the child widget.
  final Key subKey;

  /// Reference to the parent list widget.
  final StatelessWidget state;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is _ReorderableListViewChildGlobalKey && other.subKey == subKey && other.state == state;
  }

  @override
  int get hashCode => Object.hash(subKey, state);
}
