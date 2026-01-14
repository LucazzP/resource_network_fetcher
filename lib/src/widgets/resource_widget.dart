import 'package:flutter/material.dart';
import 'package:resource_network_fetcher/src/widgets/default_error_widget.dart';

import '../app_exception.dart';
import '../status.dart';
import '../resource.dart';

/// A widget that displays different UI based on a [Resource]'s state.
///
/// [ResourceWidget] automatically handles the three states of a [Resource]:
/// - Loading: Shows [loadingWidget]
/// - Success: Shows [doneWidget] with the data
/// - Failed: Shows either a custom error widget or [doneWidget] with null data
///
/// This widget simplifies the common pattern of switching UI based on
/// async operation state.
///
/// ## Basic Usage
///
/// ```dart
/// ResourceWidget<User>(
///   resource: userResource,
///   loadingWidget: CircularProgressIndicator(),
///   doneWidget: (user) => UserProfile(user: user),
/// )
/// ```
///
/// ## With Error Handling
///
/// ```dart
/// ResourceWidget<User>(
///   resource: userResource,
///   loadingWidget: CircularProgressIndicator(),
///   doneWidget: (user) => UserProfile(user: user),
///   showErrorWidget: true,
///   errorWidget: (error) => ErrorDisplay(message: error.message),
///   refresh: () => controller.loadUser(),
/// )
/// ```
///
/// ## With Loading and Error Data States
///
/// ```dart
/// ResourceWidget<User>(
///   resource: userResource,
///   loadingWidget: CircularProgressIndicator(),
///   doneWidget: (user) => UserProfile(user: user),
///   loadingWithDataWidget: (user) => Stack(
///     children: [
///       UserProfile(user: user),
///       LoadingOverlay(),
///     ],
///   ),
///   errorWithDataWidget: (error, user) => Stack(
///     children: [
///       UserProfile(user: user),
///       ErrorBanner(message: error.message),
///     ],
///   ),
/// )
/// ```
///
/// See also:
/// - [ListViewResourceWidget] for displaying lists with resource state handling
/// - [Resource] for the state wrapper class
class ResourceWidget<T> extends StatelessWidget {
  /// The resource whose state determines what widget to display.
  final Resource<T> resource;

  /// Widget shown when the resource is in loading state without data.
  ///
  /// This is typically a loading indicator like [CircularProgressIndicator].
  final Widget loadingWidget;

  /// Custom widget builder for error states without data.
  ///
  /// If not provided and [showErrorWidget] is true, a [DefaultErrorWidget]
  /// is shown. If [showErrorWidget] is false, [doneWidget] is called with
  /// null data.
  final Widget Function(NetworkException e)? errorWidget;

  /// Custom widget builder for error states when data is available.
  ///
  /// Useful for showing an error message while still displaying
  /// previously loaded data.
  final Widget Function(NetworkException e, T? data)? errorWithDataWidget;

  /// Whether to show an error widget when the resource fails.
  ///
  /// If false, [doneWidget] is called with null data on failure.
  /// Defaults to false.
  final bool showErrorWidget;

  /// Widget builder called when the resource is successful.
  ///
  /// The [data] parameter may be null if the successful operation
  /// returned no data.
  final Widget Function(T? data) doneWidget;

  /// Custom widget builder for loading states when data is available.
  ///
  /// Useful for showing a loading indicator while still displaying
  /// previously loaded data (e.g., during a refresh).
  final Widget Function(T? data)? loadingWithDataWidget;

  /// Callback for retry/refresh functionality.
  ///
  /// When provided with [showErrorWidget] true and no custom [errorWidget],
  /// the default error widget will show a "Try Again" button that calls
  /// this function.
  final Future<void> Function()? refresh;

  /// Custom text for the "Try Again" button in the default error widget.
  final String? textTryAgain;

  /// Creates a [ResourceWidget].
  ///
  /// The [resource], [loadingWidget], and [doneWidget] parameters are required.
  ///
  /// Example:
  /// ```dart
  /// ResourceWidget<User>(
  ///   resource: userResource,
  ///   loadingWidget: CircularProgressIndicator(),
  ///   doneWidget: (user) => Text(user?.name ?? 'No user'),
  /// )
  /// ```
  const ResourceWidget({
    super.key,
    required this.resource,
    required this.loadingWidget,
    this.errorWidget,
    required this.doneWidget,
    this.refresh,
    this.showErrorWidget = false,
    this.errorWithDataWidget,
    this.loadingWithDataWidget,
    this.textTryAgain,
  });

  @override
  Widget build(BuildContext context) {
    switch (resource.status) {
      case Status.loading:
        if (loadingWithDataWidget != null && resource.data != null) {
          return loadingWithDataWidget!(resource.data as T);
        }
        return loadingWidget;
      case Status.success:
        return doneWidget(resource.data);
      case Status.failed:
        if (errorWithDataWidget != null && resource.data != null) {
          return errorWithDataWidget!(resource.error ?? const NetworkException(), resource.data);
        }
        return showErrorWidget
            ? errorWidget == null
                ? DefaultErrorWidget(
                    resource.message,
                    onTryAgain: refresh,
                    textTryAgain: textTryAgain,
                  )
                : errorWidget!(resource.error ?? const NetworkException())
            : doneWidget(resource.data);
    }
  }
}
