#!/usr/bin/env python3
"""
Create sample configuration data for Oil Manager application
Populates all config collections with realistic test data
"""

import sys
import os

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    print("✅ firebase-admin imported successfully\n")
except ImportError as e:
    print(f"❌ Failed to import firebase-admin: {e}")
    sys.exit(1)

# Initialize Firebase
if not firebase_admin._apps:
    cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()

print("🔧 Creating Sample Configuration Data")
print("=" * 60)

# ============================================================
# PRODUCTS
# ============================================================
print("\n📦 Creating Products...")

products = [
    {
        "sku": "OIL-PREM-5L",
        "name": "Premium Cooking Oil",
        "description": "High-quality refined cooking oil, perfect for everyday cooking",
        "category": "Premium",
        "uom": "L",
        "packSize": 5.0,
        "imageUrl": "https://via.placeholder.com/400x400?text=Premium+Oil+5L",
        "isActive": True,
        "specifications": {
            "type": "Refined",
            "healthBenefits": ["Low cholesterol", "Heart healthy"],
            "shelfLife": "12 months"
        },
        "tags": ["premium", "refined", "cooking"],
        "createdAt": firestore.SERVER_TIMESTAMP,
    },
    {
        "sku": "OIL-STD-10L",
        "name": "Standard Cooking Oil",
        "description": "Quality cooking oil for bulk use",
        "category": "Standard",
        "uom": "L",
        "packSize": 10.0,
        "imageUrl": "https://via.placeholder.com/400x400?text=Standard+Oil+10L",
        "isActive": True,
        "specifications": {
            "type": "Refined",
            "usage": "General cooking",
            "shelfLife": "12 months"
        },
        "tags": ["standard", "bulk", "cooking"],
        "createdAt": firestore.SERVER_TIMESTAMP,
    },
    {
        "sku": "OIL-BULK-20L",
        "name": "Bulk Cooking Oil",
        "description": "Large volume cooking oil for commercial kitchens",
        "category": "Bulk",
        "uom": "L",
        "packSize": 20.0,
        "imageUrl": "https://via.placeholder.com/400x400?text=Bulk+Oil+20L",
        "isActive": True,
        "specifications": {
            "type": "Commercial",
            "usage": "Restaurant & catering",
            "shelfLife": "12 months"
        },
        "tags": ["bulk", "commercial", "restaurant"],
        "createdAt": firestore.SERVER_TIMESTAMP,
    },
]

for product in products:
    db.collection("config_products").add(product)
    print(f"  ✓ Created: {product['name']} ({product['sku']})")

# ============================================================
# UCO GRADES
# ============================================================
print("\n♻️  Creating UCO Grades...")

uco_grades = [
    {
        "gradeCode": "A",
        "gradeName": "Grade A - Premium",
        "description": "Clean, fresh used cooking oil with minimal impurities",
        "minQualityScore": 80.0,
        "maxQualityScore": 100.0,
        "colorRange": "Light amber to golden",
        "isActive": True,
        "createdAt": firestore.SERVER_TIMESTAMP,
    },
    {
        "gradeCode": "B",
        "gradeName": "Grade B - Standard",
        "description": "Good quality used oil with some impurities",
        "minQualityScore": 60.0,
        "maxQualityScore": 79.0,
        "colorRange": "Medium amber to brown",
        "isActive": True,
        "createdAt": firestore.SERVER_TIMESTAMP,
    },
    {
        "gradeCode": "C",
        "gradeName": "Grade C - Basic",
        "description": "Acceptable used oil with visible impurities",
        "minQualityScore": 40.0,
        "maxQualityScore": 59.0,
        "colorRange": "Dark brown",
        "isActive": True,
        "createdAt": firestore.SERVER_TIMESTAMP,
    },
]

for grade in uco_grades:
    db.collection("config_uco_grades").add(grade)
    print(f"  ✓ Created: {grade['gradeName']} ({grade['gradeCode']})")

# ============================================================
# UCO BUYBACK RATES
# ============================================================
print("\n💰 Creating UCO Buyback Rates...")

