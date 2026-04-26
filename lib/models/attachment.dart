enum AttachmentType {
  image,
  video,
  audio,
  pdf,
  youtube,
  link;

  static AttachmentType fromString(String value) {
    return AttachmentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AttachmentType.link,
    );
  }
}

class Attachment {
  final String url;
  final AttachmentType type;
  final String name;
  final int? sizeBytes;
  final String? thumbnailUrl;

  const Attachment({
    required this.url,
    required this.type,
    this.name = '',
    this.sizeBytes,
    this.thumbnailUrl,
  });

  factory Attachment.fromJson(Map<String, dynamic> data) {
    return Attachment(
      url: data['url'] as String? ?? '',
      type: AttachmentType.fromString(data['type'] as String? ?? 'link'),
      name: data['name'] as String? ?? '',
      sizeBytes: (data['sizeBytes'] as num?)?.toInt(),
      thumbnailUrl: data['thumbnailUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'type': type.name,
        'name': name,
        if (sizeBytes != null) 'sizeBytes': sizeBytes,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      };

  bool get isImage => type == AttachmentType.image;
  bool get isVideo => type == AttachmentType.video;
  bool get isAudio => type == AttachmentType.audio;
  bool get isPdf => type == AttachmentType.pdf;
  bool get isYouTube => type == AttachmentType.youtube;

  static AttachmentType inferType(String url) {
    final lower = url.toLowerCase();
    if (_isYouTubeUrl(lower)) return AttachmentType.youtube;
    if (lower.endsWith('.pdf')) return AttachmentType.pdf;
    if (_imageExts.any((e) => lower.endsWith(e))) return AttachmentType.image;
    if (_videoExts.any((e) => lower.endsWith(e))) return AttachmentType.video;
    if (_audioExts.any((e) => lower.endsWith(e))) return AttachmentType.audio;
    return AttachmentType.link;
  }

  static bool _isYouTubeUrl(String url) =>
      url.contains('youtube.com/watch') ||
      url.contains('youtu.be/') ||
      url.contains('youtube.com/embed');

  static String? extractYouTubeId(String url) {
    final patterns = [
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]+)'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]+)'),
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]+)'),
    ];
    for (final p in patterns) {
      final match = p.firstMatch(url);
      if (match != null) return match.group(1);
    }
    return null;
  }

  static const _imageExts = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
  static const _videoExts = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
  static const _audioExts = ['.mp3', '.wav', '.aac', '.ogg', '.m4a', '.flac'];
}
