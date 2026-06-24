# TeamCloud Retail POS — Nomba Payment Flow

This document describes the end-to-end payment flow from client (Flutter) → backend (Firebase Functions) → Nomba → webhook callback → Firestore sale confirmation.

## Overview

The flow is designed for security and reliability:
- **No secrets on client**: Nomba API key lives only on the server.
- **Deterministic reference matching**: Sales and payments are linked by a shared `reference` ID.
- **Webhook verification**: Payment events are verified using HMAC-SHA256 signature.

## Components

### 1. Client (Flutter App)

**File**: `lib/src/features/payments/nomba/nomba_payment_provider.dart`

- User selects "Nomba" payment method on checkout.
- `NombaPaymentProvider.processPayment()` is called with:
  - `amountCents`: total in cents
  - `currency`: e.g., "USD"
  - `reference`: deterministic ID (Firestore doc ID)
  - `metadata`: `{ tenantId, branchId, cashierId }`
- Retrieves Firebase ID token (`await user.getIdToken()`).
- POSTs to backend `/create-payment` with `Authorization: Bearer <idToken>` header.

### 2. Backend (Firebase Functions)

**File**: `functions/index.js`

#### Endpoint: `POST /create-payment`

**Authentication**:
- Verifies Firebase ID token from `Authorization: Bearer <token>` header.
- Extracts `tenant_id` custom claim from token.
- Ensures metadata `tenantId` matches user's `tenant_id`.

**Process**:
1. Validates request: `amount`, `currency`, `reference` required.
2. Calls Nomba API: `POST https://api.nomba.com/v1/transactions` with Nomba secret key (from config).
3. Returns response: `{ success, transactionId, reference, ... }` to client.

**Config**:
```bash
firebase functions:config:set nomba.secret="YOUR_NOMBA_API_KEY"
```

#### Endpoint: `POST /webhook`

**Webhook Secret**:
```bash
firebase functions:config:set nomba.webhook_secret="YOUR_WEBHOOK_SECRET"
```

**Signature Verification**:
- Expects `x-nomba-signature` or `x-paystack-signature` header.
- Verifies HMAC-SHA256 digest of raw request body.

**Process** (on successful payment):
1. Parses Nomba webhook event.
2. Extracts: `transactionId`, `status`, `metadata.reference`, `metadata.tenantId`.
3. Writes `payments/{transactionId}` to Firestore with full event data.
4. Matches sale in `tenants/{tenantId}/sales`:
   - **Preferred**: `paymentRef == reference` (direct match).
   - **Fallback**: Search recent sales for `notes` containing `transactionId` or `paymentRef == transactionId`.
5. Updates matched sale: `status: "confirmed"`, `paymentRef: transactionId`.

### 3. Firestore Models

#### Sale

**Location**: `lib/src/features/sales/models/sale.dart`

Key fields:
- `id`: Firestore doc ID (generated at checkout).
- `paymentRef`: Deterministic reference passed to payment provider (set during checkout).
- `paymentMethod`: "cash" or "nomba".
- `status`: "completed" (after client POST), "confirmed" (after webhook).
- `notes`: Optional; may contain `payment_ref:<transactionId>`.

#### Payment (server-side)

**Firestore path**: `payments/{transactionId}`

Fields:
- `transactionId`: Nomba transaction ID.
- `status`: Payment status from Nomba.
- `reference`: Deterministic reference from metadata (for reconciliation).
- `metadata`: Original metadata (tenantId, branchId, etc.).
- `raw`: Full Nomba event.
- `receivedAt`: Server timestamp.

## Example Flow

### Scenario: User completes checkout with Nomba payment

1. **Client Checkout Screen** (`lib/src/features/pos/views/checkout_screen.dart`):
   ```dart
   final reference = FirebaseFirestore.instance.collection('tenants').doc().id;
   final paymentResult = await paymentClient.processPayment(
     amountCents: 5000,
     currency: 'USD',
     reference: reference,
     metadata: { tenantId: 'tenant-123', branchId: 'branch-1', cashierId: 'cashier-1' }
   );
   // Create Sale with paymentRef: reference
   final sale = Sale(
     id: saleId,
     paymentRef: reference,
     status: 'completed',
     ...
   );
   await saleRepo.createSale(tenantId, sale);
   ```

2. **Backend /create-payment**:
   ```
   POST /create-payment
   Authorization: Bearer <idToken>
   Content-Type: application/json
   {
     "amount": 5000,
     "currency": "USD",
     "reference": "abc-123-def",
     "metadata": { "tenantId": "tenant-123", ... }
   }

   Response:
   {
     "success": true,
     "transactionId": "nomba-txn-xyz",
     "reference": "abc-123-def",
     "message": "Payment created"
   }
   ```

3. **Nomba processes payment**, sends webhook:
   ```
   POST /webhook
   x-nomba-signature: <hmac-sha256>
   {
     "data": {
       "id": "nomba-txn-xyz",
       "status": "success",
       "metadata": {
         "reference": "abc-123-def",
         "tenantId": "tenant-123"
       }
     }
   }
   ```

4. **Backend webhook handler**:
   - Verifies signature.
   - Writes `payments/nomba-txn-xyz` with full event.
   - Queries `tenants/tenant-123/sales` for `paymentRef == "abc-123-def"`.
   - Finds sale (from step 1), updates: `status: "confirmed"`, `paymentRef: "nomba-txn-xyz"`.

5. **Client syncs sale**:
   - Sale now shows `status: "confirmed"` in subsequent queries.
   - Receipt can be generated/printed.

## Testing Checklist

- [ ] Local emulator: `firebase emulators:start --only functions`
- [ ] Deploy to staging/production: `firebase deploy --only functions`
- [ ] Configure Nomba test API key and webhook secret in functions config.
- [x] Configure webhook URL in Nomba dashboard: `https://us-central1-teamcloud-94b3a.cloudfunctions.net/api/webhook`
- [ ] End-to-end test: complete checkout → verify sale `status: "confirmed"` within 10 seconds.
- [ ] Webhook replay: Verify webhook re-delivery updates matching sale correctly.
- [ ] Tenant isolation: Verify a user from tenant-A cannot pay for tenant-B's checkout.

## Security Notes

- **Secrets**: Store `nomba.secret` and `nomba.webhook_secret` in Firebase Functions config, not in code.
- **Auth**: `/create-payment` enforces Firebase Auth and tenant match.
- **Webhook**: Signature verification prevents replay/injection attacks.
- **CORS**: Functions are CORS-enabled; tighten as needed for production.
- **Custom claims**: Ensure Firebase Auth rules include `tenant_id` in ID tokens (via `setCustomUserClaims` admin SDK).

## Debugging

- Check Functions logs: `firebase functions:log`
- Local emulator: `firebase emulators:start`
- Nomba sandbox API for testing: https://developer.nomba.com/docs (check current endpoint).
