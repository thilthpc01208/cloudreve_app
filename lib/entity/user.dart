import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'group.dart';

class User {
  String id;
  String user_name;
  String nickname;
  String language;
  int status;
  String avatar;
  String created_at;
  bool anonymous;
  Group group;
  List tags;

  User(
    this.id,
    this.user_name,
    this.nickname,
    this.language,
    this.status,
    this.avatar,
    this.created_at,
    this.anonymous,
    this.group,
    this.tags,
  );

  factory User.fromMap(Map<String, dynamic> map) {
    final groupMap = map['group'] is Map<String, dynamic>
        ? map['group'] as Map<String, dynamic>
        : <String, dynamic>{};

    return User(
      _stringOf(map['id']),
      _stringOf(map['user_name'] ?? map['username'] ?? map['email']),
      _stringOf(map['nickname'] ?? map['name'] ?? map['user_name']),
      _stringOf(map['language'] ?? map['locale']),
      _intOf(map['status']) ?? 0,
      _stringOf(map['avatar']),
      _stringOf(map['created_at'] ?? map['createdAt']),
      _boolOf(map['anonymous']) ?? false,
      Group.fromMap(groupMap),
      List.from(map['tags'] is List ? map['tags'] : const []),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'user_name': user_name,
      'nickname': nickname,
      'language': language,
      'status': status,
      'avatar': avatar,
      'created_at': created_at,
      'anonymous': anonymous,
      'group': group.toMap(),
      'tags': tags,
    };
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) =>
      User.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(covariant User other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.user_name == user_name &&
        other.nickname == nickname &&
        other.language == language &&
        other.status == status &&
        other.avatar == avatar &&
        other.created_at == created_at &&
        other.anonymous == anonymous &&
        other.group == group &&
        listEquals(other.tags, tags);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        user_name.hashCode ^
        nickname.hashCode ^
        language.hashCode ^
        status.hashCode ^
        avatar.hashCode ^
        created_at.hashCode ^
        anonymous.hashCode ^
        group.hashCode ^
        tags.hashCode;
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
