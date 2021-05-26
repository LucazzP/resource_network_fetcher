class ResourceMetaData<T> {
  /// The actual data in the resource
  final T? data;

  /// The latest results that occured before the data
  final List<T?> results;

  const ResourceMetaData({
    this.data,
  }) : results = const [];

  const ResourceMetaData._({
    this.data,
    this.results = const [],
  });

  ResourceMetaData<T> addData(T? newData) {
    final _results = List<T?>.from(results);
    _results.insert(0, data);
    if (_results.length > 2) {
      _results.removeLast();
    }
    return ResourceMetaData._(
      data: newData,
      results: _results,
    );
  }
}
