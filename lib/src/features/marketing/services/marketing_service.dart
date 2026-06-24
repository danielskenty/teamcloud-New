import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/backend_config.dart';

class MarketingService {
  MarketingService({
    String backendEndpoint = BackendConfig.functionsUrl,
    http.Client? client,
  }) : _backendEndpoint = backendEndpoint,
       _client = client ?? http.Client();

  final String _backendEndpoint;
  final http.Client _client;

  Future<MarketingSubmissionResult> submitSignup({
    required String plan,
    required String name,
    required String businessName,
    required String email,
    required String phone,
  }) async {
    final response = await _client.post(
      Uri.parse('$_backendEndpoint/public/signup-request'),
      headers: _headers,
      body: jsonEncode({
        'plan': plan.trim(),
        'name': name.trim(),
        'businessName': businessName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
      }),
    );
    return _parseResponse(
      response,
      fallbackMessage: 'Unable to submit signup request',
    );
  }

  Future<MarketingSubmissionResult> submitContact({
    required String name,
    required String email,
    required String message,
  }) async {
    final response = await _client.post(
      Uri.parse('$_backendEndpoint/public/contact-request'),
      headers: _headers,
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
        'message': message.trim(),
      }),
    );
    return _parseResponse(
      response,
      fallbackMessage: 'Unable to submit contact request',
    );
  }

  MarketingSubmissionResult _parseResponse(
    http.Response response, {
    required String fallbackMessage,
  }) {
    final decoded = jsonDecode(response.body);
    final body = decoded is Map<String, dynamic>
        ? decoded
        : const <String, dynamic>{};
    final message = body['message'] as String? ?? fallbackMessage;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(message);
    }

    return MarketingSubmissionResult(
      requestId: body['requestId'] as String? ?? '',
      message: message,
    );
  }

  static const _headers = {'Content-Type': 'application/json'};
}

class MarketingSubmissionResult {
  const MarketingSubmissionResult({
    required this.requestId,
    required this.message,
  });

  final String requestId;
  final String message;
}
