/// Represents the possible states of a [Resource].
///
/// A [Status] indicates the current state of an asynchronous operation,
/// typically a network request or data fetch operation.
///
/// ## States
///
/// - [loading]: The operation is in progress. The [Resource] may or may not
///   have data from a previous operation or cache.
/// - [success]: The operation completed successfully. The [Resource] should
///   contain the resulting data.
/// - [failed]: The operation failed with an error. The [Resource] will contain
///   error information and may contain previous data.
///
/// ## Usage
///
/// ```dart
/// final resource = Resource<User>.loading();
///
/// switch (resource.status) {
///   case Status.loading:
///     return CircularProgressIndicator();
///   case Status.success:
///     return UserWidget(user: resource.data!);
///   case Status.failed:
///     return ErrorWidget(message: resource.message);
/// }
/// ```
///
/// See also:
/// - [Resource] for the main class that uses this enum.
/// - [Resource.isLoading], [Resource.isSuccess], [Resource.isFailed] for
///   convenient boolean getters.
enum Status {
  /// Indicates that an operation is currently in progress.
  ///
  /// During this state, the [Resource] may contain stale data from a
  /// previous successful operation, which can be displayed while waiting
  /// for fresh data.
  loading,

  /// Indicates that an operation completed successfully.
  ///
  /// The [Resource] should contain valid data in this state.
  success,

  /// Indicates that an operation failed with an error.
  ///
  /// The [Resource] will contain error information via [Resource.error]
  /// and [Resource.message]. It may also contain data from a previous
  /// successful operation.
  failed,
}
