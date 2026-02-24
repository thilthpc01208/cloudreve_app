import 'dart:convert';

class File {
  String id;
  String name;
  String path;
  String uri;
  String thumbnail;
  bool thumb;
  int size;
  String type;
  String date;
  String createDate;
  bool sourceEnabled;

  File({
    required this.id,
    required this.name,
    required this.path,
    required this.uri,
    required this.thumbnail,
    required this.thumb,
    required this.size,
    required this.type,
    required this.date,
    required this.createDate,
    required this.sourceEnabled,
  });

  factory File.fromMap(Map<String, dynamic> map) {
    final id = _stringOf(map['id'] ?? map['file_id'] ?? map['source_id']);
    final name = _stringOf(map['name'] ?? map['display_name']);
    final path = _stringOf(map['path']);
    final uri = _stringOf(map['uri']).isNotEmpty
        ? _stringOf(map['uri'])
        : _buildUri(path, name);
    final thumbnail = _stringOf(
      map['thumbnail'] ?? map['thumb_url'] ?? map['preview_url'],
    );
    final thumbFlag = map['thumb'] == true || thumbnail.isNotEmpty;
    final size = _intOf(map['size']) ?? 0;
    final type = _resolveType(map);

    return File(
      id: id,
      name: name,
      path: path,
      uri: uri,
      thumbnail: thumbnail,
      thumb: thumbFlag,
      size: size,
      type: type,
      date: _stringOf(map['date'] ?? map['updated_at'] ?? map['updatedAt']),
      createDate:
          _stringOf(map['create_date'] ?? map['created_at'] ?? map['createdAt']),
      sourceEnabled: _boolOf(map['source_enabled']) ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'path': path,
      'uri': uri,
      'thumbnail': thumbnail,
      'thumb': thumb,
      'size': size,
      'type': type,
      'date': date,
      'create_date': createDate,
      'source_enabled': sourceEnabled,
    };
  }

  String toJson() => json.encode(toMap());

  factory File.fromJson(String source) =>
      File.fromMap(json.decode(source) as Map<String, dynamic>);

  static String _resolveType(Map<String, dynamic> map) {
    final raw = _stringOf(map['type']);
    if (raw.isNotEmpty) return raw;

    final isDir = _boolOf(map['is_dir']) ?? false;
    return isDir ? 'dir' : 'file';
  }

  static String _buildUri(String path, String name) {
    final rawPath = path.startsWith('/') ? path.substring(1) : path;
    final normalizedPath = rawPath.isEmpty
        ? 'cloudreve://my/'
        : (rawPath.endsWith('/')
            ? 'cloudreve://my/$rawPath'
            : 'cloudreve://my/$rawPath/');
    return '$normalizedPath$name';
  }

  static String _stringOf(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static int? _intOf(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static bool? _boolOf(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      if (value == 'true') return true;
      if (value == 'false') return false;
    }
    return null;
  }
}
