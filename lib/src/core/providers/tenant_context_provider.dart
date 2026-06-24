import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_providers.dart';

class TenantContext {
  const TenantContext({
    required this.userId,
    required this.tenantId,
    required this.role,
  });

  final String userId;
  final String? tenantId;
  final String? role;

  bool get isPlatformAdmin {
    return role == 'super_admin' ||
        role == 'support_admin' ||
        role == 'billing_admin';
  }

  bool get hasTenant {
    return tenantId != null && tenantId!.isNotEmpty;
  }

  bool hasAnyRole(Set<String> roles) {
    final currentRole = role;
    return currentRole != null && roles.contains(currentRole);
  }
}

final tenantContextProvider = FutureProvider<TenantContext?>((ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) {
    return null;
  }

  final tokenResult = await user.getIdTokenResult();
  final claims = tokenResult.claims ?? const <String, dynamic>{};

  return TenantContext(
    userId: user.uid,
    tenantId: _readStringClaim(claims, const ['tenant_id', 'tenantId']),
    role: _readStringClaim(claims, const ['role']),
  );
});

String? _readStringClaim(Map<String, dynamic> claims, List<String> keys) {
  for (final key in keys) {
    final value = claims[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}
