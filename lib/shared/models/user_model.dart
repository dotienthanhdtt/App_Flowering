class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String? nativeLanguageId;
  final String? nativeLanguageCode;
  final String? nativeLanguageName;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.nativeLanguageId,
    this.nativeLanguageCode,
    this.nativeLanguageName,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      nativeLanguageId: json['nativeLanguageId'] as String?,
      nativeLanguageCode: json['nativeLanguageCode'] as String?,
      nativeLanguageName: json['nativeLanguageName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'nativeLanguageId': nativeLanguageId,
      'nativeLanguageCode': nativeLanguageCode,
      'nativeLanguageName': nativeLanguageName,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? nativeLanguageId,
    String? nativeLanguageCode,
    String? nativeLanguageName,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      nativeLanguageId: nativeLanguageId ?? this.nativeLanguageId,
      nativeLanguageCode: nativeLanguageCode ?? this.nativeLanguageCode,
      nativeLanguageName: nativeLanguageName ?? this.nativeLanguageName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
