import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/backend_config.dart';
import '../models/nomba_config.dart';

class NombaConfigService {
  NombaConfigService({
    String backendEndpoint = BackendConfig.functionsUrl,
    FirebaseAuth? auth,
    http.Client? client,
  }) : _backendEndpoint = backendEndpoint,
       _auth = auth ?? FirebaseAuth.instance,
       _client = client ?? http.Client();

  final String _backendEndpoint;
  final FirebaseAuth _auth;
  final http.Client _client;

  Future<NombaConfig> getConfig() async {
    final response = await _client.get(
      Uri.parse('$_backendEndpoint/admin/nomba-config'),
      headers: await _headers(),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        body['message'] as String? ?? 'Unable to load Nomba keys',
      );
    }

    final config = body['config'];
    if (config is! Map<String, dynamic>) {
      return NombaConfig.empty();
    }
    return NombaConfig.fromMap(config);
  }

  Future<NombaConfig> saveConfig({
    required String mode,
    required NombaKeyPayload test,
    required NombaKeyPayload live,
  }) async {
    final response = await _client.post(
      Uri.parse('$_backendEndpoint/admin/nomba-config'),
      headers: await _headers(),
      body: jsonEncode({
        'mode': mode,
        'test': test.toMap(),
        'live': live.toMap(),
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        body['message'] as String? ?? 'Unable to save Nomba keys',
      );
    }

    final config = body['config'];
    if (config is! Map<String, dynamic>) {
      return NombaConfig.empty();
    }
    return NombaConfig.fromMap(config);
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

class NombaKeyPayload {
  const NombaKeyPayload({
    required this.publicKey,
    required this.secretKey,
    required this.webhookSecret,
  });

  final String publicKey;
  final String secretKey;
  final String webhookSecret;

  Map<String, dynamic> toMap() {
    return {
      'publicKey': publicKey.trim(),
      'secretKey': secretKey.trim(),
      'webhookSecret': webhookSecret.trim(),
    };
  }
}
