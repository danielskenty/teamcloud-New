Nomba Integration Guide

Overview

This project includes a mockable Nomba payment provider and guidance for production integration. Nomba (formerly Paystack in some markets) requires server-side secret API keys for security-sensitive operations.

Recommended architecture

- Client (Flutter app): Collect payment intent and call a secure backend endpoint.
- Backend: Uses Nomba secret key to create a charge/transaction and returns a payment confirmation or URL to the client.

Steps to integrate Nomba (production)

1. Create a backend endpoint (Node/Express, Firebase Function, etc.) at `/create-payment` that:
   - Accepts POST JSON: `{ amount, currency, reference, metadata }`
   - Calls Nomba server API with your secret key to create the payment
   - Verifies the response and returns `{ success: true, transactionId, message }` or an error

2. Secure the backend:
   - Require authentication or verify tenant context
   - Rate limit and log requests
   - Keep secret keys in environment variables (never in client code)

3. Webhooks (recommended):
   - Configure Nomba webhooks to notify your backend of payment success/failure
   - Update Firestore or your database when webhook confirms payment

4. Client-side (Flutter):
   - Set `NombaPaymentProvider(backendEndpoint: 'https://your-backend')`
   - Use the checkout flow to call `processPayment` which hits your backend
   - On success, create the `Sale` record referencing the `transactionId`

Security notes

- Do not embed Nomba secret keys in the Flutter app.
- Validate tenant and user authorization in your backend before creating charges.

Testing

- Implement a staging backend and connect to Nomba's test credentials.
- Use test cards or sandbox tools provided by Nomba for sandbox payments.

Example backend (Node.js/Express) sketch

```js
const express = require('express');
const fetch = require('node-fetch');
const app = express();
app.use(express.json());

app.post('/create-payment', async (req, res) => {
  const { amount, currency, reference, metadata } = req.body;
  // Validate input and authenticate caller

  // Call Nomba API using server-side secret key
  const resp = await fetch('https://api.nomba.com/v1/transactions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${process.env.NOMBA_SECRET}`,
    },
    body: JSON.stringify({ amount, currency, reference, metadata }),
  });
  const data = await resp.json();
  if (resp.ok) {
    res.json({ success: true, transactionId: data.id, message: 'Created' });
  } else {
    res.status(500).json({ success: false, message: data.message || 'error' });
  }
});

app.listen(3000);
```

Support

If you want, I can scaffold a minimal backend function (Firebase Function or Node express) for Nomba calls and a webhook handler. Which backend platform do you prefer? (Firebase Functions / Express on Cloud Run / Other)