# Get grade IDs first
grades_snapshot = db.collection("config_uco_grades").get()
grade_map = {doc.to_dict()['gradeCode']: doc.id for doc in grades_snapshot}

buyback_rates = [
    {
        "gradeId": grade_map.get("A", ""),
        "ratePerKg": 2.50,
        "currency": "USD",
        "validFrom": firestore.SERVER_TIMESTAMP,
        "isActive": True,
        "createdAt": firestore.SERVER_TIMESTAMP,
    },
    {
        "gradeId": grade_map.get("B", ""),
        "ratePerKg": 2.00,
        "currency": "USD",
        "validFrom": firestore.SERVER_TIMESTAMP,
        "isActive": True,
        "createdAt": firestore.SERVER_TIMESTAMP,
    },
    {
        "gradeId": grade_map.get("C", ""),
        "ratePerKg": 1.50,
        "currency": "USD",
        "validFrom": firestore.SERVER_TIMESTAMP,
        "isActive": True,
        "createdAt": firestore.SERVER_TIMESTAMP,
    },
]

for rate in buyback_rates:
    db.collection("config_uco_buyback_rates").add(rate)
    print(f"  ✓ Created: ${rate['ratePerKg']}/kg for grade {rate['gradeId'][:8]}...")

# ============================================================
# PAYMENT METHODS
# ============================================================
print("\n💳 Creating Payment Methods...")

payment_methods = [
    {
        "code": "COD",
        "name": "Cash on Delivery",
        "description": "Pay with cash when order is delivered",
        "requiresApproval": False,
        "isOnlinePayment": False,
        "displayOrder": 1,
        "isActive": True,
        "createdAt": firestore.SERVER_TIMESTAMP,
    },
    {
        "code": "BANK_TRANSFER",
        "name": "Bank Transfer",
        "description": "Direct bank transfer before delivery",
        "requiresApproval": True,
        "isOnlinePayment": False,
        "displayOrder": 2,
        "isActive": True,
        "createdAt": firestore.SERVER_TIMESTAMP,
    },
    {
        "code": "CARD",
        "name": "Credit/Debit Card",
        "description": "Pay online with credit or debit card",
        "requiresApproval": False,
        "isOnlinePayment": True,
        "displayOrder": 3,
        "isActive": True,
        "createdAt": firestore.SERVER_TIMESTAMP,
    },
]

for method in payment_methods:
    db.collection("config_payment_methods").add(method)
    print(f"  ✓ Created: {method['name']} ({method['code']})")

# ============================================================
# ORDER STATUSES
# ============================================================
print("\n📊 Creating Order Statuses...")

