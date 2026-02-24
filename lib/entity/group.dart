import 'dart:convert';

class Group {
  int id;
  String name;
  bool allowShare;
  bool allowRemoteDownload;
  bool allowArchiveDownload;
  bool shareDownload;
  bool compress;
  bool webdav;
  int sourceBatch;
  bool advanceDelete;
  bool allowWebDAVProxy;

  Group(
    this.id,
    this.name,
    this.allowShare,
    this.allowRemoteDownload,
    this.allowArchiveDownload,
    this.shareDownload,
    this.compress,
    this.webdav,
    this.sourceBatch,
    this.advanceDelete,
    this.allowWebDAVProxy,
  );

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      _intOf(map['id']) ?? 0,
      _stringOf(map['name'] ?? map['group_name'] ?? 'User'),
      _boolOf(map['allowShare']) ?? false,
      _boolOf(map['allowRemoteDownload']) ?? false,
      _boolOf(map['allowArchiveDownload']) ?? false,
      _boolOf(map['shareDownload']) ?? false,
      _boolOf(map['compress']) ?? false,
      _boolOf(map['webdav']) ?? false,
      _intOf(map['sourceBatch']) ?? 0,
      _boolOf(map['advanceDelete']) ?? false,
      _boolOf(map['allowWebDAVProxy']) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'allowShare': allowShare,
      'allowRemoteDownload': allowRemoteDownload,
      'allowArchiveDownload': allowArchiveDownload,
      'shareDownload': shareDownload,
      'compress': compress,
      'webdav': webdav,
      'sourceBatch': sourceBatch,
      'advanceDelete': advanceDelete,
      'allowWebDAVProxy': allowWebDAVProxy,
    };
  }

  String toJson() => json.encode(toMap());

  factory Group.fromJson(String source) =>
      Group.fromMap(json.decode(source) as Map<String, dynamic>);

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
