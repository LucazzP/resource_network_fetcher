import 'package:flutter/material.dart';
import 'package:resource_network_fetcher/src/widgets/default_error_widget.dart';

import '../app_exception.dart';
import '../status.dart';
import '../resource.dart';

class ResourceWidget<T> extends StatelessWidget {
  final Resource<T> resource;
  final Widget loadingWidget;
  final Widget Function(AppException e)? errorWidget;
  final Widget Function(AppException e, T? data)? errorWithDataWidget;
  final bool showErrorWidget;
  final Widget Function(T? data) doneWidget;
  final Widget Function(T? data)? loadingWithDataWidget;
  final Future<void> Function()? refresh;
  final String? textTryAgain;

  const ResourceWidget({
    Key? key,
    required this.resource,
    required this.loadingWidget,
    this.errorWidget,
    required this.doneWidget,
    this.refresh,
    this.showErrorWidget = false,
    this.errorWithDataWidget,
    this.loadingWithDataWidget,
    this.textTryAgain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (resource.status) {
      case Status.loading:
        if (loadingWithDataWidget != null && resource.data != null) {
          return loadingWithDataWidget!(resource.data!);
        }
        return loadingWidget;
      case Status.success:
        return doneWidget(resource.data);
      case Status.failed:
        if (errorWithDataWidget != null && resource.data != null) {
          return errorWithDataWidget!(resource.error ?? const AppException(), resource.data);
        }
        return showErrorWidget
            ? errorWidget == null
                ? DefaultErrorWidget(
                    resource.message,
                    onTryAgain: refresh!,
                    textTryAgain: textTryAgain,
                  )
                : errorWidget!(resource.error ?? const AppException())
            : doneWidget(resource.data);
      default:
        return const SizedBox.shrink();
    }
  }
}