order_statuses = [
    # Sales Order Statuses
    {"type": "sales", "code": "PENDING", "name": "Pending", "description": "Order received, awaiting confirmation", "sequence": 1, "isTerminal": False, "color": "#FFA500", "isActive": True, "createdAt": firestore.SERVER_TIMESTAMP},
    {"type": "sales", "code": "CONFIRMED", "name": "Confirmed", "description": "Order confirmed by operations", "sequence": 2, "isTerminal": False, "color": "#2196F3", "isActive": True, "createdAt": firestore.SERVER_TIMESTAMP},
    {"type": "sales", "code": "PREPARING", "name": "Preparing", "description": "Order being prepared in warehouse", "sequence": 3, "isTerminal": False, "color": "#9C27B0", "isActive": True, "createdAt": firestore.SERVER_TIMESTAMP},
    {"type": "sales", "code": "DISPATCHED", "name": "Dispatched", "description": "Order out for delivery", "sequence": 4, "isTerminal": False, "color": "#FF9800", "isActive": True, "createdAt": firestore.SERVER_TIMESTAMP},
    {"type": "sales", "code": "DELIVERED", "name": "Delivered", "description": "Order delivered to customer", "sequence": 5, "isTerminal": True, "color": "#4CAF50", "isActive": True, "createdAt": firestore.SERVER_TIMESTAMP},
    {"type": "sales", "code": "CANCELLED", "name": "Cancelled", "description": "Order cancelled", "sequence": 99, "isTerminal": True, "color": "#F44336", "isActive": True, "createdAt": firestore.SERVER_TIMESTAMP},
    
    # UCO Order Statuses
    {"type": "uco", "code": "REQUESTED", "name": "Requested", "description": "Pickup request received", "sequence": 1, "isTerminal": False, "color": "#FFA500", "isActive": True, "createdAt": firestore.SERVER_TIMESTAMP},
    {"type": "uco", "code": "SCHEDULED", "name": "Scheduled", "description": "Pickup scheduled", "sequence": 2, "isTerminal": False, "color": "#2196F3", "isActive": True, "createdAt": firestore.SERVER_TIMESTAMP},
    {"type": "uco", "code": "COLLECTED", "name": "Collected", "description": "UCO collected from customer", "sequence": 3, "isTerminal": False, "color": "#9C27B0", "isActive": True, "createdAt": firestore.SERVER_TIMESTAMP},
    {"type": "uco", "code": "INSPECTED", "name": "Inspected", "description": "Quality inspection completed", "sequence": 4, "isTerminal": False, "color": "#FF9800", "isActive": True, "createdAt": firestore.SERVER_TIMESTAMP},
    {"type": "uco", "code": "PAID", "name": "Paid", "description": "Payment processed", "sequence": 5, "isTerminal": True, "color": "#4CAF50", "isActive": True, "createdAt": firestore.SERVER_TIMESTAMP},
    
    # Return Statuses
    {"type": "return", "code": "REQUESTED", "name": "Requested", "description": "Return request submitted", "sequence": 1, "isTerminal": False, "color": "#FFA500", "isActive": True, "createdAt": firestore.SERVER_TIMESTAMP},
    {"type": "return", "code": "APPROVED", "name": "Approved", "description": "Return approved", "sequence": 2, "isTerminal": False, "color": "#2196F3", "isActive": True, "createdAt": firestore.SERVER_TIMESTAMP},
    {"type": "return", "code": "COLLECTED", "name": "Collected", "description": "Items collected from customer", "sequence": 3, "isTerminal": False, "color": "#9C27B0", "isActive": True, "createdAt": firestore.SERVER_TIMESTAMP},
    {"type": "return", "code": "REFUNDED", "name": "Refunded", "description": "Refund processed", "sequence": 4, "isTerminal": True, "color": "#4CAF50", "isActive": True, "createdAt": firestore.SERVER_TIMESTAMP},
]

for status in order_statuses:
    db.collection("config_order_statuses").add(status)
    print(f"  ✓ Created: {status['type'].upper()} - {status['name']}")

# ============================================================
# REASONS
# ============================================================
print("\n📝 Creating Reason Codes...")

reasons = [
    # Cancel Reasons
    {"type": "cancel", "code": "CHANGE_MIND", "name": "Changed My Mind", "description": "Customer changed mind about order", "requiresEvidence": False, "requiresComment": False, "displayOrder": 1, "isActive": True, "createdAt": firestore.SERVER_TIMESTAMP},
    {"type": "cancel", "code": "WRONG_PRODUCT", "name": "Ordered Wrong Product", "description": "Customer ordered wrong product", "requiresEvidence": False, "requiresComment": False, "displayOrder": 2, "isActive": True, "createdAt": firestore.SERVER_TIMESTAMP},
    {"type": "cancel", "code": "FOUND_CHEAPER", "name": "Found Cheaper Alternative", "description": "Customer found cheaper option", "requiresEvidence": False, "requiresComment": False, "displayOrder": 3, "isActive": True, "createdAt": firestore.SERVER_TIMESTAMP},
    
    # Return Reasons
    {"type": "return", "code": "DAMAGED", "name": "Damaged Product", "description": "Product arrived damaged", "requiresEvidence": True, "requiresComment": True, "displayOrder": 1, "isActive": True, "createdAt": firestore.SERVER_TIMESTAMP},
    {"type": "return", "code": "WRONG_ITEM", "name": "Wrong Item Delivered", "description": "Received wrong product", "requiresEvidence": True, "requiresComment": True, "displayOrder": 2, "isActive": True, "createdAt": firestore.SERVER_TIMESTAMP},
    {"type": "return", "code": "QUALITY_ISSUE", "name": "Quality Issue", "description": "Product quality not satisfactory", "requiresEvidence": True, "requiresComment": True, "displayOrder": 3, "isActive": True, "createdAt": firestore.SERVER_TIMESTAMP},
    
    # UCO Rejection Reasons
    {"type": "reject_uco", "code": "CONTAMINATED", "name": "Contaminated", "description": "UCO contains contaminants", "requiresEvidence": True, "requiresComment": True, "displayOrder": 1, "isActive": True, "createdAt": firestore.SERVER_TIMESTAMP},
    {"type": "reject_uco", "code": "POOR_QUALITY", "name": "Poor Quality", "description": "UCO quality below acceptable standards", "requiresEvidence": True, "requiresComment": True, "displayOrder": 2, "isActive": True, "createdAt": firestore.SERVER_TIMESTAMP},
    {"type": "reject_uco", "code": "INSUFFICIENT_QTY", "name": "Insufficient Quantity", "description": "Quantity too low for collection", "requiresEvidence": False, "requiresComment": True, "displayOrder": 3, "isActive": True, "createdAt": firestore.SERVER_TIMESTAMP},
]

