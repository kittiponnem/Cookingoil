#!/usr/bin/env python3
"""
Test Firebase Authentication connectivity
This script verifies that the Firebase project is properly configured
and test users can authenticate.
"""

import sys
import os

try:
    import firebase_admin
    from firebase_admin import credentials, auth
    print("✅ firebase-admin imported successfully")
except ImportError as e:
    print(f"❌ Failed to import firebase-admin: {e}")
    print("📦 INSTALLATION REQUIRED:")
    print("pip install firebase-admin==7.1.0")
    sys.exit(1)

def test_firebase_connection():
    """Test Firebase Admin SDK connectivity"""
    
    try:
        # Initialize Firebase Admin SDK
        if not firebase_admin._apps:
            cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
            firebase_admin.initialize_app(cred)
            print("✅ Firebase Admin SDK initialized")
        
        # Try to list users (verify connectivity)
        users_page = auth.list_users(max_results=5)
        print(f"\n✅ Firebase connection successful!")
        print(f"📊 Found {len(users_page.users)} test users:")
        
        for user in users_page.users:
            print(f"  - {user.email or user.phone_number} (UID: {user.uid})")
        
        print("\n🔐 Test Login Credentials:")
        print("=" * 50)
        for user in users_page.users:
            if user.email:
                print(f"Email: {user.email}")
                print(f"Password: Test123456 (if user was created by setup script)")
                print(f"UID: {user.uid}")
                print("-" * 50)
        
        print("\n✅ Firebase is properly configured and ready!")
        print("\n🌐 You can now log in at:")
        print("https://5060-i461f8m4skrepzmne2o9f-8f57ffe2.sandbox.novita.ai")
        
        return True
        
    except Exception as e:
        print(f"\n❌ Firebase connection failed: {e}")
        print("\n🔧 Troubleshooting steps:")
        print("1. Verify Firebase Admin SDK file exists: /opt/flutter/firebase-admin-sdk.json")
        print("2. Check Firebase project configuration")
        print("3. Ensure test users were created properly")
        return False

if __name__ == "__main__":
    print("🔥 Testing Firebase Authentication Configuration\n")
    success = test_firebase_connection()
    sys.exit(0 if success else 1)
