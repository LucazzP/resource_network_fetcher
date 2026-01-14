/// Stores metadata about the history of a [Resource]'s data changes.
///
/// [ResourceMetaData] keeps track of the current data and the last few
/// data values that a [Resource] has held. This is particularly useful
/// when working with streams, where you might need to compare the current
/// data with previous values or detect changes.
///
/// ## Usage
///
/// When using [NetworkBoundResources.asSimpleStream], [NetworkBoundResources.asResourceStream],
/// or [NetworkBoundResources.asStream], the metadata is automatically managed.
///
/// ```dart
/// var resource = Resource.success(data: <String>[]);
/// resource = resource.addData(Status.success, ["newData"]);
///
/// // Access the current data
/// print(resource.metaData.data); // ["newData"]
///
/// // Access the history of results (up to 2 previous values)
/// print(resource.metaData.results); // [["newData"], []]
/// ```
///
/// ## Properties
///
/// - [data]: The current data value.
/// - [results]: A list containing up to 2 previous data values.
///
/// See also:
/// - [Resource.metaData] for accessing metadata from a resource.
/// - [Resource.addData] for adding new data and updating metadata.
class ResourceMetaData<T> {
  /// The current data value in the resource.
  ///
  /// This represents the most recent data that was added to the resource.
  final T? data;

  /// A list of the most recent data values (up to 2 entries).
  ///
  /// The list is ordered with the most recent value first. This allows
  /// tracking changes over time and comparing current data with previous
  /// values.
  ///
  /// Note: The list maintains a maximum of 2 entries to conserve memory.
  final List<T?> results;

  /// Creates a new [ResourceMetaData] with the given [data].
  ///
  /// The [results] list will be empty when using this constructor.
  const ResourceMetaData({
    this.data,
  }) : results = const [];

  const ResourceMetaData._({
    this.data,
    this.results = const [],
  });

  /// Creates a new [ResourceMetaData] with updated data.
  ///
  /// The current [data] is moved to the [results] list, and [newData]
  /// becomes the new current data. The [results] list is capped at 2
  /// entries, removing the oldest entry if necessary.
  ///
  /// Returns a new [ResourceMetaData] instance with the updated values.
  ///
  /// Example:
  /// ```dart
  /// final meta = ResourceMetaData<int>(data: 1);
  /// final updated = meta.addData(2);
  /// print(updated.data); // 2
  /// print(updated.results); // [1]
  /// ```
  ResourceMetaData<T> addData(T? newData) {
    final resultsCopy = List<T?>.from(results);
    resultsCopy.insert(0, data);
    if (resultsCopy.length > 2) {
      resultsCopy.removeLast();
    }
    return ResourceMetaData._(
      data: newData,
      results: resultsCopy,
    );
  }
}
