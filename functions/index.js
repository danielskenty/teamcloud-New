const functions = require('firebase-functions');
const admin = require('firebase-admin');
const express = require('express');
const fetch = require('node-fetch');
const cors = require('cors');
const nodemailer = require('nodemailer');
const PDFDocument = require('pdfkit');

admin.initializeApp();
const app = express();
app.use(cors({ origin: true }));

// We need raw body for webhook signature verification. Create a raw parser for
// the webhook route below and use it before the JSON parser would run.
const rawBodyMiddleware = express.raw({ type: '*/*' });
const jsonBodyMiddleware = express.json();
const nombaConfigRef = () => admin.firestore().doc('platformSettings/nomba');

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

const requireSuperAdmin = (req, res, next) => {
  if (req.user?.role !== 'super_admin') {
    return res.status(403).json({ success: false, message: 'Super admin access required' });
  }
  next();
};

app.get('/admin/user-claims', verifyIdToken, requireSuperAdmin, async (req, res) => {
  try {
    const lookup = normalizeUserLookup(req.query || {});
    if (!lookup.uid && !lookup.email) {
      return res.status(400).json({ success: false, message: 'Provide a user email or uid' });
    }

    const userRecord = lookup.uid
      ? await admin.auth().getUser(lookup.uid)
      : await admin.auth().getUserByEmail(lookup.email);

    return res.json({
      success: true,
      user: publicUserClaims(userRecord),
    });
  } catch (err) {
    console.error('get user claims error', err);
    const status = err.code === 'auth/user-not-found' ? 404 : 500;
    return res.status(status).json({
      success: false,
      message: status === 404 ? 'User not found' : 'Unable to load user claims',
    });
  }
});