for reason in reasons:
    db.collection("config_reasons").add(reason)
    print(f"  ✓ Created: {reason['type'].upper()} - {reason['name']}")

# ============================================================
# FULFILLMENT SETTINGS
# ============================================================
print("\n🚚 Creating Fulfillment Settings...")

fulfillment_settings = {
    "deliverySlots": [
        {"slotName": "Morning", "startTime": "08:00", "endTime": "12:00", "maxCapacity": 20},
        {"slotName": "Afternoon", "startTime": "13:00", "endTime": "17:00", "maxCapacity": 20},
        {"slotName": "Evening", "startTime": "17:00", "endTime": "20:00", "maxCapacity": 15},
    ],
    "collectionSlots": [
        {"slotName": "Morning", "startTime": "09:00", "endTime": "12:00", "maxCapacity": 15},
        {"slotName": "Afternoon", "startTime": "14:00", "endTime": "17:00", "maxCapacity": 15},
    ],
    "serviceAreas": [
        {"areaCode": "CENTRAL", "areaName": "Central Region", "provinces": ["Metro Manila", "Rizal", "Cavite"], "cities": ["Manila", "Quezon City", "Makati"], "isActive": True},
        {"areaCode": "NORTH", "areaName": "Northern Region", "provinces": ["Bulacan", "Pampanga"], "cities": ["Malolos", "Angeles"], "isActive": True},
        {"areaCode": "SOUTH", "areaName": "Southern Region", "provinces": ["Laguna", "Batangas"], "cities": ["Santa Rosa", "Batangas City"], "isActive": True},
    ],
    "minOrderAmount": 50.0,
    "deliveryFee": 10.0,
    "freeDeliveryThreshold": 200.0,
    "leadTimeDays": 1,
    "allowSameDayDelivery": False,
    "createdAt": firestore.SERVER_TIMESTAMP,
}

db.collection("config_fulfillment_settings").add(fulfillment_settings)
print(f"  ✓ Created fulfillment settings with {len(fulfillment_settings['deliverySlots'])} delivery slots")

# ============================================================
# WORKFLOW TEMPLATES
# ============================================================
print("\n⚙️  Creating Workflow Templates...")

# Sales Order Workflow
sales_workflow = {
    "domain": "sales",
    "templateName": "Standard Sales Order",
    "description": "Default workflow for all sales orders",
    "conditions": None,
    "steps": [
        {"stepNumber": 1, "stepName": "System Check", "stepType": "SystemCheck", "assignedRole": None, "autoAdvance": True, "requiredAttachments": [], "slaDays": None},
        {"stepNumber": 2, "stepName": "Operations Approval", "stepType": "Approval", "assignedRole": "ops", "autoAdvance": False, "requiredAttachments": [], "slaDays": 1},
        {"stepNumber": 3, "stepName": "Warehouse Pick & Pack", "stepType": "Task", "assignedRole": "warehouse", "autoAdvance": False, "requiredAttachments": [], "slaDays": 1},
        {"stepNumber": 4, "stepName": "Fleet Dispatch", "stepType": "Task", "assignedRole": "fleet", "autoAdvance": False, "requiredAttachments": [], "slaDays": 1},
        {"stepNumber": 5, "stepName": "Driver Delivery", "stepType": "Task", "assignedRole": "driver", "autoAdvance": False, "requiredAttachments": ["POD_PHOTO"], "slaDays": 1},
        {"stepNumber": 6, "stepName": "Payment Reconciliation", "stepType": "Approval", "assignedRole": "finance", "autoAdvance": False, "requiredAttachments": [], "slaDays": 2},
    ],
    "isActive": True,
    "isDefault": True,
    "createdAt": firestore.SERVER_TIMESTAMP,
}

