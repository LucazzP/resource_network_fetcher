/// A package that provides a standardized way to track network requests,
/// handle errors, and manage resource states in Flutter applications.
///
/// This library exports all the core components needed to work with network
/// resources in a type-safe and error-resilient manner.
///
/// ## Main Components
///
/// - [NetworkBoundResources] - Utility class for making network requests with
///   optional caching and offline-first support.
/// - [Resource] - A wrapper class that represents the state of a network
///   operation (loading, success, or failed).
/// - [NetworkException] - A standardized exception class for network errors.
/// - [Status] - An enum representing the possible states of a resource.
///
/// ## Widgets
///
/// - [ListViewResourceWidget] - A widget for displaying lists backed by
///   [Resource] objects.
/// - [ResourceWidget] - A widget for displaying single resources with
///   automatic state handling.
///
/// ## Getting Started
///
/// ```dart
/// import 'package:resource_network_fetcher/resource_network_fetcher.dart';
///
/// void main() {
///   // Set up the error mapper to transform exceptions into user-friendly messages
///   Resource.setErrorMapper((e, stackTrace) => NetworkException(
///     exception: e,
///     message: e.toString(),
///     stackTrace: stackTrace,
///   ));
///
///   runApp(MyApp());
/// }
/// ```
///
/// See also:
/// - [NetworkBoundResources.asFuture] for simple async requests
/// - [NetworkBoundResources.asStream] for streaming data with caching
library;

export 'src/network_bound_resources.dart';
export 'src/app_exception.dart';
export 'src/resource.dart';
export 'src/status.dart';
export 'src/widgets/list_view_resource_widget.dart';
export 'src/widgets/resource_widget.dart';
