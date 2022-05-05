import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:resource_network_fetcher/src/widgets/default_error_widget.dart';

import '../app_exception.dart';
import '../resource.dart';
import '../status.dart';

class ListViewResourceWidget<T> extends StatelessWidget {
  final bool useSliver;
  final Resource<List<T>> resource;
  final Widget? loadingTile;
  final Widget Function()? loadingTileBuilder;
  final Widget Function(T data) tileMapper;
  final Widget Function(int index, Widget tile)? separatorBuilder;
  final Widget? emptyWidget;
  final Future<void> Function()? refresh;
  final EdgeInsets? padding;
  final List<Widget>? topWidgets;
  final Widget Function(AppException e)? errorWidget;
  final Axis scrollDirection;
  final bool reverse;
  final ScrollController? controller;
  final bool? primary;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final double? cacheExtent;
  final int? semanticChildCount;
  final DragStartBehavior dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final String? restorationId;
  final Clip clipBehavior;
  final double? itemExtent;
  final bool reorderableList;
  final ReorderCallback? onReorder;
  final int loadingTileQuantity;
  final String? textTryAgain;

  const ListViewResourceWidget({
    Key? key,
    this.useSliver = false,
    required this.resource,
    required this.loadingTile,
    required this.tileMapper,
    this.refresh,
    this.emptyWidget,
    this.padding,
    this.topWidgets,
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
        loadingTileBuilder = null,
        super(key: key);

  const ListViewResourceWidget.reorderable({
    Key? key,
    required this.resource,
    required this.loadingTileBuilder,
    required this.tileMapper,
    required this.onReorder,
    this.refresh,
    this.emptyWidget,
    this.topWidgets,
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
        loadingTile = null,
        super(key: key);

  const ListViewResourceWidget.sliver({
    Key? key,
    this.useSliver = true,
    required this.resource,
    required this.loadingTile,
    required this.tileMapper,
    this.refresh,
    this.separatorBuilder,
    this.emptyWidget,
    this.topWidgets,
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
        loadingTileBuilder = null,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget child;
    final _topWidgets = topWidgets ?? <Widget>[];

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
              return _generateListBuilder(resource, _topWidgets, index);
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
          return _generateListBuilder(resource, _topWidgets, index);
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
        header: _topWidgets.length == 1
            ? _topWidgets.first
            : scrollDirection == Axis.vertical
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _topWidgets,
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _topWidgets,
                  ),
      );
    } else {
      child = ListView.builder(
        itemBuilder: (context, index) {
          return _generateListBuilder(resource, _topWidgets, index);
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

  int get _listLenght {
    var lenght = 0;

    if (!reorderableList) {
      lenght += topWidgets?.length ?? 0;
    }

    switch (resource.status) {
      case Status.loading:
        lenght += (resource.data ?? []).length + loadingTileQuantity;
        break;
      case Status.success:
        if (emptyWidget != null &&
            (resource.data == null || (resource.data ?? []).isEmpty)) {
          lenght++;
        } else {
          lenght += resource.data?.length ?? 0;
        }
        break;
      case Status.failed:
        lenght++;
        break;
      default:
        break;
    }

    return lenght;
  }

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
        if (emptyWidget != null &&
            (resource.data == null || (resource.data ?? []).isEmpty)) {
          return emptyWidget ?? const SizedBox.shrink();
        }
        final widget = tileMapper(data[index]);
        if (separatorBuilder != null) {
          return separatorBuilder!(index, widget);
        }
        return widget;
      case Status.failed:
        return errorWidget != null
            ? errorWidget!(resource.error ?? const AppException())
            : DefaultErrorWidget(
                resource.message,
                onTryAgain: refresh,
                textTryAgain: textTryAgain,
                key: UniqueKey(),
              );
      default:
        break;
    }
    return const SizedBox.shrink();
  }

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

  Widget _itemBuilder(BuildContext context, int index) {
    final item = _generateListBuilder(resource, topWidgets ?? [], index);
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

// A global key that takes its identity from the object and uses a value of a
// particular type to identify itself.
//
// The difference with GlobalObjectKey is that it uses [==] instead of [identical]
// of the objects used to generate widgets.
@optionalTypeArgs
class _ReorderableListViewChildGlobalKey extends GlobalObjectKey {
  const _ReorderableListViewChildGlobalKey(this.subKey, this.state)
      : super(subKey);

  final Key subKey;
  final StatelessWidget state;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is _ReorderableListViewChildGlobalKey &&
        other.subKey == subKey &&
        other.state == state;
  }

  @override
  int get hashCode => hashValues(subKey, state);
}
