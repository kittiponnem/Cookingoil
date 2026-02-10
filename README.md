# Oil Manager - Enterprise Cooking Oil Management System

## Project Overview

Oil Manager is an enterprise-grade FlutterFlow-inspired application for managing a nationwide cooking oil business with B2C and B2B customer support, fleet management, and Microsoft Dynamics 365 Finance & Operations (D365 F&O) integration.

## Features

### Multi-Role Architecture
- **Customer B2C**: Individual customers ordering cooking oil and requesting UCO pickups
- **Customer B2B User**: Business account users placing orders
- **Customer B2B Admin**: Business account administrators managing branches and users
- **Driver**: Field personnel executing deliveries and pickups with proof capture
- **Dispatcher**: Operations team managing job assignments and fleet coordination
- **Admin**: System administrators with full access

### Core Functionality

#### For Customers
- Browse product catalog with pricing
- Add products to cart and checkout
- Schedule delivery time windows
- Track order status with timeline
- Request UCO (Used Cooking Oil) pickup with photos
- Choose incentive types (Cash/Credit Note/Points)
- Manage delivery addresses
- View invoices and documents

#### For Drivers
- View assigned jobs for the day
- Navigate to delivery/pickup locations
- Update job status (En Route, Arrived, Completed)
- Capture proof of delivery (photos + signature)
- Capture pickup proof with quality assessment
- Offline-safe job completion with sync queue
- Track completed jobs history

#### For Dispatchers
- View pending orders and pickup requests
- Assign jobs to drivers with vehicles and schedules
- Monitor live driver locations on map
- Handle exceptions and reschedule jobs
- View real-time job status updates
- Manage fleet resources

#### For Admins
- Configure service areas and business rules
- Manage user accounts and permissions
- View audit trails and job events
- Configure minimum pickup quantities and incentives

## Technical Architecture

### Backend Integration
- **System of Record**: Microsoft Dynamics 365 Finance & Operations (D365 F&O)
- **Middleware API**: Azure Functions / .NET Web API (placeholder endpoints defined)
- **Real-time Data**: Firebase Firestore for offline-first mobile experience
- **File Storage**: Firebase Storage for photos, signatures, and documents

### Data Layer - Firestore Collections

#### 1. users
```
uid: string (document ID)
role: string (enum)
displayName: string
phone: string
email: string
customerAccountId: string (nullable)
branchIds: array<string>
isActive: boolean
createdAt: timestamp
```

#### 2. customer_branches
```
branchId: string (document ID)
customerAccountId: string
branchName: string
addresses: array<map>
  - label: string
  - addressText: string
  - lat: number
  - lng: number
  - notes: string
defaultAddress: map (nullable)
createdAt: timestamp
```

#### 3. products_cache
```
sku: string (document ID)
name: string
uom: string
packSize: string
imageUrl: string (nullable)
category: string
isActive: boolean
updatedAt: timestamp
```

#### 4. sales_orders
```
orderId: string (document ID)
orderNumber: string (from D365)
customerType: string (B2B/B2C)
customerAccountId: string
branchId: string (nullable)
deliveryAddress: map
  - text: string
  - lat: number
  - lng: number
  - notes: string
preferredWindowStart: timestamp
preferredWindowEnd: timestamp
status: string (enum)
totalAmount: number
currency: string
paymentMethod: string (enum)
createdByUid: string
createdAt: timestamp
lastStatusAt: timestamp
```

#### 5. sales_order_lines
```
orderId: string
sku: string
qty: number
unitPrice: number
lineTotal: number
```

#### 6. pickup_requests
```
pickupId: string (document ID)
customerType: string (B2B/B2C)
customerAccountId: string
branchId: string (nullable)
pickupAddress: map
estimatedQty: number
estimatedUom: string
containerType: string
photos: array<string>
preferredWindowStart: timestamp
preferredWindowEnd: timestamp
incentiveType: string (enum)
status: string (enum)
qualityFlags: map
  - water: boolean
  - solid: boolean
  - odor: boolean
  - otherNotes: string
createdByUid: string
createdAt: timestamp
lastStatusAt: timestamp
```

#### 7. jobs
```
jobId: string (document ID)
jobType: string (Delivery/Pickup)
refId: string (orderId or pickupId)
stopSequence: number
assignedDriverUid: string
assignedVehicleId: string
scheduledDate: date
windowStart: timestamp
windowEnd: timestamp
status: string (enum)
dispatcherUid: string
createdAt: timestamp
```

#### 8. job_events
```
jobId: string
eventType: string (enum)
statusFrom: string (nullable)
statusTo: string (nullable)
note: string (nullable)
photoUrls: array<string>
signatureUrl: string (nullable)
actualQty: number (nullable)
actualUom: string (nullable)
lat: number (nullable)
lng: number (nullable)
createdByUid: string
createdAt: timestamp
```