app.post('/admin/user-claims', verifyIdToken, requireSuperAdmin, jsonBodyMiddleware, async (req, res) => {
  try {
    const lookup = normalizeUserLookup(req.body || {});
    if (!lookup.uid && !lookup.email) {
      return res.status(400).json({ success: false, message: 'Provide a user email or uid' });
    }

    const role = typeof req.body?.role === 'string' ? req.body.role.trim() : '';
    const tenantId = typeof req.body?.tenantId === 'string'
      ? req.body.tenantId.trim()
      : typeof req.body?.tenant_id === 'string'
        ? req.body.tenant_id.trim()
        : '';

    const validation = validateManagedClaims(role, tenantId);
    if (validation) {
      return res.status(400).json({ success: false, message: validation });
    }

    const userRecord = lookup.uid
      ? await admin.auth().getUser(lookup.uid)
      : await admin.auth().getUserByEmail(lookup.email);

    const existingClaims = userRecord.customClaims || {};
    const nextClaims = { ...existingClaims, role };
    delete nextClaims.tenantId;

    if (tenantId) {
      nextClaims.tenant_id = tenantId;
    } else {
      delete nextClaims.tenant_id;
    }

    await admin.auth().setCustomUserClaims(userRecord.uid, nextClaims);

    const updatedUser = await admin.auth().getUser(userRecord.uid);
    await admin.firestore().collection('auditLogs').add({
      actorId: req.user.uid,
      actorRole: req.user.role,
      action: 'auth.claims.updated',
      resourcePath: `auth/users/${updatedUser.uid}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      metadata: {
        email: updatedUser.email || null,
        role,
        tenantId: tenantId || null,
      },
    });

    return res.json({
      success: true,
      user: publicUserClaims(updatedUser),
    });
  } catch (err) {
    console.error('update user claims error', err);
    const status = err.code === 'auth/user-not-found' ? 404 : 500;
    return res.status(status).json({
      success: false,
      message: status === 404 ? 'User not found' : 'Unable to update user claims',
    });
  }
});

app.get('/admin/nomba-config', verifyIdToken, requireSuperAdmin, async (req, res) => {
  try {
    const config = await getNombaConfig();
    return res.json({
      success: true,
      config: publicNombaConfig(config),
    });
  } catch (err) {
    console.error('get nomba config error', err);
    return res.status(500).json({ success: false, message: 'Unable to load Nomba config' });
  }
});

app.post('/admin/nomba-config', verifyIdToken, requireSuperAdmin, jsonBodyMiddleware, async (req, res) => {
  try {
    const payload = req.body || {};
    const mode = payload.mode === 'live' ? 'live' : 'test';
    const incoming = {
      mode,
      test: sanitizeNombaKeySet(payload.test),
      live: sanitizeNombaKeySet(payload.live),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedBy: req.user.uid,
    };

    await nombaConfigRef().set(incoming, { merge: true });
    const config = await getNombaConfig();

    return res.json({
      success: true,
      config: publicNombaConfig(config),
    });
  } catch (err) {
    console.error('update nomba config error', err);
    return res.status(500).json({ success: false, message: 'Unable to save Nomba config' });
  }
});

// Create a payment via Nomba - server-side only (requires Firebase auth)
app.post('/create-payment', verifyIdToken, jsonBodyMiddleware, async (req, res) => {
  try {
    const { currency = 'USD', reference, metadata, items, discount = 0 } = req.body;
    const userTenantId = req.user.tenant_id || req.user.tenantId;
    const tenantId = metadata?.tenantId || req.body?.tenantId;
    const branchId = metadata?.branchId || req.body?.branchId;

    if (!tenantId || !branchId || !currency || !reference || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ success: false, message: 'Missing required fields' });
    }

    if (!userTenantId || userTenantId !== tenantId) {
      return res.status(403).json({ success: false, message: 'Tenant mismatch' });
    }

    const db = admin.firestore();
    const quote = await calculateSaleQuote(db, tenantId, branchId, items, discount);
    const amount = Math.round(quote.total * 100);

    const nombaConfig = await getNombaConfig();
    const selectedNombaKeys = nombaConfig[nombaConfig.mode] || {};
    const secret = selectedNombaKeys.secretKey || functions.config()?.nomba?.secret;
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
    const paymentIntentRef = db.doc(`tenants/${tenantId}/paymentIntents/${reference}`);
    await paymentIntentRef.set({
      tenantId,
      branchId,
      reference,
      transactionId: transactionId || null,
      provider: 'nomba',
      mode: nombaConfig.mode,
      currency,
      amount,
      subtotal: quote.subtotal,
      discount: quote.discount,
      tax: quote.tax,
      total: quote.total,
      items: quote.items,
      status: 'created',
      createdBy: req.user.uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    return res.json({
      success: true,
      transactionId,
      reference,
      amount,
      total: quote.total,
      mode: nombaConfig.mode,
      message: 'Payment created',
      data,
    });
  } catch (err) {
    console.error('create-payment error', err);
    const status = err.statusCode || 500;
    return res.status(status).json({
      success: false,
      message: err.publicMessage || err.message || 'Internal server error',
    });
  }
});

app.post('/finalize-sale', verifyIdToken, jsonBodyMiddleware, async (req, res) => {
  try {
    const {
      tenantId,
      branchId,
      cashierId,
      customerId = null,
      items,
      paymentMethod,
      paymentRef = null,
      transactionId = null,
      discount = 0,
    } = req.body;

    const userTenantId = req.user.tenant_id || req.user.tenantId;
    const userRole = req.user.role;

    if (!tenantId || !branchId || !cashierId || !paymentMethod || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ success: false, message: 'Missing required sale fields' });
    }

    if (!userTenantId || userTenantId !== tenantId) {
      return res.status(403).json({ success: false, message: 'Tenant mismatch' });
    }

    if (!['cashier', 'business_owner', 'branch_manager', 'sales_staff'].includes(userRole)) {
      return res.status(403).json({ success: false, message: 'Role cannot finalize sales' });
    }

    const db = admin.firestore();
    const saleRef = db.collection(`tenants/${tenantId}/sales`).doc();
    const now = admin.firestore.FieldValue.serverTimestamp();

    const salePayload = await db.runTransaction(async (transaction) => {
      const quote = await calculateSaleQuote(db, tenantId, branchId, items, discount, { transaction });

      if (paymentMethod !== 'cash') {
        if (!paymentRef) {
          throw httpError(400, 'Payment reference is required');
        }
        const paymentIntentRef = db.doc(`tenants/${tenantId}/paymentIntents/${paymentRef}`);
        const paymentIntentDoc = await transaction.get(paymentIntentRef);
        if (!paymentIntentDoc.exists) {
          throw httpError(400, 'Payment intent not found');
        }
        const paymentIntent = paymentIntentDoc.data();
        if (
          paymentIntent.provider !== paymentMethod ||
          paymentIntent.branchId !== branchId ||
          integerValue(paymentIntent.amount) !== Math.round(quote.total * 100)
        ) {
          throw httpError(400, 'Payment intent does not match sale total');
        }
        if (transactionId && paymentIntent.transactionId && paymentIntent.transactionId !== transactionId) {
          throw httpError(400, 'Payment transaction mismatch');
        }
        transaction.update(paymentIntentRef, {
          status: 'used',
          saleId: saleRef.id,
          updatedAt: now,
        });
      }

      for (const stockUpdate of quote.stockUpdates) {
        transaction.update(stockUpdate.inventoryRef, {
          quantity: stockUpdate.nextQuantity,
          available: stockUpdate.nextAvailable,
          updatedAt: now,
        });
        if (stockUpdate.nextProductQuantity != null) {
          transaction.update(stockUpdate.productRef, {
            quantity: stockUpdate.nextProductQuantity,
            updatedAt: now,
          });
        }
      }

      const sale = {
        tenantId,
        branchId,
        cashierId,
        customerId,
        items: quote.items,
        subtotal: quote.subtotal,
        discount: quote.discount,
        tax: quote.tax,
        total: quote.total,
        paymentMethod,
        status: paymentMethod === 'cash' ? 'completed' : 'pending_confirmation',
        paymentRef,
        notes: transactionId ? `payment_ref:${transactionId}` : '',
        createdAt: now,
        updatedAt: now,
        finalizedBy: req.user.uid,
      };

      transaction.set(saleRef, sale);

      const auditRef = db.collection('auditLogs').doc();
      transaction.set(auditRef, {
        tenantId,
        actorId: req.user.uid,
        actorRole: userRole,
        action: 'sale.finalized',
        resourcePath: saleRef.path,
        createdAt: now,
        metadata: {
          branchId,
          cashierId,
          paymentMethod,
          total: quote.total,
        },
      });

      return { id: saleRef.id, ...sale, createdAt: null, updatedAt: null };
    });

    return res.json({ success: true, sale: salePayload });
  } catch (err) {
    console.error('finalize-sale error', err);
    const status = err.statusCode || 500;
    return res.status(status).json({
      success: false,
      message: err.publicMessage || err.message || 'Internal server error',
    });
  }
});

// Webhook endpoint: Nomba will POST here to notify payment status changes.
app.post('/webhook', rawBodyMiddleware, async (req, res) => {
  try {
    const raw = req.body; // Buffer
    const signature = req.headers['x-nomba-signature'] || req.headers['x-paystack-signature'];

    const nombaConfig = await getNombaConfig();
    const webhookSecrets = [
      nombaConfig[nombaConfig.mode]?.webhookSecret,
      nombaConfig.test?.webhookSecret,
      nombaConfig.live?.webhookSecret,
      functions.config()?.nomba?.webhook_secret,
    ].filter(Boolean);

    if (webhookSecrets.length && signature) {
      const crypto = require('crypto');
      const validSignature = webhookSecrets.some((webhookSecret) => {
        const hmac = crypto.createHmac('sha256', webhookSecret);
        hmac.update(raw);
        const digest = hmac.digest('hex');
        return digest === signature;
      });
      if (!validSignature) {
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

          // Optional email receipt when customer email is present
          const customerEmail = matched.data()?.customerEmail || matched.data()?.customer?.email || metadata?.customerEmail || metadata?.customer?.email;
          if (customerEmail) {
            try {
              await sendReceiptEmail(customerEmail, matched.id, tenantId, saleDataToReceiptPayload(matched.data()));
              console.log(`Sent receipt email to ${customerEmail}`);
            } catch (emailError) {
              console.error('Failed to send receipt email', emailError);
            }
          }
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

function saleDataToReceiptPayload(data) {
  if (!data) return null;

  return {
    saleId: data.id || data.saleId,
    tenantId: data.tenantId,
    branchId: data.branchId,
    cashierId: data.cashierId,
    customerEmail: data.customerEmail || data.customer?.email || null,
    items: data.items || [],
    subtotal: data.subtotal,
    tax: data.tax,
    total: data.total,
    paymentMethod: data.paymentMethod,
    status: data.status,
    createdAt: data.createdAt,
  };
}

async function getNombaConfig() {
  const doc = await nombaConfigRef().get();
  const data = doc.exists ? doc.data() : {};
  const fallback = functions.config()?.nomba || {};

  return {
    mode: data.mode === 'live' ? 'live' : 'test',
    test: {
      publicKey: data.test?.publicKey || '',
      secretKey: data.test?.secretKey || fallback.secret || '',
      webhookSecret: data.test?.webhookSecret || fallback.webhook_secret || '',
    },
    live: {
      publicKey: data.live?.publicKey || '',
      secretKey: data.live?.secretKey || '',
      webhookSecret: data.live?.webhookSecret || '',
    },
  };
}

function publicNombaConfig(config) {
  return {
    mode: config.mode,
    test: publicNombaKeySet(config.test),
    live: publicNombaKeySet(config.live),
  };
}

function publicNombaKeySet(keys) {
  return {
    publicKey: keys?.publicKey || '',
    secretKeyConfigured: Boolean(keys?.secretKey),
    secretKeyMasked: maskSecret(keys?.secretKey),
    webhookSecretConfigured: Boolean(keys?.webhookSecret),
    webhookSecretMasked: maskSecret(keys?.webhookSecret),
  };
}

function sanitizeNombaKeySet(keys) {
  const sanitized = {};
  if (!keys || typeof keys !== 'object') {
    return sanitized;
  }

  if (typeof keys.publicKey === 'string') {
    sanitized.publicKey = keys.publicKey.trim();
  }
  if (typeof keys.secretKey === 'string' && keys.secretKey.trim()) {
    sanitized.secretKey = keys.secretKey.trim();
  }
  if (typeof keys.webhookSecret === 'string' && keys.webhookSecret.trim()) {
    sanitized.webhookSecret = keys.webhookSecret.trim();
  }
  return sanitized;
}

async function calculateSaleQuote(db, tenantId, branchId, items, discount, options = {}) {
  const transaction = options.transaction || null;
  const normalizedItems = normalizeSaleItems(items);
  if (!normalizedItems.length) {
    throw httpError(400, 'Sale must include at least one valid item');
  }

  const saleItems = [];
  const stockUpdates = [];
  let subtotal = 0;

  for (const item of normalizedItems) {
    const productRef = db.doc(`tenants/${tenantId}/products/${item.productId}`);
    const productDoc = transaction
      ? await transaction.get(productRef)
      : await productRef.get();

    if (!productDoc.exists) {
      throw httpError(400, `Product not found: ${item.productId}`);
    }

    const product = productDoc.data();
    if (product.isActive === false) {
      throw httpError(400, `Product is inactive: ${product.name || item.productId}`);
    }

    const unitPrice = numberValue(product.sellingPrice);
    if (unitPrice < 0) {
      throw httpError(400, `Invalid product price: ${product.name || item.productId}`);
    }

    const inventoryQuery = db
      .collection(`tenants/${tenantId}/inventory`)
      .where('productId', '==', item.productId)
      .where('branchId', '==', branchId)
      .limit(1);
    const inventorySnapshot = transaction
      ? await transaction.get(inventoryQuery)
      : await inventoryQuery.get();

    if (inventorySnapshot.empty) {
      throw httpError(400, `Inventory not found for product: ${product.name || item.productId}`);
    }

    const inventoryDoc = inventorySnapshot.docs[0];
    const inventory = inventoryDoc.data();
    const available = integerValue(inventory.available);
    const quantity = integerValue(inventory.quantity);

    if (available < item.quantity || quantity < item.quantity) {
      throw httpError(400, `Insufficient stock for product: ${product.name || item.productId}`);
    }

    const productQuantity = integerValue(product.quantity);
    const nextProductQuantity = productQuantity >= item.quantity
      ? productQuantity - item.quantity
      : null;
    const lineTotal = roundMoney(unitPrice * item.quantity);
    subtotal = roundMoney(subtotal + lineTotal);

    saleItems.push({
      productId: item.productId,
      productName: product.name || item.productName || 'Item',
      unitPrice,
      quantity: item.quantity,
      discount: 0,
      total: lineTotal,
    });
    stockUpdates.push({
      inventoryRef: inventoryDoc.ref,
      productRef,
      nextQuantity: quantity - item.quantity,
      nextAvailable: available - item.quantity,
      nextProductQuantity,
    });
  }

  const normalizedDiscount = Math.max(0, numberValue(discount));
  const taxableAmount = Math.max(0, roundMoney(subtotal - normalizedDiscount));
  const tax = roundMoney(taxableAmount * 0.12);
  const total = roundMoney(taxableAmount + tax);

  return {
    items: saleItems,
    stockUpdates,
    subtotal,
    discount: normalizedDiscount,
    tax,
    total,
  };
}

function normalizeUserLookup(source) {
  const uid = typeof source.uid === 'string' ? source.uid.trim() : '';
  const email = typeof source.email === 'string' ? source.email.trim().toLowerCase() : '';
  return { uid, email };
}

function validateManagedClaims(role, tenantId) {
  const platformRoles = ['super_admin', 'support_admin', 'billing_admin'];
  const tenantRoles = [
    'business_owner',
    'branch_manager',
    'inventory_officer',
    'cashier',
    'sales_staff',
    'accountant',
  ];
  const allowedRoles = [...platformRoles, ...tenantRoles];

  if (!allowedRoles.includes(role)) {
    return 'Invalid role';
  }

  if (tenantRoles.includes(role) && !tenantId) {
    return 'Tenant roles require tenant_id';
  }

  if (platformRoles.includes(role) && tenantId) {
    return 'Platform admin roles must not include tenant_id';
  }

  return null;
}

function publicUserClaims(userRecord) {
  const claims = userRecord.customClaims || {};
  return {
    uid: userRecord.uid,
    email: userRecord.email || '',
    displayName: userRecord.displayName || '',
    disabled: userRecord.disabled === true,
    role: typeof claims.role === 'string' ? claims.role : '',
    tenantId: typeof claims.tenant_id === 'string'
      ? claims.tenant_id
      : typeof claims.tenantId === 'string'
        ? claims.tenantId
        : '',
  };
}

function maskSecret(secret) {
  if (!secret) {
    return '';
  }
  const suffix = secret.slice(-4);
  return `****${suffix}`;
}

function normalizeSaleItems(items) {
  return items
    .map((item) => ({
      productId: typeof item.productId === 'string' ? item.productId.trim() : '',
      productName: typeof item.productName === 'string' ? item.productName.trim() : '',
      quantity: integerValue(item.quantity),
    }))
    .filter((item) => item.productId && item.quantity > 0);
}

function integerValue(value) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) {
    return 0;
  }
  return Math.trunc(parsed);
}

function numberValue(value) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) {
    return 0;
  }
  return parsed;
}

function roundMoney(value) {
  return Math.round((Number(value) + Number.EPSILON) * 100) / 100;
}

function httpError(statusCode, publicMessage) {
  const error = new Error(publicMessage);
  error.statusCode = statusCode;
  error.publicMessage = publicMessage;
  return error;
}

async function sendReceiptEmail(email, saleId, tenantId, payload) {
  const config = functions.config();
  const mailConfig = config?.mail;
  if (!mailConfig || !mailConfig.smtp_host || !mailConfig.smtp_user || !mailConfig.smtp_pass) {
    throw new Error('SMTP config missing');
  }

  const transporter = nodemailer.createTransport({
    host: mailConfig.smtp_host,
    port: parseInt(mailConfig.smtp_port || '587', 10),
    secure: mailConfig.smtp_secure === 'true',
    auth: {
      user: mailConfig.smtp_user,
      pass: mailConfig.smtp_pass,
    },
  });

  const pdfBuffer = await buildReceiptPdf(payload);
  const mailOptions = {
    from: mailConfig.smtp_from || mailConfig.smtp_user,
    to: email,
    subject: `Receipt for Sale ${saleId}`,
    text: `Thank you for your purchase. Your receipt is attached for sale ${saleId}.`,
    attachments: [
      {
        filename: `receipt-${saleId}.pdf`,
        content: pdfBuffer,
      },
    ],
  };

  await transporter.sendMail(mailOptions);
}

function buildReceiptPdf(payload) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ size: 'A4', margin: 40 });
    const chunks = [];
    doc.on('data', (chunk) => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);

    doc.fontSize(20).text('TeamCloud Retail POS', { underline: true });
    doc.moveDown();
    doc.fontSize(12).text(`Sale: ${payload.saleId}`);
    doc.text(`Tenant: ${payload.tenantId}`);
    doc.text(`Branch: ${payload.branchId}`);
    if (payload.customerEmail) {
      doc.text(`Customer: ${payload.customerEmail}`);
    }
    doc.text(`Payment Method: ${payload.paymentMethod}`);
    doc.text(`Status: ${payload.status}`);
    doc.text(`Date: ${payload.createdAt ? new Date(payload.createdAt._seconds * 1000).toISOString() : ''}`);
    doc.moveDown();

    doc.fontSize(14).text('Items');
    doc.moveDown(0.5);
    doc.fontSize(10);
    doc.text('Item | Qty | Unit Price | Total');
    doc.moveDown(0.2);
    if (Array.isArray(payload.items)) {
      payload.items.forEach((item) => {
        doc.text(`${item.productName || item.name || 'Item'} | ${item.quantity || item.qty || 0} | ${item.unitPrice || item.price || 0} | ${item.total || 0}`);
      });
    }
    doc.moveDown();
    doc.text(`Subtotal: ${payload.subtotal || 0}`);
    doc.text(`Tax: ${payload.tax || 0}`);
    doc.text(`Total: ${payload.total || 0}`);
    doc.moveDown();
    doc.text('Thank you for your purchase!', { italics: true });

    doc.end();
  });
}

exports.api = functions.https.onRequest(app);
