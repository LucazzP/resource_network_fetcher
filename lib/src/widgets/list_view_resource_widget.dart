import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:resource_network_fetcher/src/widgets/default_error_widget.dart';

import '../app_exception.dart';
import '../resource.dart';
import '../status.dart';

class ListViewResourceWidget<T> extends StatelessWidget {
  final bool useSliver;
  final Resource<List<T>> resource;
  final Widget loadingTile;
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
        super(key: key);

  const ListViewResourceWidget.reorderable({
    Key? key,
    required this.resource,
    required this.loadingTile,
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
  })  : useSliver = false,
        itemExtent = null,
        semanticChildCount = null,
        addAutomaticKeepAlives = true,
        addRepaintBoundaries = true,
        addSemanticIndexes = true,
        reorderableList = onReorder != null,
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
        super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget child;
    final _topWidgets = topWidgets ?? <Widget>[];
    final list = _generateList(resource, _topWidgets);

    if (useSliver) {
      child = SliverList(
        delegate: SliverChildListDelegate.fixed(
          list,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
        ),
      );
    } else if (reorderableList) {
      child = ReorderableListView(
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
        children: list,
      );
    } else {
      child = ListView(
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
        children: list,
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

  List<Widget> _generateList(
    Resource<List<T>> resource,
    List<Widget> topWidgets,
  ) {
    var listWidgets = <Widget>[];
    if (resource.data != null) {
      listWidgets = (resource.data ?? []).map<Widget>(tileMapper).toList();
      if (separatorBuilder != null) {
        listWidgets = listWidgets
            .asMap()
            .map((index, child) {
              return MapEntry(index, separatorBuilder!(index, child));
            })
            .values
            .toList();
      }
    }
    switch (resource.status) {
      case Status.loading:
        for (var i = 0; i < loadingTileQuantity; i++) {
          listWidgets.add(loadingTile);
        }
        break;
      case Status.success:
        if (emptyWidget != null && (resource.data == null || (resource.data ?? []).isEmpty)) {
          listWidgets.add(emptyWidget ?? const SizedBox.shrink());
        }
        break;
      case Status.failed:
        listWidgets.add(
          errorWidget != null
              ? errorWidget!(resource.error ?? const AppException())
              : DefaultErrorWidget(
                  resource.message,
                  onTryAgain: refresh,
                  textTryAgain: textTryAgain,
                  key: UniqueKey(),
                ),
        );
        break;
      default:
        break;
    }
    if (!reorderableList) {
      listWidgets.insertAll(0, topWidgets);
    }
    return listWidgets;
  }
}