#### 9. documents
```
refType: string (Order/Pickup)
refId: string
docType: string (Invoice/CreditNote/POD/PickupReceipt)
docUrl: string
createdAt: timestamp
```

#### 10. driver_locations
```
driverUid: string (document ID)
lat: number
lng: number
speed: number (nullable)
heading: number (nullable)
updatedAt: timestamp
```

### Required Firestore Indexes

Create composite indexes for optimal query performance:

1. **sales_orders**
   - Fields: `customerAccountId` (Ascending), `createdAt` (Descending)
   - Fields: `status` (Ascending), `createdAt` (Descending)

2. **pickup_requests**
   - Fields: `customerAccountId` (Ascending), `createdAt` (Descending)
   - Fields: `status` (Ascending), `createdAt` (Descending)

3. **jobs**
   - Fields: `assignedDriverUid` (Ascending), `scheduledDate` (Ascending)
   - Fields: `status` (Ascending), `scheduledDate` (Ascending)

4. **job_events**
   - Fields: `jobId` (Ascending), `createdAt` (Ascending)

## API Contract

### Middleware API Endpoints (Placeholder)

All API calls must include Authorization header with Bearer token.

#### Auth API
- `POST /auth/login` - Email/password login
- `POST /auth/login/send-otp` - Send OTP to phone
- `POST /auth/login/verify-otp` - Verify OTP

#### Catalog API
- `GET /catalog/products?customerId={id}` - Get products catalog
- `GET /catalog/products/{sku}` - Get product by SKU
- `GET /catalog/products/{sku}/pricing` - Get product pricing

#### Orders API
- `POST /orders` - Create sales order
- `GET /orders/{id}` - Get order by ID
- `GET /orders?customerId={id}&status={status}` - Get customer orders
- `PUT /orders/{id}/status` - Update order status
- `POST /orders/{id}/cancel` - Cancel order

#### Pickup API
- `POST /pickups` - Create pickup request
- `GET /pickups/{id}` - Get pickup by ID
- `GET /pickups?customerId={id}&status={status}` - Get customer pickups
- `PUT /pickups/{id}/status` - Update pickup status
- `POST /pickups/{id}/quality` - Submit quality assessment

#### Dispatch API
- `POST /dispatch/jobs` - Create job
- `POST /dispatch/jobs/{id}/assign` - Assign job to driver
- `POST /dispatch/jobs/{id}/status` - Update job status
- `POST /dispatch/jobs/{id}/complete` - Complete job with proof
- `GET /dispatch/jobs?driverUid={id}&status={status}&date={date}` - Get jobs

#### Documents API
- `GET /documents?refType={type}&refId={id}` - Get documents

## Installation and Setup

### Prerequisites
- Flutter 3.35.4 (Dart 3.9.2)
- Firebase project with Firestore and Storage enabled
- Google Maps API key for location features

### Dependencies
All dependencies are pre-configured in `pubspec.yaml`:
- Firebase Core & Services (cloud_firestore, firebase_auth, firebase_storage)
- Provider for state management
- Hive & shared_preferences for offline storage
- Google Maps Flutter for location features
- Image picker & signature capture for proof collection

### Firebase Configuration

1. **Create Firebase Project** at https://console.firebase.google.com/
2. **Enable Services**:
   - Authentication (Email/Password + Phone)
   - Cloud Firestore
   - Storage
3. **Download Configuration**:
   - `google-services.json` for Android → `android/app/`
   - Web configuration → Update `main.dart` FirebaseOptions
4. **Create Firestore Collections** (see schema above)
5. **Set Security Rules**:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - users can read/write own document
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Orders - customers can read/write own orders
    match /sales_orders/{orderId} {
      allow read: if request.auth != null && 
        (resource.data.customerAccountId == request.auth.token.customerAccountId ||
         request.auth.token.role in ['dispatcher', 'admin']);
      allow create: if request.auth != null;
    }
    
    // Jobs - drivers can read assigned jobs, dispatchers can manage
    match /jobs/{jobId} {
      allow read: if request.auth != null &&
        (resource.data.assignedDriverUid == request.auth.uid ||
         request.auth.token.role in ['dispatcher', 'admin']);
      allow write: if request.auth.token.role in ['dispatcher', 'admin'];
    }
    
    // Products cache - read only for all authenticated users
    match /products_cache/{productId} {
      allow read: if request.auth != null;
      allow write: if request.auth.token.role == 'admin';
    }
  }
}
```

### Running the Application

1. **Install Dependencies**:
```bash
cd /home/user/flutter_app
flutter pub get
```

2. **Configure Firebase**:
   - Update `lib/main.dart` with your Firebase configuration
   - Add `google-services.json` to `android/app/`

3. **Update API Base URL**:
   - Edit `lib/services/api_service.dart`
   - Replace placeholder URL with your middleware API endpoint

4. **Run on Web** (for testing):
```bash
flutter run -d chrome
```

5. **Build for Android**:
```bash
flutter build apk --release
```

## Project Structure

```
lib/
├── main.dart                      # App entry point with multi-provider setup
├── models/                        # Data models
│   ├── user_model.dart
│   ├── customer_branch_model.dart
│   ├── product_model.dart
│   ├── sales_order_model.dart
│   ├── pickup_request_model.dart
│   └── job_model.dart
├── providers/                     # State management
│   ├── auth_provider.dart         # Authentication & role-based routing
│   └── cart_provider.dart         # Shopping cart state
├── services/                      # API & data services
│   ├── api_service.dart           # Base HTTP client
│   ├── auth_api_service.dart
│   ├── catalog_api_service.dart
│   ├── orders_api_service.dart
│   ├── pickup_api_service.dart
│   ├── dispatch_api_service.dart
│   └── firestore_service.dart     # Firestore operations
├── screens/                       # UI screens
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── customer/
│   │   └── customer_home_screen.dart
│   ├── driver/
│   │   └── driver_home_screen.dart
│   ├── dispatcher/
│   │   └── dispatcher_home_screen.dart
│   └── admin/
└── widgets/                       # Reusable components
    └── status_timeline.dart
