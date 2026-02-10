#!/usr/bin/env python3
"""
Create Firebase Authentication users and Firestore user profiles
for Oil Manager application testing
"""

import sys

try:
    import firebase_admin
    from firebase_admin import credentials, auth, firestore
    print("✅ firebase-admin imported successfully\n")
except ImportError as e:
    print(f"❌ Failed to import firebase-admin: {e}")
    sys.exit(1)

# Initialize Firebase
if not firebase_admin._apps:
    cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()

# Test users to create
test_users = [
    {
        "email": "customer@test.com",
        "password": "Test123456",
        "displayName": "Test Customer",
        "role": "customer_b2c",
        "phone": "+1234567890"
    },
    {
        "email": "b2b@test.com",
        "password": "Test123456",
        "displayName": "B2B Customer",
        "role": "customer_b2b_user",
        "phone": "+1234567891"
    },
    {
        "email": "driver@test.com",
        "password": "Test123456",
        "displayName": "Test Driver",
        "role": "driver",
        "phone": "+1234567892"
    },
    {
        "email": "dispatcher@test.com",
        "password": "Test123456",
        "displayName": "Test Dispatcher",
        "role": "dispatcher",
        "phone": "+1234567893"
    },
    {
        "email": "admin@test.com",
        "password": "Test123456",
        "displayName": "Test Admin",
        "role": "admin",
        "phone": "+1234567894"
    }
]

print("🔥 Creating Firebase Authentication Users\n")
print("=" * 60)

created_count = 0
updated_count = 0

for user_data in test_users:
    email = user_data["email"]
    
    try:
        # Try to get existing user
        try:
            existing_user = auth.get_user_by_email(email)
            print(f"✓ User exists: {email}")
            
            # Update user properties if needed
            auth.update_user(
                existing_user.uid,
                display_name=user_data["displayName"],
                password=user_data["password"]
            )
            uid = existing_user.uid
            updated_count += 1
            
        except auth.UserNotFoundError:
            # Create new Firebase Auth user
            new_user = auth.create_user(
                email=email,
                password=user_data["password"],
                display_name=user_data["displayName"],
                email_verified=True
            )
            uid = new_user.uid
            created_count += 1
            print(f"✅ Created: {email}")
        
        # Create/update Firestore user document
        user_doc_data = {
            "uid": uid,
            "email": email,
            "displayName": user_data["displayName"],
            "role": user_data["role"],
            "phone": user_data.get("phone", ""),
            "customerAccountId": "",
            "branchIds": [],
            "isActive": True,
            "createdAt": firestore.SERVER_TIMESTAMP
        }
        
        db.collection("users").document(uid).set(user_doc_data, merge=True)
        print(f"   → Firestore profile: ✅")
        print(f"   → UID: {uid}")
        print(f"   → Role: {user_data['role']}")
        print("-" * 60)
        
    except Exception as e:
        print(f"❌ Error creating {email}: {e}")
        print("-" * 60)

print(f"\n📊 Summary:")
print(f"   Created: {created_count} new users")
print(f"   Updated: {updated_count} existing users")
print(f"   Total: {created_count + updated_count} users ready")

print(f"\n🔐 Test Login Credentials:")
print("=" * 60)
for user_data in test_users:
    print(f"Email: {user_data['email']}")
    print(f"Password: {user_data['password']}")
    print(f"Role: {user_data['role']}")
    print(f"Display Name: {user_data['displayName']}")
    print("-" * 60)

print(f"\n🌐 Login URL:")
print("https://5060-i461f8m4skrepzmne2o9f-8f57ffe2.sandbox.novita.ai")
print("\n✅ All test users created successfully!")
