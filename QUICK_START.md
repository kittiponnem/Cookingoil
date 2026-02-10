# Quick Start Guide - Oil Manager

## Overview

Oil Manager is an enterprise-grade Flutter application for managing cooking oil orders, UCO pickups, fleet operations, and D365 F&O integration.

## Prerequisites

- Flutter 3.35.4 or compatible version
- Dart 3.9.2
- Android Studio or VS Code with Flutter extensions
- Firebase account
- Google Maps API key

## Project Setup (5 Minutes)

### 1. Clone and Install Dependencies

```bash
cd /home/user/flutter_app
flutter pub get
```

### 2. Configure Firebase

#### Create Firebase Project
1. Go to https://console.firebase.google.com/
2. Click "Add Project"
3. Follow the setup wizard

#### Enable Required Services
- Authentication (Email/Password + Phone)
- Cloud Firestore
- Cloud Storage

#### Download Configuration Files
- **Android**: Download `google-services.json` → Place in `android/app/`
- **Web**: Copy web configuration values

#### Update main.dart
Edit `lib/main.dart` and replace Firebase configuration:

```dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  ),
);
```

### 3. Set Up Firestore Database

Follow the detailed guide in `FIRESTORE_SETUP.md`:

1. Create Firestore database
2. Create 10 required collections
3. Set up composite indexes
4. Deploy security rules

**Quick Setup Command** (if using Firebase CLI):
```bash
firebase init firestore
firebase deploy --only firestore:rules,firestore:indexes
```

### 4. Configure Google Maps (Optional for MVP)

1. Get API key from Google Cloud Console
2. Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

### 5. Update API Base URL

Edit `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'https://YOUR_MIDDLEWARE_API_URL/api';
```

For development, you can use a mock API or placeholder.

## Running the Application

### Web Preview (Fastest)
```bash
cd /home/user/flutter_app
flutter run -d chrome
```

### Android Debug Build
```bash
flutter run
```

### Android Release Build
```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

## Test User Accounts

### Create Test Users via Firebase Console

Navigate to Authentication → Users → Add User

#### Customer B2C User
```
Email: customer@test.com
Password: Test123456
```

Then add to Firestore `users` collection:
```json
{
  "uid": "firebase_uid_here",
  "role": "customer_b2c",
  "displayName": "Test Customer",
  "phone": "+1234567890",
  "email": "customer@test.com",
  "customerAccountId": "CUST001",
  "branchIds": [],
  "isActive": true,
  "createdAt": "2024-01-01T00:00:00Z"
}
```

#### Driver User
```json
{
  "uid": "driver_uid_here",
  "role": "driver",
  "displayName": "Test Driver",
  "phone": "+1234567891",
  "email": "driver@test.com",
  "customerAccountId": null,
  "branchIds": [],
  "isActive": true,
  "createdAt": "2024-01-01T00:00:00Z"
}
```

#### Dispatcher User
```json
{
  "uid": "dispatcher_uid_here",
  "role": "dispatcher",
  "displayName": "Test Dispatcher",
  "phone": "+1234567892",
  "email": "dispatcher@test.com",
  "customerAccountId": null,
  "branchIds": [],
  "isActive": true,
  "createdAt": "2024-01-01T00:00:00Z"
}
```

## Testing the Application

### 1. Authentication Flow
1. Open app → Login screen appears
2. Toggle between Phone OTP and Email login
3. For Email: Use test credentials
4. App should route to appropriate dashboard based on role

### 2. Customer Flow
1. Login as customer
2. View home dashboard
3. Navigate to Catalog tab
4. Navigate to Orders tab
5. Navigate to UCO Pickup tab

### 3. Driver Flow
1. Login as driver
2. View today's jobs
3. Check job list
4. (Jobs would appear if created via Firestore)

### 4. Dispatcher Flow
1. Login as dispatcher
2. View dashboard stats
3. Navigate to Deliveries tab
4. Navigate to Live Map tab

## Project Structure Quick Reference

```
lib/
├── main.dart                          # App entry point
├── models/                            # Data models (10 files)
│   ├── user_model.dart
│   ├── product_model.dart
│   ├── sales_order_model.dart
│   ├── pickup_request_model.dart
│   └── job_model.dart
├── providers/                         # State management
│   ├── auth_provider.dart             # Auth + routing
│   └── cart_provider.dart             # Shopping cart
├── services/                          # API & Firebase
│   ├── api_service.dart               # HTTP client
│   ├── firestore_service.dart         # Firestore ops
│   └── *_api_service.dart             # API endpoints
├── screens/                           # UI screens
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── customer/customer_home_screen.dart
│   ├── driver/driver_home_screen.dart
│   └── dispatcher/dispatcher_home_screen.dart
└── widgets/                           # Reusable components
    └── status_timeline.dart
