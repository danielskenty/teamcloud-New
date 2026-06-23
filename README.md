# TeamCloud Retail POS

A comprehensive Flutter-based multi-tenant SaaS Retail Point-of-Sale (POS) application built with Firebase.

## Features

- **Multi-Tenant Architecture**: Support for multiple independent retail businesses
- **Role-Based Access Control**: 7 different user roles with granular permissions
- **Firebase Integration**: Real-time database, authentication, cloud storage, and messaging
- **Product Management**: Complete product catalog with categories and brands
- **Inventory Tracking**: Real-time inventory management with low-stock alerts
- **Sales Processing**: POS transaction handling with customer loyalty points
- **Customer Management**: Customer profiles with purchase history and loyalty tracking
- **Branch Management**: Multi-branch support with independent operations
- **Cross-Platform**: Support for iOS, Android, Web, and Desktop (via Flutter)

## Tech Stack

- **Framework**: Flutter 3.38.5
- **Language**: Dart 3.10.4
- **State Management**: Flutter Riverpod
- **Routing**: GoRouter
- **Backend**: Firebase (Firestore, Authentication, Storage, Messaging)
- **Architecture**: Feature-based folder structure with Repository pattern

## Project Structure

```
lib/
├── main.dart              # App entrypoint
├── app.dart              # App configuration
├── firebase_options.dart # Firebase configuration
└── src/
    ├── core/             # Shared utilities, constants, routes, theme
    │   ├── constants/
    │   ├── providers/    # Firebase providers
    │   ├── routes/       # GoRouter configuration
    │   └── theme/        # App theme and styling
    └── features/         # Feature modules
        ├── auth/         # Authentication
        ├── dashboard/    # Tenant dashboard
        ├── branches/     # Branch management
        ├── products/     # Product catalog
        ├── inventory/    # Stock management
        ├── sales/        # POS transactions
        └── customers/    # Customer management
```

## Setup Instructions

### Prerequisites

- Flutter 3.38.5 or later
- Firebase project (create at [console.firebase.google.com](https://console.firebase.google.com))
- Firebase CLI

### 1. Firebase Configuration

1. Create a Firebase project for `teamcloud-94b3a`
2. Enable the following services:
   - Authentication (Email/Password)
   - Firestore Database
   - Storage
   - Cloud Messaging
3. Download credentials for each platform and update `lib/firebase_options.dart`

### 2. Custom Claims Setup

Custom claims are required for role-based access control. Follow the guide in [CUSTOM_CLAIMS_SETUP.md](CUSTOM_CLAIMS_SETUP.md) to:
- Set up a Cloud Function for managing custom claims
- Configure automatic claims assignment on user creation

### 3. Firebase Security Rules

Deploy the Firestore and Storage security rules:

```bash
firebase deploy --only firestore:rules,storage:rules
```

Rules are defined in:
- `firestore.rules` - Firestore access control
- `storage.rules` - Storage bucket access control

### 4. Running the App

```bash
# Get dependencies
flutter pub get

# Run on your device/emulator
flutter run

# Or specify a device
flutter run -d <device-id>
```

## User Roles

- **Super Admin**: Full system access across all tenants
- **Business Owner**: Complete control of assigned tenant
- **Branch Manager**: Manage branch operations and staff
- **Inventory Officer**: Handle stock management
- **Cashier**: Process sales transactions
- **Sales Staff**: View products and assist customers
- **Accountant**: Financial reports and analysis

## Development

### Code Analysis

```bash
flutter analyze
```

### Testing

```bash
flutter test
```

### Building for Production

```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release

# Web
flutter build web --release
```

## Security Considerations

- All data access is controlled by Firestore security rules
- User roles are enforced via custom claims in Firebase Authentication
- Tenant isolation is enforced at the database level
- Storage access is scoped to tenant folders

## Documentation

- [Custom Claims Setup](CUSTOM_CLAIMS_SETUP.md) - Role-based access control configuration
- [Firestore Rules](firestore.rules) - Database security rules
- [Storage Rules](storage.rules) - Cloud Storage security rules

## Contributing

See the project structure above for feature organization. Each feature should:
1. Have its own folder under `lib/src/features/`
2. Include models, repositories, providers, and views
3. Follow the established patterns (Provider-based state management, Repository pattern)

## License

Proprietary - TeamCloud Inc.

## Support

For issues and questions, contact the development team.