db.collection("config_workflow_templates").add(sales_workflow)
print(f"  ✓ Created: Sales Order Workflow ({len(sales_workflow['steps'])} steps)")

# UCO Workflow
uco_workflow = {
    "domain": "uco",
    "templateName": "Standard UCO Collection",
    "description": "Default workflow for UCO pickups",
    "conditions": None,
    "steps": [
        {"stepNumber": 1, "stepName": "System Check", "stepType": "SystemCheck", "assignedRole": None, "autoAdvance": True, "requiredAttachments": [], "slaDays": None},
        {"stepNumber": 2, "stepName": "Operations Approval", "stepType": "Approval", "assignedRole": "ops", "autoAdvance": False, "requiredAttachments": [], "slaDays": 1},
        {"stepNumber": 3, "stepName": "Fleet Assignment", "stepType": "Task", "assignedRole": "fleet", "autoAdvance": False, "requiredAttachments": [], "slaDays": 1},
        {"stepNumber": 4, "stepName": "Driver Collection", "stepType": "Task", "assignedRole": "driver", "autoAdvance": False, "requiredAttachments": ["COLLECTION_PHOTO"], "slaDays": 2},
        {"stepNumber": 5, "stepName": "QA Inspection & Grading", "stepType": "Task", "assignedRole": "warehouse", "autoAdvance": False, "requiredAttachments": ["INSPECTION_PHOTO"], "slaDays": 1},
        {"stepNumber": 6, "stepName": "Finance Payout Approval", "stepType": "Approval", "assignedRole": "finance", "autoAdvance": False, "requiredAttachments": [], "slaDays": 1},
        {"stepNumber": 7, "stepName": "Payout Execution", "stepType": "Task", "assignedRole": "finance", "autoAdvance": False, "requiredAttachments": [], "slaDays": 2},
    ],
    "isActive": True,
    "isDefault": True,
    "createdAt": firestore.SERVER_TIMESTAMP,
}

db.collection("config_workflow_templates").add(uco_workflow)
print(f"  ✓ Created: UCO Collection Workflow ({len(uco_workflow['steps'])} steps)")

# Return Workflow
return_workflow = {
    "domain": "return",
    "templateName": "Standard Return/Refund",
    "description": "Default workflow for returns and refunds",
    "conditions": None,
    "steps": [
        {"stepNumber": 1, "stepName": "Operations Review", "stepType": "Approval", "assignedRole": "ops", "autoAdvance": False, "requiredAttachments": [], "slaDays": 1},
        {"stepNumber": 2, "stepName": "Fleet Pickup Schedule", "stepType": "Task", "assignedRole": "fleet", "autoAdvance": False, "requiredAttachments": [], "slaDays": 2},
        {"stepNumber": 3, "stepName": "Warehouse Inspection", "stepType": "Task", "assignedRole": "warehouse", "autoAdvance": False, "requiredAttachments": ["INSPECTION_PHOTO"], "slaDays": 1},
        {"stepNumber": 4, "stepName": "Finance Refund Approval", "stepType": "Approval", "assignedRole": "finance", "autoAdvance": False, "requiredAttachments": [], "slaDays": 1},
        {"stepNumber": 5, "stepName": "Refund Execution", "stepType": "Task", "assignedRole": "finance", "autoAdvance": False, "requiredAttachments": [], "slaDays": 2},
    ],
    "isActive": True,
    "isDefault": True,
    "createdAt": firestore.SERVER_TIMESTAMP,
}