```

## Development Roadmap

### Phase 1: Core Features (Current)
- [x] Authentication system with role-based routing
- [x] Firestore data models and service layer
- [x] API service architecture
- [x] Basic UI for all user roles
- [ ] Product catalog with cart
- [ ] Order creation and tracking
- [ ] Pickup request workflow

### Phase 2: Driver Experience
- [ ] Job detail screens with navigation
- [ ] Photo capture component
- [ ] Signature capture component
- [ ] Offline job queue
- [ ] Background location tracking
- [ ] Push notifications

### Phase 3: Dispatcher Tools
- [ ] Job assignment interface
- [ ] Live driver map with Google Maps
- [ ] Exception handling workflow
- [ ] Driver performance metrics
- [ ] Route optimization

### Phase 4: Enterprise Features
- [ ] B2B branch management
- [ ] User permission system
- [ ] Document management
- [ ] Reporting and analytics
- [ ] Audit trail viewer
- [ ] Service area configuration

### Phase 5: Integration
- [ ] D365 F&O middleware API implementation
- [ ] Real-time sync with ERP
- [ ] Invoice/credit note generation
- [ ] Payment gateway integration
- [ ] Email/SMS notifications

## Business Rules

### Service Areas
- Configurable by province/region
- Minimum pickup quantity by zone
- Delivery time windows by area

### Incentive Types
- **Cash**: Direct payment to customer at collection
- **Credit Note**: Posted to D365 customer account
- **Points**: Loyalty program (customer wallet)
- **All**: Customer can choose preferred incentive

### Quality Flags (UCO Pickup)
- Water content check
- Solid particles check
- Odor assessment
- Free-form notes

### Job Assignment Logic
- Driver availability check
- Vehicle capacity matching
- Geographic proximity
- Time window feasibility
- Stop sequence optimization

## Security Considerations

1. **Authentication**:
   - Phone OTP for customers (Firebase Auth)
   - Email/password for internal users
   - JWT tokens from middleware API

2. **Authorization**:
   - Role-based access control (RBAC)
   - Firestore security rules
   - API endpoint protection

3. **Data Privacy**:
   - Encrypted data transmission (HTTPS)
   - PII protection in logs
   - GDPR compliance considerations

4. **Offline Security**:
   - Local data encryption
   - Secure credential storage
   - Sync conflict resolution

## Testing Strategy

### Unit Tests
- Model serialization/deserialization
- Business logic in providers
- API service methods

### Widget Tests
- Authentication flows
- Form validation
- Component rendering

### Integration Tests
- End-to-end user workflows
- API integration
- Offline functionality

## Production Deployment

### Pre-Deployment Checklist
- [ ] Update API base URL to production
- [ ] Configure Firebase for production project
- [ ] Set up proper Firestore security rules
- [ ] Enable Firebase App Check
- [ ] Configure Google Maps API restrictions
- [ ] Set up error logging (Crashlytics)
- [ ] Performance monitoring
- [ ] Create release signing keystore

### Monitoring
- Firebase Analytics for user behavior
- Crashlytics for crash reporting
- Performance monitoring for API calls
- Custom events for business metrics

## Support and Maintenance

### Known Limitations
- Real-time location tracking requires GPS permission
- Offline mode has limited functionality for new orders
- Photo uploads require network connectivity
- Google Maps requires API key and billing setup

### Future Enhancements
- Multi-language support
- Dark mode theme
- Advanced route optimization
- Customer loyalty program
- Promotional campaigns
- Integration with accounting systems

## License

This is an enterprise application for internal use. All rights reserved.

## Contact

For technical support and inquiries, contact the development team.
