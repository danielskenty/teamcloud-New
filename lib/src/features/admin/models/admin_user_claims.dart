class AdminUserClaims {
  const AdminUserClaims({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.disabled,
    required this.role,
    required this.tenantId,
  });

  final String uid;
  final String email;
  final String displayName;
  final bool disabled;
  final String role;
  final String tenantId;

  factory AdminUserClaims.empty() {
    return const AdminUserClaims(
      uid: '',
      email: '',
      displayName: '',
      disabled: false,
      role: '',
      tenantId: '',
    );
  }

  factory AdminUserClaims.fromMap(Map<String, dynamic> map) {
    return AdminUserClaims(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      disabled: map['disabled'] == true,
      role: map['role'] as String? ?? '',
      tenantId: map['tenantId'] as String? ?? '',
    );
  }
}