```

## Common Development Tasks

### Add New Screen
1. Create screen file in appropriate directory
2. Add route to `main.dart`
3. Navigate using `Navigator.pushNamed(context, '/route')`

### Add New API Endpoint
1. Add method to appropriate `*_api_service.dart`
2. Use `ApiService.get()` or `.post()` methods
3. Handle response in UI layer

### Add New Firestore Query
1. Add method to `firestore_service.dart`
2. Use existing collection references
3. Map to model using `.fromFirestore()`

### Update Data Model
1. Modify model in `models/` directory
2. Update `fromFirestore()` and `toFirestore()` methods
3. Run `flutter pub get` if adding new dependencies

## Troubleshooting

### "No Firebase App '[DEFAULT]' has been created"
**Solution**: Check that `Firebase.initializeApp()` is called in `main()` before `runApp()`

### "Missing or insufficient permissions"
**Solution**: Check Firestore security rules and ensure user has correct role claim

### "Failed to resolve dependencies"
**Solution**: Run `flutter pub get` and check `pubspec.yaml` for version conflicts

### Build Errors
**Solution**: Clean and rebuild:
```bash
flutter clean
flutter pub get
flutter run
```

### API Calls Failing
**Solution**: Check that API base URL is correctly configured and middleware is running

## Development Workflow

### 1. Feature Development
```bash
# Create feature branch
git checkout -b feature/my-feature

# Make changes
# Test locally

# Commit
git add .
git commit -m "Add: my feature description"

# Push
git push origin feature/my-feature
```

### 2. Testing
```bash
# Run tests
flutter test

# Run specific test
flutter test test/auth_provider_test.dart

# Check code quality
flutter analyze
```

### 3. Code Formatting
```bash
# Format all Dart files
dart format .

# Format specific file
dart format lib/main.dart
```

## Next Steps

### Immediate (MVP)
1. ✅ Basic authentication working
2. ✅ Role-based navigation implemented
3. ✅ Firestore integration complete
4. 🔲 Connect to real middleware API
5. 🔲 Implement product catalog UI
6. 🔲 Build order creation flow
7. 🔲 Add photo capture for pickups

### Short Term (Phase 2)
1. Driver job execution screens
2. Proof of delivery capture
3. Offline job queue
4. Push notifications
5. Real-time driver tracking

### Long Term (Phase 3+)
1. B2B branch management
2. Advanced reporting
3. Route optimization
4. Payment integration
5. Multi-language support

## Getting Help

### Documentation
- `README.md` - Full project documentation
- `FIRESTORE_SETUP.md` - Database setup guide
- `API_IMPLEMENTATION_GUIDE.md` - Backend API specs

### Resources
- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Provider Documentation](https://pub.dev/packages/provider)

### Support Channels
- Internal: Slack #oil-manager-dev
- Technical Issues: Create GitHub issue
- Firebase Issues: Firebase Console → Support

## Performance Tips

### Optimize Firestore Queries
```dart
// ✅ Good - Uses index
collection.where('status', isEqualTo: 'Pending')

// ❌ Bad - Requires composite index
collection
  .where('status', isEqualTo: 'Pending')
  .orderBy('createdAt', descending: true)
```

### Reduce API Calls
- Cache product catalog locally (Hive)
- Use Firestore offline persistence
- Batch updates when possible

### Optimize Build Size
```bash
# Build with code splitting
flutter build apk --release --split-per-abi

# Results in smaller APKs:
# app-armeabi-v7a-release.apk
# app-arm64-v8a-release.apk
# app-x86_64-release.apk
```

## Security Checklist

- [ ] API base URL uses HTTPS
- [ ] Firebase security rules deployed
- [ ] Sensitive data not logged
- [ ] Test accounts removed before production
- [ ] API keys not committed to git
- [ ] User passwords hashed (handled by Firebase)

## Deployment Checklist

### Pre-Deployment
- [ ] All tests passing
- [ ] No `flutter analyze` errors
- [ ] Firebase production project configured
- [ ] API pointing to production endpoint
- [ ] Google Maps API key configured
- [ ] Version number updated in `pubspec.yaml`

### Production Build
```bash
flutter build apk --release --split-per-abi
flutter build appbundle --release
```

### Post-Deployment
- [ ] Test on real devices
- [ ] Monitor Firebase Analytics
- [ ] Check Crashlytics for errors
- [ ] Review API performance metrics

## Useful Commands Cheat Sheet

```bash
# Project
flutter create my_app              # Create new project
flutter pub get                    # Install dependencies
flutter pub upgrade                # Upgrade dependencies
flutter clean                      # Clean build

# Development
flutter run                        # Run debug
flutter run -d chrome              # Run on web
flutter run --release              # Run release mode
flutter devices                    # List devices

# Testing
flutter test                       # Run all tests
flutter test --coverage            # With coverage
flutter analyze                    # Static analysis

# Building
flutter build apk --release        # Android APK
flutter build appbundle            # Android App Bundle
flutter build web                  # Web build

# Code Quality
dart format .                      # Format code
dart fix --apply                   # Apply fixes
flutter pub outdated               # Check outdated deps

# Firebase
firebase init                      # Initialize Firebase
firebase deploy                    # Deploy rules/indexes
firebase emulators:start           # Local emulators
```

## License

Enterprise Application - Internal Use Only

---

**Ready to Start?** Follow the setup steps above and you'll have the app running in 15 minutes!

For detailed documentation, see `README.md` and other guide files in the project root.
