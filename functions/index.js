const functions = require('firebase-functions');
const admin = require('firebase-admin');
const express = require('express');
const fetch = require('node-fetch');
const cors = require('cors');

admin.initializeApp();
const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

// We need raw body for webhook signature verification. Create a raw parser for
// the webhook route below and use it before the JSON parser would run.
const rawBodyMiddleware = express.raw({ type: '*/*' });

// Middleware to verify Firebase ID token
const verifyIdToken = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, message: 'Missing or invalid authorization' });
  }

  const token = authHeader.substring(7);
  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    req.user = decodedToken;
    next();
  } catch (err) {
    console.error('Token verification failed', err.message);
    return res.status(401).json({ success: false, message: 'Unauthorized: invalid token' });
  }
};

// Create a payment via Nomba - server-side only (requires Firebase auth)
app.post('/create-payment', verifyIdToken, async (req, res) => {
  try {
    const { amount, currency, reference, metadata } = req.body;
    const userTenantId = req.user.tenant_id || req.user.tenantId;

    if (!amount || !currency || !reference) {
      return res.status(400).json({ success: false, message: 'Missing required fields' });
    }

    // Ensure caller's tenant matches the metadata tenant
    const metadataTenantId = metadata?.tenantId;
    if (metadataTenantId && userTenantId && metadataTenantId !== userTenantId) {
      return res.status(403).json({ success: false, message: 'Tenant mismatch' });
    }

    // Read secret from functions config: `firebase functions:config:set nomba.secret="<secret>"`
    const config = functions.config();
    const secret = config?.nomba?.secret;
    if (!secret) {
      console.error('Nomba secret not configured.');
      return res.status(500).json({ success: false, message: 'Payment secret not configured' });
    }

    // Call Nomba API (server-side) - replace endpoint if Nomba API path differs
    const resp = await fetch('https://api.nomba.com/v1/transactions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${secret}`,
      },
      body: JSON.stringify({ amount, currency, reference, metadata }),
    });

    const data = await resp.json();

    if (!resp.ok) {
      console.error('Nomba API error', data);
      return res.status(502).json({ success: false, message: data?.message || 'Nomba API error', details: data });
    }

    // Return response with transaction ID and reference for client reconciliation
    const transactionId = data?.id || data?.transactionId;
    return res.json({
      success: true,
      transactionId,
      reference,
      message: 'Payment created',
      data,
    });
  } catch (err) {
    console.error('create-payment error', err);
    return res.status(500).json({ success: false, message: err.message || 'Internal server error' });
  }
});

// Webhook endpoint: Nomba will POST here to notify payment status changes.
app.post('/webhook', rawBodyMiddleware, async (req, res) => {
  try {
    const raw = req.body; // Buffer
    const signature = req.headers['x-nomba-signature'] || req.headers['x-paystack-signature'];

    const config = functions.config();
    const webhookSecret = config?.nomba?.webhook_secret;

    if (webhookSecret && signature) {
      const crypto = require('crypto');
      const hmac = crypto.createHmac('sha256', webhookSecret);
      hmac.update(raw);
      const digest = hmac.digest('hex');
      if (digest !== signature) {
        console.warn('Webhook signature mismatch');
        return res.status(403).send('invalid signature');
      }
    } else {
      console.warn('No webhook secret or signature present; skipping verification');
    }

    // Parse JSON body after verification
    const event = JSON.parse(raw.toString('utf8'));
    console.log('Received webhook event:', JSON.stringify(event));

    // Normalise transaction id and metadata
    const transactionId = event?.data?.id || event?.data?.transactionId || event?.id || null;
    const status = event?.data?.status || event?.status || event?.event || null;
    const metadata = event?.data?.metadata || event?.metadata || {};
    const tenantId = metadata?.tenantId || metadata?.tenant_id || null;
    const reference = metadata?.reference || metadata?.reference_id || metadata?.ref || null;

    const db = admin.firestore();

    if (transactionId) {
      // Record the payment event
      const paymentRef = db.collection('payments').doc(transactionId);
      await paymentRef.set({
        transactionId,
        status,
        metadata,
        reference,
        raw: event,
        receivedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      // Try to find a matching sale and update it to confirmed/paid
      if (tenantId) {
        const salesCol = db.collection(`tenants/${tenantId}/sales`);
        let matched = null;

        // Prefer direct reference match if present
        if (reference) {
          const refQuery = await salesCol.where('paymentRef', '==', reference).limit(1).get();
          if (!refQuery.empty) {
            matched = refQuery.docs[0];
          }
        }

        // Fallback to searching recent sales for transactionId in notes or paymentRef equal to transactionId
        if (!matched) {
          const candidates = await salesCol.orderBy('createdAt', 'desc').limit(200).get();
          for (const doc of candidates.docs) {
            const data = doc.data();
            const notes = data.notes || '';
            if (notes && notes.toString().includes(transactionId)) {
              matched = doc;
              break;
            }
            if (data.paymentRef && data.paymentRef === transactionId) {
              matched = doc;
              break;
            }
          }
        }

        if (matched) {
          await matched.ref.update({
            status: 'confirmed',
            paymentRef: transactionId,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(`Updated sale ${matched.id} for tenant ${tenantId} as confirmed`);
        } else {
          console.log('No matching sale found for transactionId', transactionId, 'reference', reference);
        }
      }
    } else {
      console.warn('Webhook received without transaction id');
    }

    return res.status(200).send('ok');
  } catch (err) {
    console.error('webhook error', err);
    return res.status(500).send('error');
  }
});

exports.api = functions.https.onRequest(app);
