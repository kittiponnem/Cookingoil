#!/usr/bin/env python3
"""
Firestore Setup Script for Oil Manager
Creates collections, indexes, and sample data
"""

import firebase_admin
from firebase_admin import credentials, firestore, auth
from datetime import datetime, timedelta
import sys

print("🔥 Starting Firestore setup for Oil Manager...")

# Initialize Firebase Admin SDK
try:
    cred = credentials.Certificate('/opt/flutter/firebase-admin-sdk.json')
    firebase_admin.initialize_app(cred)
    print("✅ Firebase Admin SDK initialized")
except Exception as e:
    print(f"❌ Failed to initialize Firebase: {e}")
    sys.exit(1)

db = firestore.client()

# Create test users
print("\n📝 Creating test users...")

test_users = [
    {
        'uid': 'customer_b2c_001',
        'email': 'customer@test.com',
        'password': 'Test123456',
        'displayName': 'Test Customer',
        'role': 'customer_b2c'
    },
    {
        'uid': 'customer_b2b_001',
        'email': 'b2b@test.com',
        'password': 'Test123456',
        'displayName': 'B2B Customer',
        'role': 'customer_b2b_user'
    },
    {
        'uid': 'driver_001',
        'email': 'driver@test.com',
        'password': 'Test123456',
        'displayName': 'Test Driver',
        'role': 'driver'
    },
    {
        'uid': 'dispatcher_001',
        'email': 'dispatcher@test.com',
        'password': 'Test123456',
        'displayName': 'Test Dispatcher',
        'role': 'dispatcher'
    },
    {
        'uid': 'admin_001',
        'email': 'admin@test.com',
        'password': 'Test123456',
        'displayName': 'Test Admin',
        'role': 'admin'
    }
]

for user_data in test_users:
    try:
        # Try to create user in Firebase Auth
        try:
            user = auth.create_user(
                uid=user_data['uid'],
                email=user_data['email'],
                password=user_data['password'],
                display_name=user_data['displayName']
            )
            print(f"✅ Created auth user: {user_data['email']}")
        except auth.EmailAlreadyExistsError:
            print(f"⚠️  Auth user already exists: {user_data['email']}")
        except Exception as e:
            print(f"⚠️  Auth user creation skipped: {user_data['email']} - {e}")
        
        # Create user document in Firestore
        user_doc = {
            'uid': user_data['uid'],
            'role': user_data['role'],
            'displayName': user_data['displayName'],
            'phone': f'+123456789{test_users.index(user_data)}',
            'email': user_data['email'],
            'customerAccountId': f"CUST{test_users.index(user_data):03d}" if 'customer' in user_data['role'] else None,
            'branchIds': [],
            'isActive': True,
            'createdAt': firestore.SERVER_TIMESTAMP
        }
        
        db.collection('users').document(user_data['uid']).set(user_doc)
        print(f"✅ Created Firestore user: {user_data['displayName']} ({user_data['role']})")
        
    except Exception as e:
        print(f"❌ Error creating user {user_data['email']}: {e}")

# Create sample products
print("\n📦 Creating sample products...")

products = [
    {
        'sku': 'OIL-001',
        'name': 'Premium Cooking Oil 5L',
        'uom': 'L',
        'packSize': '5L Bottle',
        'imageUrl': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400',
        'category': 'Cooking Oil',
        'isActive': True,
        'updatedAt': firestore.SERVER_TIMESTAMP
    },
    {
        'sku': 'OIL-002',
        'name': 'Standard Cooking Oil 10L',
        'uom': 'L',
        'packSize': '10L Jerry Can',
        'imageUrl': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400',
        'category': 'Cooking Oil',
        'isActive': True,
        'updatedAt': firestore.SERVER_TIMESTAMP
    },
    {
        'sku': 'OIL-003',
        'name': 'Bulk Cooking Oil 20L',
        'uom': 'L',
        'packSize': '20L Container',
        'imageUrl': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400',
        'category': 'Cooking Oil',
        'isActive': True,
        'updatedAt': firestore.SERVER_TIMESTAMP
    }
]

for product in products:
    try:
        db.collection('products_cache').document(product['sku']).set(product)
        print(f"✅ Created product: {product['name']}")
    except Exception as e:
        print(f"❌ Error creating product {product['sku']}: {e}")

# Create sample order
print("\n📋 Creating sample order...")

try:
    order_data = {
        'orderNumber': 'SO-2024-001',
        'customerType': 'B2C',
        'customerAccountId': 'CUST000',
        'branchId': None,
        'deliveryAddress': {
            'text': '123 Main Street, Downtown, City 12345',
            'lat': 40.7128,
            'lng': -74.0060,
            'notes': 'Leave at reception'
        },
        'preferredWindowStart': firestore.SERVER_TIMESTAMP,
        'preferredWindowEnd': firestore.SERVER_TIMESTAMP,
        'status': 'Submitted',
        'totalAmount': 235.00,
        'currency': 'USD',
        'paymentMethod': 'COD',
        'createdByUid': 'customer_b2c_001',
        'createdAt': firestore.SERVER_TIMESTAMP,
        'lastStatusAt': firestore.SERVER_TIMESTAMP
    }
    
    order_ref = db.collection('sales_orders').add(order_data)
    print(f"✅ Created sample order: SO-2024-001")
    
    # Create order lines
    order_lines = [
        {
            'orderId': order_ref[1].id,
            'sku': 'OIL-001',
            'qty': 10,
            'unitPrice': 23.50,
            'lineTotal': 235.00
        }
    ]
    
    for line in order_lines:
        db.collection('sales_order_lines').add(line)
    print(f"✅ Created order lines")
    
except Exception as e:
    print(f"❌ Error creating order: {e}")

# Create sample pickup request
print("\n♻️  Creating sample pickup request...")

try:
    pickup_data = {
        'customerType': 'B2C',
        'customerAccountId': 'CUST000',
        'branchId': None,
        'pickupAddress': {
            'text': '456 Oak Avenue, Uptown, City 12345',
            'lat': 40.7589,
            'lng': -73.9851,
            'notes': 'Use back entrance'
        },
        'estimatedQty': 50,
        'estimatedUom': 'liter',
        'containerType': 'Plastic Jerry Can',
        'photos': [],
        'preferredWindowStart': firestore.SERVER_TIMESTAMP,
        'preferredWindowEnd': firestore.SERVER_TIMESTAMP,
        'incentiveType': 'CreditNote',
        'status': 'Submitted',
        'qualityFlags': None,
        'createdByUid': 'customer_b2c_001',
        'createdAt': firestore.SERVER_TIMESTAMP,
        'lastStatusAt': firestore.SERVER_TIMESTAMP
    }
    
    db.collection('pickup_requests').add(pickup_data)
    print(f"✅ Created sample pickup request")
    
except Exception as e:
    print(f"❌ Error creating pickup request: {e}")

print("\n✅ Firestore setup complete!")
print("\n📧 Test User Credentials:")
print("=" * 50)
for user in test_users:
    print(f"{user['displayName']:20} | {user['email']:25} | {user['password']}")
print("=" * 50)
print("\n🌐 You can now login with these credentials in the app!")
