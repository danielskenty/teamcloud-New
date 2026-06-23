Nomba backend (Firebase Functions)

This folder contains a minimal Firebase Functions Express app that exposes two endpoints:

- `POST /create-payment` - Accepts `{ amount, currency, reference, metadata }` and calls Nomba API using the server-side secret key. **Requires Firebase ID token in Authorization header (`Bearer <idToken>`)**. Returns `{ success, transactionId, reference, ... }`.
- `POST /webhook` - Webhook endpoint to receive asynchronous payment events from Nomba (no auth required; uses signature verification).

Authentication

- `/create-payment` verifies Firebase ID tokens and ensures the caller's tenant matches the metadata tenant.
- Callers must include `Authorization: Bearer <idToken>` header.
- The idToken is issued by Firebase Auth and contains tenant/custom claims.

Webhook handling

- The webhook endpoint attempts to verify the signature header (`x-nomba-signature` or `x-paystack-signature`) using the function config key `nomba.webhook_secret`.
- On receiving a successful payment event the function will:
	- write a payment record to `payments/{transactionId}` (includes the `reference` for reconciliation).
	- attempt to locate a matching sale document under `tenants/{tenantId}/sales` (preferring direct `paymentRef == reference` match, with fallback to heuristics).
	- mark matching sale `status: "confirmed"` and set `paymentRef: transactionId`.

Configure webhook secret:

```bash
firebase functions:config:set nomba.webhook_secret="YOUR_WEBHOOK_SECRET"
```

Setup

1. Install dependencies:

```bash
cd functions
npm install
```

2. Set Nomba secret in functions config (do NOT embed secret in client code):

```bash
firebase functions:config:set nomba.secret="YOUR_NOMBA_SECRET"
```

3. Test locally with the emulator:

```bash
firebase emulators:start --only functions
```

4. Deploy to Firebase:

```bash
firebase deploy --only functions
```

Security

- Verify and validate webhook signatures (if provided by Nomba).
- Authenticate and authorize callers to `/create-payment` if needed.
- Keep secrets in `functions` config or use Secret Manager.

Notes

- Adjust the Nomba API path as needed if their API differs.
- Add logging and error handling for production.
