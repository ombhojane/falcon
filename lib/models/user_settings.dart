class UserSettings {
  final String name;
  final String avatar;

  UserSettings({
    required this.name,
    required this.avatar,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      name: json['name'] as String? ?? 'User',
      avatar: json['avatar'] as String? ?? '👤',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'avatar': avatar,
    };
  }
}
