extension GvNullableStringExtensions on String? {
  bool get isBlank => this == null || this!.trim().isEmpty;

  String? get trimmedOrNull {
    final value = this?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }
}

extension GvStringExtensions on String {
  bool get isNotBlank => trim().isNotEmpty;
}
