# Firestore Database Setup Guide

## Firebase Console Configuration

### Step 1: Create Firestore Database

1. Go to **Firebase Console**: https://console.firebase.google.com/
2. Select your project
3. Navigate to **Build** → **Firestore Database**
4. Click **Create Database**
5. Select production mode or test mode:
   - **Production mode**: Secure rules (recommended for production)
   - **Test mode**: Open access (only for development)
6. Select database location (choose closest to your users)

### Step 2: Create Collections

Run this setup script in Firebase Console or use the provided Python script to create all collections with sample data.

#### Collections to Create:

1. **users**
2. **customer_branches**
3. **products_cache**
4. **sales_orders**
5. **sales_order_lines**
6. **pickup_requests**
7. **jobs**
8. **job_events**
9. **documents**
10. **driver_locations**

### Step 3: Create Composite Indexes

Navigate to **Firestore Database** → **Indexes** → **Composite** and create these indexes:

#### Index 1: sales_orders by customer and date
```
Collection ID: sales_orders
Fields indexed:
  - customerAccountId (Ascending)
  - createdAt (Descending)
Query scope: Collection
```

#### Index 2: sales_orders by status and date
```
Collection ID: sales_orders
Fields indexed:
  - status (Ascending)
  - createdAt (Descending)
Query scope: Collection
```

#### Index 3: pickup_requests by customer and date
```
Collection ID: pickup_requests
Fields indexed:
  - customerAccountId (Ascending)
  - createdAt (Descending)
Query scope: Collection
```

#### Index 4: pickup_requests by status and date
```
Collection ID: pickup_requests
Fields indexed:
  - status (Ascending)
  - createdAt (Descending)
Query scope: Collection
```

#### Index 5: jobs by driver and date
```
Collection ID: jobs
Fields indexed:
  - assignedDriverUid (Ascending)
  - scheduledDate (Ascending)
Query scope: Collection
```

#### Index 6: jobs by status and date
```
Collection ID: jobs
Fields indexed:
  - status (Ascending)
  - scheduledDate (Ascending)
Query scope: Collection
```

#### Index 7: job_events by job and date
```
Collection ID: job_events
Fields indexed:
  - jobId (Ascending)
  - createdAt (Ascending)
Query scope: Collection
```

### Step 4: Security Rules

Replace the default rules with these production-ready security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isRole(role) {
      return request.auth.token.role == role;
    }
    
    function isAnyRole(roles) {
      return request.auth.token.role in roles;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId) || isAnyRole(['admin']);
    }
    
    // Customer branches
    match /customer_branches/{branchId} {
      allow read: if isAuthenticated() && 
        (resource.data.customerAccountId == request.auth.token.customerAccountId ||
         isAnyRole(['dispatcher', 'admin']));
      allow write: if isAuthenticated() &&
        (resource.data.customerAccountId == request.auth.token.customerAccountId ||
         isAnyRole(['admin']));
    }
    
    // Products cache - read only for authenticated users
    match /products_cache/{productId} {
      allow read: if isAuthenticated();
      allow write: if isRole('admin');
    }
    
    // Sales orders
    match /sales_orders/{orderId} {
      allow read: if isAuthenticated() && 
        (resource.data.customerAccountId == request.auth.token.customerAccountId ||
         resource.data.createdByUid == request.auth.uid ||
         isAnyRole(['dispatcher', 'driver', 'admin']));
      allow create: if isAuthenticated() && 
        request.resource.data.createdByUid == request.auth.uid;
      allow update: if isAnyRole(['dispatcher', 'admin']);
    }
    
    // Sales order lines
    match /sales_order_lines/{lineId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isRole('admin');
    }
    
    // Pickup requests
    match /pickup_requests/{pickupId} {
      allow read: if isAuthenticated() && 
        (resource.data.customerAccountId == request.auth.token.customerAccountId ||
         resource.data.createdByUid == request.auth.uid ||
         isAnyRole(['dispatcher', 'driver', 'admin']));
      allow create: if isAuthenticated() && 
        request.resource.data.createdByUid == request.auth.uid;
      allow update: if isAnyRole(['dispatcher', 'driver', 'admin']);
    }
    
    // Jobs
    match /jobs/{jobId} {
      allow read: if isAuthenticated() &&
        (resource.data.assignedDriverUid == request.auth.uid ||
         isAnyRole(['dispatcher', 'admin']));
      allow write: if isAnyRole(['dispatcher', 'admin']);
      allow update: if resource.data.assignedDriverUid == request.auth.uid &&
        request.resource.data.status != resource.data.status;
    }
    
    // Job events
    match /job_events/{eventId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isRole('admin');
    }
    
    // Documents
    match /documents/{documentId} {
      allow read: if isAuthenticated();
      allow write: if isAnyRole(['dispatcher', 'driver', 'admin']);
    }
    
    // Driver locations
    match /driver_locations/{driverUid} {
      allow read: if isAuthenticated() && 
        (isOwner(driverUid) || isAnyRole(['dispatcher', 'admin']));
      allow write: if isOwner(driverUid) || isRole('admin');
    }
  }
}
```

### Step 5: Storage Rules

Navigate to **Build** → **Storage** → **Rules** and set these rules for photo and signature uploads:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isValidImageFile() {
      return request.resource.size < 10 * 1024 * 1024 // 10MB
             && request.resource.contentType.matches('image/.*');
    }
    
    // Order photos
    match /orders/{orderId}/{allPaths=**} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && isValidImageFile();
    }
    
    // Pickup photos
    match /pickups/{pickupId}/{allPaths=**} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && isValidImageFile();
    }
    
    // Job proof photos and signatures
    match /jobs/{jobId}/{allPaths=**} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && isValidImageFile();
    }
    
    // Product images (admin only)
    match /products/{productId}/{allPaths=**} {
      allow read: if true; // Public read
      allow write: if request.auth.token.role == 'admin';
    }
  }
}
```