db.collection("config_workflow_templates").add(return_workflow)
print(f"  ✓ Created: Return/Refund Workflow ({len(return_workflow['steps'])} steps)")

# ============================================================
# PRICE LISTS
# ============================================================
print("\n💵 Creating Price Lists...")

price_lists = [
    {
        "code": "B2C_STANDARD",
        "name": "B2C Standard Pricing",
        "description": "Standard retail pricing for B2C customers",
        "customerType": "B2C",
        "validFrom": firestore.SERVER_TIMESTAMP,
        "isActive": True,
        "isDefault": True,
        "createdAt": firestore.SERVER_TIMESTAMP,
    },
    {
        "code": "B2B_WHOLESALE",
        "name": "B2B Wholesale Pricing",
        "description": "Discounted pricing for B2B customers",
        "customerType": "B2B",
        "validFrom": firestore.SERVER_TIMESTAMP,
        "isActive": True,
        "isDefault": True,
        "createdAt": firestore.SERVER_TIMESTAMP,
    },
]

price_list_map = {}
for price_list in price_lists:
    doc_ref = db.collection("config_price_lists").add(price_list)
    price_list_map[price_list['code']] = doc_ref[1].id
    print(f"  ✓ Created: {price_list['name']}")

# ============================================================
# PRICE LIST ITEMS
# ============================================================
print("\n💲 Creating Price List Items...")

# Get product IDs
products_snapshot = db.collection("config_products").get()
product_map = {doc.to_dict()['sku']: doc.id for doc in products_snapshot}

price_items = [
    # B2C Pricing
    {"priceListId": price_list_map.get("B2C_STANDARD", ""), "productId": product_map.get("OIL-PREM-5L", ""), "unitPrice": 45.00, "currency": "USD", "createdAt": firestore.SERVER_TIMESTAMP},
    {"priceListId": price_list_map.get("B2C_STANDARD", ""), "productId": product_map.get("OIL-STD-10L", ""), "unitPrice": 80.00, "currency": "USD", "createdAt": firestore.SERVER_TIMESTAMP},
    {"priceListId": price_list_map.get("B2C_STANDARD", ""), "productId": product_map.get("OIL-BULK-20L", ""), "unitPrice": 150.00, "currency": "USD", "createdAt": firestore.SERVER_TIMESTAMP},
    
    # B2B Pricing (10% discount)
    {"priceListId": price_list_map.get("B2B_WHOLESALE", ""), "productId": product_map.get("OIL-PREM-5L", ""), "unitPrice": 40.50, "currency": "USD", "createdAt": firestore.SERVER_TIMESTAMP},
    {"priceListId": price_list_map.get("B2B_WHOLESALE", ""), "productId": product_map.get("OIL-STD-10L", ""), "unitPrice": 72.00, "currency": "USD", "createdAt": firestore.SERVER_TIMESTAMP},
    {"priceListId": price_list_map.get("B2B_WHOLESALE", ""), "productId": product_map.get("OIL-BULK-20L", ""), "unitPrice": 135.00, "currency": "USD", "createdAt": firestore.SERVER_TIMESTAMP},
]

for item in price_items:
    db.collection("config_price_list_items").add(item)

print(f"  ✓ Created {len(price_items)} price list items")

# ============================================================
# SUMMARY
# ============================================================
print("\n" + "=" * 60)
print("✅ SAMPLE DATA CREATION COMPLETE!")
print("=" * 60)
print(f"\n📊 Summary:")
print(f"   • Products: {len(products)}")
print(f"   • UCO Grades: {len(uco_grades)}")
print(f"   • Buyback Rates: {len(buyback_rates)}")
print(f"   • Payment Methods: {len(payment_methods)}")
print(f"   • Order Statuses: {len(order_statuses)}")
print(f"   • Reason Codes: {len(reasons)}")
print(f"   • Fulfillment Settings: 1 document")
print(f"   • Workflow Templates: 3 (Sales, UCO, Return)")
print(f"   • Price Lists: {len(price_lists)}")
print(f"   • Price List Items: {len(price_items)}")
print(f"\n🎉 All configuration data is ready for use!")
