# Nomba Integration Guide

TeamCloud Retail POS uses Firebase Cloud Functions for Nomba payments. Nomba secret keys are managed by Super Admins in the app and are never embedded in the Flutter client.

## Backend URL

Default API URL:

```text
https://us-central1-teamcloud-94b3a.cloudfunctions.net/api
```

Local or staging builds can override this with:

```sh
flutter run --dart-define=TEAMCLOUD_FUNCTIONS_URL=<api-url>
```

## Deploy

Deploy the Firebase Function API:

```sh
firebase deploy --only functions
```

`firebase.json` points Functions deploys at the `functions/` directory.

## Super Admin Key Management

1. Sign in with a Firebase user whose custom claim has `role: super_admin`.
2. Open `/admin`.
3. Use the Nomba payment keys panel to manage:
   - Test public key
   - Test secret key
   - Test webhook secret
   - Live public key
   - Live secret key
   - Live webhook secret
   - Active mode: `test` or `live`

The backend stores these values under `platformSettings/nomba`. Secret values are masked when returned to the client. Leaving a secret field blank keeps the existing saved secret.

## Payment Flow

1. Flutter checkout calls `/create-payment`.
2. The Cloud Function verifies Firebase Auth and tenant ownership.
3. The Cloud Function reads the active Nomba key set and calls Nomba server-side.
4. Flutter checkout calls `/finalize-sale`.
5. The Cloud Function recalculates totals from Firestore products, deducts inventory in a transaction, creates the sale, and writes an audit log.

## Webhook

Configure Nomba webhooks to notify:

```text
https://us-central1-teamcloud-94b3a.cloudfunctions.net/api/webhook
```

The webhook verifies the signature against the active stored webhook secret, plus stored test/live webhook secrets, with legacy Functions config as fallback.

## Security Notes

- Do not put Nomba secret keys in Flutter code.
- Only `super_admin` can read or update Nomba key configuration.
- Tenant users can only create payments for their own tenant.
- Clients cannot create or update sale documents directly; final sale writes are server-side.