## Sample Data Creation

### Option 1: Manual Creation via Firebase Console

Create sample documents manually in Firebase Console:

#### Sample User (Customer B2C)
```json
{
  "uid": "user123",
  "role": "customer_b2c",
  "displayName": "John Doe",
  "phone": "+1234567890",
  "email": "john@example.com",
  "customerAccountId": "CUST001",
  "branchIds": [],
  "isActive": true,
  "createdAt": "2024-01-01T00:00:00Z"
}
```

#### Sample User (Driver)
```json
{
  "uid": "driver123",
  "role": "driver",
  "displayName": "Mike Smith",
  "phone": "+1234567891",
  "email": "mike@example.com",
  "customerAccountId": null,
  "branchIds": [],
  "isActive": true,
  "createdAt": "2024-01-01T00:00:00Z"
}
```

#### Sample Product
```json
{
  "sku": "OIL-001",
  "name": "Premium Cooking Oil",
  "uom": "L",
  "packSize": "5L Bottle",
  "imageUrl": "https://example.com/oil.jpg",
  "category": "Cooking Oil",
  "isActive": true,
  "updatedAt": "2024-01-01T00:00:00Z"
}
```

### Option 2: Programmatic Setup (Python Script)

If you have Firebase Admin SDK configured, you can use a Python script to populate sample data. The script would:

1. Create user accounts for each role
2. Populate product catalog
3. Create sample orders and pickups
4. Generate test jobs for drivers

## Verification Checklist

After setup, verify the following:

- [ ] All 10 collections exist in Firestore
- [ ] All 7 composite indexes are created and active
- [ ] Security rules are deployed
- [ ] Storage rules are deployed
- [ ] Sample data is accessible in Firebase Console
- [ ] Flutter app can authenticate users
- [ ] Flutter app can read/write data according to role permissions

## Troubleshooting

### Index Creation Issues
- **Problem**: Queries fail with "requires an index" error
- **Solution**: Click the link in the error message to auto-create the index

### Permission Denied Errors
- **Problem**: "Missing or insufficient permissions" error
- **Solution**: Verify security rules are deployed and user has correct role claim

### Authentication Issues
- **Problem**: Users cannot sign in
- **Solution**: Enable Email/Password and Phone authentication in Firebase Console → Authentication → Sign-in method

## Next Steps

After completing Firestore setup:

1. Configure Firebase in Flutter app (`lib/main.dart`)
2. Add `google-services.json` to Android project
3. Test authentication flows
4. Verify data read/write operations
5. Test offline persistence
6. Monitor usage in Firebase Console

## Production Considerations

Before going to production:

- [ ] Review and tighten security rules
- [ ] Set up backup schedules
- [ ] Enable Firestore monitoring and alerts
- [ ] Configure rate limiting
- [ ] Set up proper error logging
- [ ] Test disaster recovery procedures
- [ ] Document data retention policies
- [ ] Set up cost alerts for usage monitoring

## Additional Resources

- [Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)
- [Best Practices](https://firebase.google.com/docs/firestore/best-practices)
- [Data Modeling Guide](https://firebase.google.com/docs/firestore/data-model)
