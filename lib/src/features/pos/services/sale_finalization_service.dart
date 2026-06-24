import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/cart_item.dart';

class FinalizedSaleResult {
  const FinalizedSaleResult({required this.success, this.saleId, this.message});

  final bool success;
  final String? saleId;
  final String? message;
}

class SaleFinalizationService {
  SaleFinalizationService({
    required this.backendEndpoint,
    FirebaseAuth? auth,
    http.Client? client,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _client = client ?? http.Client();

  final String backendEndpoint;
  final FirebaseAuth _auth;
  final http.Client _client;

  Future<FinalizedSaleResult> finalizeSale({
    required String tenantId,
    required String branchId,
    required String cashierId,
    required List<CartItem> items,
    required String paymentMethod,
    String? paymentRef,
    String? transactionId,
    String? customerId,
    double discount = 0,
  }) async {
    final user = _auth.currentUser;
    final idToken = await user?.getIdToken();
    if (idToken == null) {
      return const FinalizedSaleResult(
        success: false,
        message: 'User not authenticated',
      );
    }

    final uri = Uri.parse('$backendEndpoint/finalize-sale');
    final response = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'tenantId': tenantId,
            'branchId': branchId,
            'cashierId': cashierId,
            'customerId': customerId,
            'items': items.map((item) => item.toMap()).toList(),
            'paymentMethod': paymentMethod,
            'paymentRef': paymentRef,
            'transactionId': transactionId,
            'discount': discount,
          }),
        )
        .timeout(const Duration(seconds: 20));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return FinalizedSaleResult(
        success: false,
        message: body['message'] as String? ?? 'Sale finalization failed',
      );
    }

    final sale = body['sale'];
    return FinalizedSaleResult(
      success: body['success'] == true,
      saleId: sale is Map<String, dynamic> ? sale['id'] as String? : null,
      message: body['message'] as String?,
    );
  }
}
