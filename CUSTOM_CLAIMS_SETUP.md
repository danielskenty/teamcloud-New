# Firebase Custom Claims Setup

## Overview

The TeamCloud Retail POS app uses Firebase Authentication with custom claims to enforce role-based access control (RBAC) across a multi-tenant architecture. Custom claims are set on user tokens by a backend service (Cloud Functions) and are used in Firestore security rules to control data access.

## Custom Claims Structure

Each user token includes the following custom claims:

```json
{
  "tenant_id": "tenant-uuid",
  "role": "business_owner|branch_manager|inventory_officer|cashier|sales_staff|accountant|super_admin"
}
```

### Roles and Permissions

- **super_admin**: Full access across all tenants
- **business_owner**: Full access to assigned tenant
- **branch_manager**: Manage branch operations, products, and staff
- **inventory_officer**: Manage inventory and stock levels
- **cashier**: Process sales and customer transactions
- **sales_staff**: View products and create orders (if POS supports)
- **accountant**: Manage expenses, purchases, and financial reports

## Setting Custom Claims via Cloud Function

The custom claims must be set using the Firebase Admin SDK, typically in a Cloud Function triggered during user creation or role assignment.

### Example Cloud Function (Node.js)

Create a file `functions/src/setCustomClaims.ts`:

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

export const setUserCustomClaims = functions.firestore
  .document('tenants/{tenantId}/users/{userId}')
  .onCreate(async (snap, context) => {
    const userData = snap.data();
    const { userId } = context.params;

    const customClaims = {
      tenant_id: context.params.tenantId,
      role: userData.role || 'sales_staff',
    };

    try {
      await admin.auth().setCustomUserClaims(userId, customClaims);
      console.log(`Custom claims set for user ${userId}`);
    } catch (error) {
      console.error(`Error setting custom claims: ${error}`);
    }
  });

export const updateUserRole = functions.https.onCall(
  async (data, context) => {
    // Verify that the user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated',
      );
    }

    const { userId, role, tenantId } = data;

    // Verify the user has permission to update roles
    const customClaims = context.auth.token as Record<string, unknown>;
    const userRole = customClaims.role as string;
    const userTenantId = customClaims.tenant_id as string;

    if (userRole !== 'business_owner' && userRole !== 'super_admin') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only business owners can update roles',
      );
    }

    if (userRole !== 'super_admin' && userTenantId !== tenantId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'You can only update roles within your tenant',
      );
    }

    try {
      await admin.auth().setCustomUserClaims(userId, {
        tenant_id: tenantId,
        role: role,
      });
      return { success: true };
    } catch (error) {
      throw new functions.https.HttpsError('internal', (error as Error).message);
    }
  },
);
```

### Setup Steps

1. Initialize Firebase Functions in your project:
   ```bash
   firebase init functions
   ```

2. Install Admin SDK:
   ```bash
   cd functions
   npm install firebase-admin
   ```

3. Deploy the function:
   ```bash
   firebase deploy --only functions
   ```

## Retrieving Custom Claims in the Flutter App

Custom claims are automatically included in the user's ID token. Here's how to access them:

```dart
import 'package:firebase_auth/firebase_auth.dart';

Future<Map<String, dynamic>?> getUserCustomClaims() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final tokenResult = await user.getIdTokenResult(true);
  return tokenResult.claims;
}

// Usage
final claims = await getUserCustomClaims();
final tenantId = claims?['tenant_id'] as String?;
final role = claims?['role'] as String?;
```

## Firestore Security Rules with Custom Claims

The Firestore security rules use these custom claims to enforce access control:

```javascript
function hasTenantRole(tenantId, roles) {
  return hasTenantAccess(tenantId) && request.auth.token.role in roles;
}
```

See `firestore.rules` for the complete rule set.

## Important Considerations

1. **Token Refresh**: Custom claims are cached in the ID token. For changes to take effect immediately, call:
   ```dart
   await FirebaseAuth.instance.currentUser?.getIdTokenResult(true);
   ```

2. **Development**: For testing without a Cloud Function, you can manually set custom claims via Firebase Console → Authentication → Users → Custom Claims.

3. **Security**: Always validate roles in both Firestore rules and Cloud Functions to prevent privilege escalation.

4. **Audit Logs**: Consider logging all role changes to the `auditLogs` collection for compliance.

## Troubleshooting

- **Claims not appearing in token**: Wait a few moments and refresh the token with `getIdTokenResult(true)`.
- **Permission denied errors**: Check that custom claims are set correctly and the Firestore rules match your claim structure.
- **Cloud Function errors**: Check the Cloud Functions logs in the Firebase Console.
