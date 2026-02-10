# API Middleware Implementation Guide

## Overview

This document provides detailed specifications for implementing the middleware API layer that connects the Flutter mobile application to Microsoft Dynamics 365 Finance & Operations (D365 F&O).

## Architecture

```
Flutter App → Middleware API → D365 F&O
              (Azure Functions/
               .NET Web API)
```

### Why Middleware?

1. **Security**: Prevents direct exposure of D365 credentials to mobile app
2. **Transformation**: Converts D365 data models to mobile-friendly formats
3. **Business Logic**: Implements validation and business rules
4. **Rate Limiting**: Protects D365 from excessive API calls
5. **Caching**: Reduces load on ERP system
6. **Error Handling**: Provides consistent error responses

## Technology Stack Recommendations

### Option 1: Azure Functions (.NET 6+)
- **Pros**: Serverless, auto-scaling, cost-effective for variable load
- **Cons**: Cold start latency, limited execution time
- **Best for**: Event-driven operations, background jobs

### Option 2: .NET Web API (Azure App Service)
- **Pros**: Always-on, better performance, WebSocket support
- **Cons**: Higher baseline cost, manual scaling management
- **Best for**: Real-time operations, high-throughput scenarios

### Recommended: Hybrid Approach
- **Azure Functions** for batch operations, notifications, scheduled jobs
- **.NET Web API** for real-time customer/driver operations

## Authentication & Authorization

### JWT Token Flow

1. **User Login** (Phone OTP or Email/Password)
   ```
   POST /auth/login
   → Generate JWT with user claims (uid, role, customerAccountId)
   → Return token + refresh token
   ```

2. **Token Validation**
   ```
   All subsequent requests must include:
   Authorization: Bearer <JWT_TOKEN>
   ```

3. **Token Claims**
   ```json
   {
     "uid": "firebase_user_id",
     "role": "customer_b2c|customer_b2b_user|driver|dispatcher|admin",
     "customerAccountId": "D365_CUSTOMER_ID",
     "email": "user@example.com",
     "phone": "+1234567890",
     "exp": 1234567890
   }
   ```

### Role-Based Access Control (RBAC)

Implement middleware authorization attributes:
```csharp
[Authorize(Roles = "customer_b2c,customer_b2b_user")]
[Authorize(Roles = "driver")]
[Authorize(Roles = "dispatcher,admin")]
```

## API Endpoints Specification

### Base URL
```
Production: https://api.oilmanager.com/v1
Staging: https://api-staging.oilmanager.com/v1
```

### Common Response Format

#### Success Response
```json
{
  "success": true,
  "data": { ... },
  "timestamp": "2024-01-01T12:00:00Z"
}
```

#### Error Response
```json
{
  "success": false,
  "error": {
    "code": "ORDER_NOT_FOUND",
    "message": "Order with ID SO-2024-001 not found",
    "details": null
  },
  "timestamp": "2024-01-01T12:00:00Z"
}
```

---

## 1. Authentication API

### POST /auth/login
**Purpose**: Email/password login for internal users

