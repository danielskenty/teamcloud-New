# TeamCloud Retail POS Implementation Tracker

Status legend:

- `[ ]` Not started
- `[~]` In progress
- `[x]` Done
- `[!]` Blocked or needs external setup

## Foundation And Build Health

- `[x]` Fix Firebase startup order so auth/router providers are only created after Firebase initializes.
- `[x]` Replace placeholder `lib/firebase_options.dart` values with real Firebase project/app config.
- `[x]` Make widget tests deterministic with Firebase/auth provider overrides.
- `[x]` Add Cloud Functions test script and syntax smoke check.
- `[x]` Remove or consolidate duplicate/unused router provider files.
- `[x]` Add CI commands for `flutter analyze`, `flutter test`, and Functions tests.

## Authentication, Tenancy, And Roles

- `[x]` Implement tenant-aware auth session model from Firebase custom claims.
- `[x]` Replace all hardcoded `demoTenant` usage with authenticated tenant context.
- `[x]` Gate `/admin` to TeamCloud platform admin roles only.
- `[x]` Gate tenant routes by tenant roles and permissions.
- `[ ]` Add user onboarding/bootstrap flow for tenant users.
- `[x]` Add custom claims setup/admin tooling for `tenant_id` and `role`.
- `[x]` Google Sign-In intentionally skipped for now; email/password remains the supported auth path.

## Firebase And Security

- `[~]` Validate Firestore rules against the app data model and custom claims.
- `[ ]` Add Realtime Database rules for carts, cashier sessions, device status, stock updates, held sales, notifications, and sync.
- `[ ]` Tighten Storage rules by tenant, file type, size, and role where needed.
- `[~]` Add audit log writes for sensitive actions.
- `[ ]` Add device authorization and session management.

## Server-Side POS And Payments

- `[x]` Move final sale processing to Cloud Functions.
- `[x]` Recalculate totals, discounts, tax, sale amounts, and Nomba payment amounts server-side.
- `[x]` Deduct inventory in a Firestore transaction during sale finalization.
- `[ ]` Add support for hold/resume sales in Realtime Database.
- `[ ]` Add multiple, split, and partial payments.
- `[ ]` Add refunds and exchanges.
- `[ ]` Replace mock/default cash payment handling with explicit production flow.
- `[x]` Wire Nomba payment endpoint to the deployed Cloud Function URL.
- `[x]` Allow Super Admin to manage Nomba test/live public keys, secret keys, webhook secrets, and active mode.
- `[x]` Fix webhook raw-body signature verification.
- `[ ]` Generate and persist receipts server-side.
- `[ ]` Add receipt printing, email receipts, and WhatsApp receipt workflows.

## Core Modules

- `[ ]` Dashboard: revenue summary, sales summary, inventory summary, top products, recent transactions, branch performance.
- `[ ]` POS: search, barcode/QR scanning, cart management, hold/resume, payments, discounts, refunds, exchanges, receipts.
- `[ ]` Products: categories, brands, variants, SKU/barcode generation, images, serial/warranty tracking.
- `[ ]` Inventory: receiving, adjustments, counts, transfers, damage, expiry, batches, reorder/low-stock alerts.
- `[ ]` Branches: unlimited branches, branch inventory, sales, transfers, reporting.
- `[ ]` Suppliers: suppliers, purchase orders, receiving, payments, ledger, returns.
- `[ ]` Customers: profiles, groups, loyalty, wallet, purchase history, statements.
- `[ ]` Credit Sales: credit sales, installments, reminders, debt tracking, collection reports.
- `[ ]` Accounting: income, expenses, cashbook, P&L, balance sheet, cash flow, VAT reports.
- `[ ]` Staff: accounts, permissions, attendance, shifts, activity logs.
- `[ ]` Promotions: discounts, coupons, loyalty rewards, referral rewards.
- `[ ]` Reports: sales, product, inventory, profit, customer, supplier, branch reports.
- `[ ]` Notifications: push, email, SMS, WhatsApp channels.
- `[ ]` SaaS Billing: trials, monthly/annual plans, upgrades, downgrades, subscriptions, invoices.

## UI And Product Quality

- `[ ]` Apply consistent Material 3 responsive layout across web, tablet, and mobile.
- `[ ]` Replace scaffold placeholder screens with production workflows.
- `[ ]` Add navigation shell/sidebar appropriate for tenant/admin portals.
- `[ ]` Verify brand colors `#0F52BA` and `#FFC107` across theme.
- `[ ]` Add loading, empty, error, and permission-denied states for all screens.
- `[ ]` Add mobile-first POS layout and desktop-optimized management layout.

## Current Verification

- `[x]` `flutter analyze` passes as of current review.
- `[x]` `flutter test` passes after Firebase/auth startup testability fix.
- `[x]` `npm test` in `functions/` passes with `node --check index.js`.
- `[x]` Cloud Functions deployed to `https://us-central1-teamcloud-94b3a.cloudfunctions.net/api`.
- `[x]` Firestore rules deployed to project `teamcloud-94b3a`.
- `[x]` Initial Super Admin claim bootstrapped for `danielskenty@gmail.com`.
