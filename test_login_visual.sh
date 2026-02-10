#!/bin/bash

echo "🔐 Oil Manager - Login System Status Check"
echo "=========================================="
echo ""

# Check server status
echo "1️⃣  Server Status:"
if lsof -i :5060 > /dev/null 2>&1; then
    echo "   ✅ Server is RUNNING on port 5060"
    SERVER_PID=$(lsof -ti:5060)
    echo "   📍 PID: $SERVER_PID"
else
    echo "   ❌ Server is NOT running"
    exit 1
fi
echo ""

# Check Firebase Auth users
echo "2️⃣  Firebase Authentication Users:"
python3 << 'PYEOF'
from firebase_admin import credentials, auth, initialize_app
import sys

try:
    initialize_app(credentials.Certificate('/opt/flutter/firebase-admin-sdk.json'))
    users = auth.list_users()
    
    if len(users.users) >= 5:
        print(f"   ✅ {len(users.users)} users created")
        for user in users.users:
            print(f"      • {user.email}")
    else:
        print(f"   ⚠️  Only {len(users.users)} users found (expected 5)")
        sys.exit(1)
except Exception as e:
    print(f"   ❌ Error: {e}")
    sys.exit(1)
PYEOF

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Firebase Auth check failed"
    exit 1
fi
echo ""

# Check Firestore user profiles
echo "3️⃣  Firestore User Profiles:"
python3 << 'PYEOF'
from firebase_admin import credentials, firestore, get_app
import sys

try:
    app = get_app()
    db = firestore.client()
    users = list(db.collection('users').get())
    
    if len(users) >= 5:
        print(f"   ✅ {len(users)} profiles in Firestore")
        for doc in users[:3]:  # Show first 3
            data = doc.to_dict()
            print(f"      • {data.get('email', 'N/A')} ({data.get('role', 'N/A')})")
        if len(users) > 3:
            print(f"      ... and {len(users) - 3} more")
    else:
        print(f"   ⚠️  Only {len(users)} profiles found (expected 5)")
        sys.exit(1)
except Exception as e:
    print(f"   ❌ Error: {e}")
    sys.exit(1)
PYEOF

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Firestore check failed"
    exit 1
fi
echo ""

# Test server response
echo "4️⃣  Server Response:"
if curl -s -I http://localhost:5060 | grep "200 OK" > /dev/null; then
    echo "   ✅ Server responding with 200 OK"
else
    echo "   ❌ Server not responding correctly"
    exit 1
fi
echo ""

# Final summary
echo "=========================================="
echo "✅ ALL SYSTEMS OPERATIONAL"
echo ""
echo "🌐 Access URL:"
echo "   https://5060-i461f8m4skrepzmne2o9f-8f57ffe2.sandbox.novita.ai"
echo ""
echo "🔐 Test Credentials:"
echo "   Email: customer@test.com"
echo "   Password: Test123456"
echo ""
echo "📚 Documentation:"
echo "   • LOGIN_GUIDE.md - Troubleshooting guide"
echo "   • README.md - Project overview"
echo "   • QUICK_START.md - Getting started"
echo ""
echo "🎉 Ready to log in!"
