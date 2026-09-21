String uploadMimeTypeForFilename(String filename) {
  final lower = filename.trim().toLowerCase();
  return switch (lower) {
    _ when lower.endsWith('.jpg') || lower.endsWith('.jpeg') => 'image/jpeg',
    _ when lower.endsWith('.png') => 'image/png',
    _ when lower.endsWith('.webp') => 'image/webp',
    _ when lower.endsWith('.mp3') => 'audio/mpeg',
    _ when lower.endsWith('.aac') => 'audio/aac',
    _ when lower.endsWith('.ogg') || lower.endsWith('.opus') => 'audio/ogg',
    _ when lower.endsWith('.wav') => 'audio/wav',
    _ when lower.endsWith('.m4a') => 'audio/mp4',
    _ when lower.endsWith('.webm') => 'audio/webm',
    _ when lower.endsWith('.mp4') => 'video/mp4',
    _ when lower.endsWith('.pdf') => 'application/pdf',
    _ when lower.endsWith('.apk') => 'application/vnd.android.package-archive',
    _ when lower.endsWith('.zip') => 'application/zip',
    _ when lower.endsWith('.txt') => 'text/plain',
    _ => 'application/octet-stream',
  };
}

String uploadMimeTypeForBytes(List<int> bytes, String filename) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return 'image/jpeg';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47) {
    return 'image/png';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'image/webp';
  }
  return uploadMimeTypeForFilename(filename);
}

/// Keeps the upload filename extension consistent with the detected MIME type.
///
/// Image preparation may re-encode a PNG/WebP source as JPEG. The media service
/// validates the declared content type against the file signature, so retaining
/// the source extension would cause an otherwise valid upload to be rejected.
String uploadFilenameForMimeType(String filename, String contentType) {
  final extension = switch (contentType.trim().toLowerCase()) {
    'image/jpeg' => 'jpg',
    'image/png' => 'png',
    'image/webp' => 'webp',
    _ => null,
  };
  if (extension == null) return filename;

  final trimmed = filename.trim();
  if (trimmed.isEmpty) return 'image.$extension';
  final dot = trimmed.lastIndexOf('.');
  final stem = dot > 0 ? trimmed.substring(0, dot) : trimmed;
  return '$stem.$extension';
}
