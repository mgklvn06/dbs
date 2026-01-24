class UserEntity {
  final String id;
  final String email;
  final String? avatarUrl;

  const UserEntity({
    required this.id,
    required this.email,
    this.avatarUrl,
  });

  void fold(void Function(Object? failure) onFailure, void Function(UserEntity) onSuccess) {}
}