**Request**:
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123",
  "loginType": "email"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "refresh_token_here",
    "expiresIn": 3600,
    "user": {
      "uid": "user123",
      "email": "user@example.com",
      "role": "dispatcher",
      "displayName": "John Doe"
    }
  }
}
```

**D365 Integration**:
- Validate against D365 worker/employee records
- Map D365 worker ID to app user ID
- Retrieve user permissions from D365 security roles

---

### POST /auth/login/send-otp
**Purpose**: Send OTP to customer phone number

**Request**:
```json
{
  "phone": "+1234567890"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "message": "OTP sent successfully",
    "expiresIn": 300
  }
}
```

**Implementation**:
- Use Azure Communication Services or Twilio for SMS
- Store OTP with expiration in Redis/Azure Cache
- Look up customer in D365 by phone number

---

### POST /auth/login/verify-otp
**Purpose**: Verify OTP and complete authentication

**Request**:
```json
{
  "phone": "+1234567890",
  "otp": "123456"
}
```

**Response**: Same as POST /auth/login

**D365 Integration**:
- Retrieve customer account from D365
- Create/update customer record if needed
- Return customer-specific pricing tier

---

## 2. Catalog API

### GET /catalog/products
**Purpose**: Get product catalog with customer-specific pricing

**Query Parameters**:
- `customerId` (optional): D365 customer account ID
- `category` (optional): Product category filter

**Authorization**: All authenticated users

**Response**:
```json
{
  "success": true,
  "data": {
    "products": [
      {
        "sku": "OIL-001",
        "name": "Premium Cooking Oil 5L",
        "description": "High-quality refined cooking oil",
        "category": "Cooking Oil",
        "uom": "L",
        "packSize": "5L Bottle",
        "imageUrl": "https://cdn.example.com/products/oil-001.jpg",
        "basePrice": 25.00,
        "customerPrice": 23.50,
        "currency": "USD",
        "taxRate": 0.05,
        "inStock": true,
        "availableQuantity": 1000
      }
    ],
    "totalCount": 1
  }
}
```

**D365 Integration**:
- Query D365 `InventTable` (Products)
- Get customer-specific pricing from `PriceDiscTable`
- Check inventory levels from `InventSum`
- Apply price agreements and discounts

---

### GET /catalog/products/{sku}/pricing
**Purpose**: Get detailed pricing for specific product and quantity

**Query Parameters**:
- `customerId`: Customer account ID
- `quantity`: Requested quantity

**Response**:
```json
{
  "success": true,
  "data": {
    "sku": "OIL-001",
    "quantity": 10,
    "unitPrice": 23.50,
    "subtotal": 235.00,
    "discounts": [
      {
        "type": "VolumeDiscount",
        "description": "10+ units discount",
        "amount": -11.75
      }
    ],
    "taxAmount": 11.16,
    "total": 234.41,
    "currency": "USD"
  }
}
```

**D365 Integration**:
- Call D365 pricing engine
- Apply trade agreements
- Calculate line discounts and taxes

---

## 3. Orders API

### POST /orders
**Purpose**: Create new sales order in D365

**Request**:
```json
{
  "customerAccountId": "CUST001",
  "branchId": "BRANCH001",
  "deliveryAddress": {
    "text": "123 Main Street, City, State 12345",
    "lat": 40.7128,
    "lng": -74.0060,
    "notes": "Leave at reception"
  },
  "preferredWindowStart": "2024-01-15T09:00:00Z",
  "preferredWindowEnd": "2024-01-15T12:00:00Z",
  "paymentMethod": "COD",
  "lines": [
    {
      "sku": "OIL-001",
      "quantity": 10,
      "requestedPrice": 23.50
    }
  ],
  "notes": "Urgent delivery"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "orderId": "local_order_id_123",
    "orderNumber": "SO-2024-001",
    "status": "Submitted",
    "totalAmount": 234.41,
    "estimatedDelivery": "2024-01-15T10:30:00Z",
    "d365SalesId": "000123456"
  }
}
```

**D365 Integration**:
1. Create sales order header in `SalesTable`
2. Create sales order lines in `SalesLine`
3. Run pricing calculations
4. Reserve inventory
5. Post to D365 journal (async if needed)
6. Return D365 sales order ID

**Error Handling**:
- Insufficient inventory → Suggest alternative delivery date
- Invalid customer → Return customer validation error
- Pricing mismatch → Return current price

---

### GET /orders/{orderId}
**Purpose**: Get order details

**Response**:
```json
{
  "success": true,
  "data": {
    "orderId": "local_order_id_123",
    "orderNumber": "SO-2024-001",
    "status": "Confirmed",
    "customerAccountId": "CUST001",
    "deliveryAddress": { ... },
    "lines": [ ... ],
    "totalAmount": 234.41,
    "statusHistory": [
      {
        "status": "Submitted",
        "timestamp": "2024-01-14T10:00:00Z"
      },
      {
        "status": "Confirmed",
        "timestamp": "2024-01-14T10:15:00Z"
      }
    ],
    "documents": [
      {
        "type": "OrderConfirmation",
        "url": "https://docs.example.com/order-123.pdf",
        "createdAt": "2024-01-14T10:15:00Z"
      }
    ]
  }
}
```

**D365 Integration**:
- Query `SalesTable` and `SalesLine`
- Get status from D365 workflow
- Retrieve attached documents

---

### PUT /orders/{orderId}/status
**Purpose**: Update order status (dispatcher/admin only)

**Request**:
```json
{
  "status": "Scheduled",
  "scheduledDate": "2024-01-15T09:00:00Z",
  "notes": "Assigned to driver TRUCK-001"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "orderId": "local_order_id_123",
    "status": "Scheduled",
    "updatedAt": "2024-01-14T15:00:00Z"
  }
}
```

**D365 Integration**:
- Update sales order status
- Trigger D365 workflow state change
- Create status log entry

---

## 4. Pickup API

### POST /pickups
**Purpose**: Create UCO pickup request

**Request**:
```json
{
  "customerAccountId": "CUST001",
  "pickupAddress": {
    "text": "456 Oak Avenue, City, State",
    "lat": 40.7589,
    "lng": -73.9851,
    "notes": "Use back entrance"
  },
  "estimatedQty": 50,
  "estimatedUom": "liter",
  "containerType": "Plastic Jerry Can",
  "photos": [
    "https://storage.example.com/pickups/photo1.jpg"
  ],
  "preferredWindowStart": "2024-01-16T13:00:00Z",
  "preferredWindowEnd": "2024-01-16T15:00:00Z",
  "incentiveType": "CreditNote"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "pickupId": "local_pickup_id_456",
    "pickupNumber": "PK-2024-001",
    "status": "Submitted",
    "estimatedIncentive": 25.00,
    "d365PurchaseId": "PO-000456"
  }
}
```

**D365 Integration**:
- Create purchase order for UCO collection
- Calculate incentive based on quality tier
- Link to customer account

---

### PUT /pickups/{pickupId}/status
**Purpose**: Update pickup status

**Request**:
```json
{
  "status": "Collected",
  "actualQty": 48,
  "actualUom": "liter",
  "qualityFlags": {
    "water": false,
    "solid": false,
    "odor": false,
    "otherNotes": "Good quality"
  },
  "photos": [
    "https://storage.example.com/pickups/proof1.jpg"
  ],
  "signatureUrl": "https://storage.example.com/pickups/signature1.jpg"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "pickupId": "local_pickup_id_456",
    "status": "Collected",
    "finalIncentive": 24.00,
    "settlementMethod": "CreditNote",
    "creditNoteNumber": "CN-2024-001"
  }
}
```

**D365 Integration**:
- Update purchase order status
- Generate credit note or cash voucher
- Post to customer account

---

## 5. Dispatch API

### POST /dispatch/jobs
**Purpose**: Create and assign delivery/pickup job

**Request**:
```json
{
  "jobType": "Delivery",
  "refId": "local_order_id_123",
  "assignedDriverUid": "driver123",
  "assignedVehicleId": "TRUCK-001",
  "scheduledDate": "2024-01-15",
  "windowStart": "2024-01-15T09:00:00Z",
  "windowEnd": "2024-01-15T12:00:00Z",
  "stopSequence": 1
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "jobId": "job_789",
    "status": "Assigned",
    "createdAt": "2024-01-14T16:00:00Z"
  }
}
```

**D365 Integration**:
- Create shipment record
- Assign to route
- Update inventory allocation

---

### POST /dispatch/jobs/{jobId}/complete
**Purpose**: Mark job as completed with proof

**Request**:
```json
{
  "photoUrls": [
    "https://storage.example.com/jobs/delivery1.jpg",
    "https://storage.example.com/jobs/delivery2.jpg"
  ],
  "signatureUrl": "https://storage.example.com/jobs/signature1.jpg",
  "notes": "Delivered successfully",
  "completedAt": "2024-01-15T10:45:00Z",
  "actualQty": 10,
  "actualUom": "units"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "jobId": "job_789",
    "status": "Completed",
    "orderId": "local_order_id_123",
    "nextActions": [
      "Generate invoice",
      "Update inventory"
    ]
  }
}
```

**D365 Integration**:
- Post packing slip
- Generate invoice
- Update inventory transactions
- Store proof documents

---

## Error Codes

| Code | Message | HTTP Status |
|------|---------|-------------|
| AUTH_INVALID_CREDENTIALS | Invalid email or password | 401 |
| AUTH_OTP_EXPIRED | OTP has expired | 401 |
| AUTH_OTP_INVALID | Invalid OTP | 401 |
| ORDER_NOT_FOUND | Order not found | 404 |
| ORDER_INSUFFICIENT_INVENTORY | Insufficient inventory | 400 |
| CUSTOMER_NOT_FOUND | Customer account not found | 404 |
| PRODUCT_NOT_FOUND | Product not found | 404 |
| PICKUP_INVALID_QTY | Pickup quantity below minimum | 400 |
| JOB_ALREADY_ASSIGNED | Job already assigned to another driver | 409 |
| D365_CONNECTION_ERROR | Unable to connect to D365 | 503 |
| D365_SYNC_FAILED | D365 synchronization failed | 500 |

## Implementation Checklist

### Phase 1: Foundation
- [ ] Set up Azure infrastructure (App Service / Functions)
- [ ] Configure D365 OData/Custom Service connection
- [ ] Implement JWT authentication
- [ ] Set up Redis/Azure Cache for session management
- [ ] Configure Application Insights logging

### Phase 2: Core APIs
- [ ] Implement Authentication endpoints
- [ ] Implement Catalog endpoints with D365 pricing
- [ ] Implement Orders endpoints with D365 sales order creation
- [ ] Implement error handling and retry logic
- [ ] Add rate limiting

### Phase 3: Fleet Operations
- [ ] Implement Pickup endpoints
- [ ] Implement Dispatch endpoints
- [ ] Integrate with Firebase for real-time updates
- [ ] Implement job completion workflow
- [ ] Set up document storage

### Phase 4: Testing & Optimization
- [ ] Unit tests for all endpoints
- [ ] Integration tests with D365 sandbox
- [ ] Load testing (100+ concurrent users)
- [ ] Security audit
- [ ] Performance optimization

### Phase 5: Production
- [ ] Deploy to production environment
- [ ] Set up monitoring and alerts
- [ ] Configure auto-scaling
- [ ] Document API for mobile team
- [ ] Training for operations team

## Monitoring & Observability

### Key Metrics to Track
1. **API Performance**
   - Average response time per endpoint
   - P95 and P99 latency
   - Error rate by endpoint

2. **D365 Integration**
   - D365 API call success rate
   - D365 sync lag time
   - Failed synchronizations

3. **Business Metrics**
   - Orders created per day
   - Average order value
   - Pickup completion rate
   - Driver efficiency

### Alerting
- API error rate > 5%
- D365 connection failure
- Order creation failure
- Average response time > 2s

## Security Best Practices

1. **API Security**
   - Use HTTPS only
   - Validate all input
   - Implement rate limiting (100 requests/minute per user)
   - Use API keys for service-to-service calls

2. **D365 Security**
   - Use service account with minimum required permissions
   - Rotate credentials quarterly
   - Log all D365 operations
   - Encrypt sensitive data at rest

3. **Data Protection**
   - Mask PII in logs
   - Implement GDPR data deletion
   - Encrypt data in transit
   - Regular security audits

## Support & Maintenance

### Regular Maintenance
- Weekly dependency updates
- Monthly security patches
- Quarterly D365 compatibility testing
- Annual disaster recovery drills

### Support Escalation
1. **Level 1**: App issues → Mobile support team
2. **Level 2**: API issues → Backend team
3. **Level 3**: D365 issues → ERP team
4. **Level 4**: Infrastructure → DevOps team
