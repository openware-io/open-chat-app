enum GvErrorType {
  network,
  unauthorized,
  validation,
  notFound,
  server,
  cancelled,
  unknown,
}

class GvAppError {
  const GvAppError({
    required this.type,
    required this.message,
    this.code,
    this.cause,
    this.stackTrace,
  });

  final GvErrorType type;
  final String message;
  final String? code;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final suffix = code == null ? '' : ' ($code)';
    return 'GvAppError.${type.name}$suffix: $message';
  }
}
