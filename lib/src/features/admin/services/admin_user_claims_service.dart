import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/backend_config.dart';
import '../models/admin_user_claims.dart';

class AdminUserClaimsService {
  AdminUserClaimsService({
    String backendEndpoint = BackendConfig.functionsUrl,
    FirebaseAuth? auth,
    http.Client? client,
  }) : _backendEndpoint = backendEndpoint,
       _auth = auth ?? FirebaseAuth.instance,
       _client = client ?? http.Client();

  final String _backendEndpoint;
  final FirebaseAuth _auth;
  final http.Client _client;

  Future<AdminUserClaims> lookup({String email = '', String uid = ''}) async {
    final query = <String, String>{};
    if (uid.trim().isNotEmpty) {
      query['uid'] = uid.trim();
    } else if (email.trim().isNotEmpty) {
      query['email'] = email.trim();
    }

    final uri = Uri.parse(
      '$_backendEndpoint/admin/user-claims',
    ).replace(queryParameters: query);
    final response = await _client.get(uri, headers: await _headers());
    return _parseUserResponse(response, fallbackMessage: 'Unable to load user');
  }

  Future<AdminUserClaims> save({
    required String uid,
    required String email,
    required String role,
    required String tenantId,
  }) async {
    final response = await _client.post(
      Uri.parse('$_backendEndpoint/admin/user-claims'),
      headers: await _headers(),
      body: jsonEncode({
        'uid': uid.trim(),
        'email': email.trim(),
        'role': role.trim(),
        'tenantId': tenantId.trim(),
      }),
    );
    return _parseUserResponse(response, fallbackMessage: 'Unable to save user');
  }

  AdminUserClaims _parseUserResponse(
    http.Response response, {
    required String fallbackMessage,
  }) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(body['message'] as String? ?? fallbackMessage);
    }

    final user = body['user'];
    if (user is! Map<String, dynamic>) {
      return AdminUserClaims.empty();
    }
    return AdminUserClaims.fromMap(user);
  }

  Future<Map<String, String>> _headers() async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}
