import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../payment_provider.dart';

class NombaPaymentProvider implements PaymentProvider {
  final String backendEndpoint; // e.g., your server that talks to Nomba
  final FirebaseAuth _auth;

  NombaPaymentProvider({required this.backendEndpoint, FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<PaymentResult> processPayment({
    required int amountCents,
    required String currency,
    required String reference,
    Map<String, dynamic>? metadata,
  }) async {
    // IMPORTANT: Do not call Nomba's secret API keys from the client app.
    // Implement a backend endpoint that accepts the payment request and
    // performs the Nomba API call securely using server-side credentials.

    // Get Firebase ID token to authenticate with backend
    String? idToken;
    try {
      final user = _auth.currentUser;
      if (user != null) {
        idToken = await user.getIdToken();
      }
    } catch (e) {
      return PaymentResult(success: false, message: 'Failed to get auth token: $e');
    }

    if (idToken == null) {
      return PaymentResult(success: false, message: 'User not authenticated');
    }

    final uri = Uri.parse('$backendEndpoint/create-payment');
    final body = json.encode({
      'amount': amountCents,
      'currency': currency,
      'reference': reference,
      'metadata': metadata ?? {},
    });

    try {
      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: body,
      ).timeout(const Duration(seconds: 15));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        return PaymentResult(
          success: data['success'] == true,
          transactionId: data['transactionId'] as String?,
          message: data['message'] as String? ?? 'Nomba backend success',
        );
      }

      return PaymentResult(success: false, message: 'Payment backend returned ${resp.statusCode}');
    } catch (e) {
      return PaymentResult(success: false, message: e.toString());
    }
  }
}
