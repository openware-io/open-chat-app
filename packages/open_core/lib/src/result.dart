sealed class GvResult<T> {
  const GvResult();

  R when<R>({
    required R Function(T data) success,
    required R Function(Object error, StackTrace? stackTrace) failure,
  }) {
    return switch (this) {
      GvSuccess<T>(:final data) => success(data),
      GvFailure<T>(:final error, :final stackTrace) =>
        failure(error, stackTrace),
    };
  }
}

final class GvSuccess<T> extends GvResult<T> {
  const GvSuccess(this.data);

  final T data;
}

final class GvFailure<T> extends GvResult<T> {
  const GvFailure(this.error, [this.stackTrace]);

  final Object error;
  final StackTrace? stackTrace;
}
