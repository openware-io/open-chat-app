class MediaUploadResult {
  const MediaUploadResult({
    required this.objectId,
    required this.url,
    required this.contentType,
    required this.size,
  });

  final String objectId;
  final String url;
  final String contentType;
  final int size;
}
