#!/usr/bin/env python3
"""
Populate advanced configuration collections for Phase 5: Config-Driven System
Creates 7 collections with comprehensive sample data
"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# Initialize Firebase
try:
    cred = credentials.Certificate('/opt/flutter/firebase-admin-sdk.json')
    firebase_admin.initialize_app(cred)
    print("✅ Firebase Admin SDK initialized")
except Exception as e:
    print(f"❌ Error: {e}")
    exit(1)

db = firestore.client()

def create_system_settings():
    """1. System Settings - Global configuration parameters"""
    print("\n⚙️  Creating system settings...")
    
    settings = [
        {
            'key': 'MIN_PICKUP_QTY',
            'valueNumber': 20.0,
            'description': 'Minimum UCO pickup quantity in kg',
            'category': 'uco',
            'updatedAt': datetime.now(),
            'updatedBy': 'admin_001'
        },
        {
            'key': 'SLA_DEFAULT_HOURS',
            'valueNumber': 24.0,
            'description': 'Default SLA hours for approvals',
            'category': 'workflow',
            'updatedAt': datetime.now(),
            'updatedBy': 'admin_001'
        },
        {
            'key': 'ENABLE_BIOMETRIC_APPROVAL',
            'valueBool': True,
            'description': 'Enable biometric authentication for approvals',
            'category': 'security',
            'updatedAt': datetime.now(),
            'updatedBy': 'admin_001'
        },
        {
            'key': 'DEFAULT_CURRENCY',
            'valueString': 'THB',
            'description': 'Default currency code',
            'category': 'general',
            'updatedAt': datetime.now(),
            'updatedBy': 'admin_001'
        },
        {
            'key': 'MAX_BULK_APPROVAL_COUNT',
            'valueNumber': 50.0,
            'description': 'Maximum number of approvals in bulk operation',
            'category': 'workflow',
            'updatedAt': datetime.now(),
            'updatedBy': 'admin_001'
        },
        {
            'key': 'ORDER_AUTO_CANCEL_HOURS',
            'valueNumber': 72.0,
            'description': 'Hours after which unpaid orders are auto-cancelled',
            'category': 'logistics',
            'updatedAt': datetime.now(),
            'updatedBy': 'admin_001'
        },
        {
            'key': 'ENABLE_EMAIL_NOTIFICATIONS',
            'valueBool': True,
            'description': 'Enable email notifications system-wide',
            'category': 'notification',
            'updatedAt': datetime.now(),
            'updatedBy': 'admin_001'
        },
        {
            'key': 'ENABLE_PUSH_NOTIFICATIONS',
            'valueBool': True,
            'description': 'Enable push notifications for mobile',
            'category': 'notification',
            'updatedAt': datetime.now(),
            'updatedBy': 'admin_001'
        },
        {
            'key': 'UCO_QUALITY_THRESHOLD',
            'valueNumber': 60.0,
            'description': 'Minimum quality score for UCO acceptance',
            'category': 'uco',
            'updatedAt': datetime.now(),
            'updatedBy': 'admin_001'
        },
        {
            'key': 'DELIVERY_BUFFER_MINUTES',
            'valueNumber': 30.0,
            'description': 'Buffer time between delivery slots',
            'category': 'logistics',
            'updatedAt': datetime.now(),
            'updatedBy': 'admin_001'
        },
    ]
    
    for setting in settings:
        db.collection('config_system_settings').document(setting['key']).set(setting)
        print(f"   ✓ {setting['key']}: {setting.get('valueString') or setting.get('valueNumber') or setting.get('valueBool')}")
    
    print(f"✅ Created {len(settings)} system settings")

def create_workflow_templates():
    """2. Workflow Templates - Versioned workflow definitions"""
    print("\n📋 Creating workflow templates...")
    
    templates = [
        # Sales Order Approval Workflow
        {
            'templateId': 'sales_order_std',
            'name': 'Standard Sales Order Approval',
            'domain': 'sales',
            'version': 1,
            'isActive': True,
            'steps': [
                {
                    'stepNo': 1,
                    'approverType': 'role',
                    'approverValue': 'operations_manager',
                    'slaHours': 24,
                    'escalationRole': 'admin',
                    'conditions': {}
                },
                {
                    'stepNo': 2,
                    'approverType': 'conditional',
                    'approverValue': 'finance_manager',
                    'slaHours': 12,
                    'escalationRole': 'admin',
                    'conditions': {'amount_threshold': 50000}
                }
            ],
            'createdAt': datetime.now(),
            'updatedAt': datetime.now()
        },
        # UCO Pickup Workflow
        {
            'templateId': 'uco_pickup_std',
            'name': 'Standard UCO Pickup Approval',
            'domain': 'pickup',
            'version': 1,
            'isActive': True,
            'steps': [
                {
                    'stepNo': 1,
                    'approverType': 'role',
                    'approverValue': 'operations_manager',
                    'slaHours': 48,
                    'escalationRole': 'warehouse_manager',
                    'conditions': {}
                }
            ],
            'createdAt': datetime.now(),
            'updatedAt': datetime.now()
        },
        # Return Request Workflow
        {
            'templateId': 'return_request_std',
            'name': 'Standard Return Request Approval',
            'domain': 'return',
            'version': 1,
            'isActive': True,
            'steps': [
                {
                    'stepNo': 1,
                    'approverType': 'role',
                    'approverValue': 'finance_manager',
                    'slaHours': 24,
                    'escalationRole': 'admin',
                    'conditions': {}
                },
                {
                    'stepNo': 2,
                    'approverType': 'conditional',
                    'approverValue': 'admin',
                    'slaHours': 12,
                    'escalationRole': None,
                    'conditions': {'amount_threshold': 10000}
                }
            ],
            'createdAt': datetime.now(),
            'updatedAt': datetime.now()
        },
    ]
    
    for template in templates:
        db.collection('config_workflow_templates').add(template)
        print(f"   ✓ {template['name']} (v{template['version']}) - {len(template['steps'])} steps")
    
    print(f"✅ Created {len(templates)} workflow templates")

def create_routing_rules():
    """3. Routing Rules - Conditional routing"""
    print("\n🔀 Creating routing rules...")
    
    rules = [
        {
            'ruleId': 'high_value_order',
            'domain': 'sales',
            'priority': 1,
            'conditions': {
                'amount': '> 500000',
                'department': '== "Enterprise"'
            },
            'assignToRole': 'admin',
            'assignToUser': None,
            'isActive': True,
            'updatedAt': datetime.now()
        },
        {
            'ruleId': 'new_vendor_order',
            'domain': 'sales',
            'priority': 2,
            'conditions': {
                'vendorType': '== "New"',
                'amount': '> 100000'
            },
            'assignToRole': 'finance_manager',
            'assignToUser': None,
            'isActive': True,
            'updatedAt': datetime.now()
        },
        {
            'ruleId': 'bulk_uco_pickup',
            'domain': 'pickup',
            'priority': 1,
            'conditions': {
                'quantity': '> 200'
            },
            'assignToRole': 'warehouse_manager',
            'assignToUser': None,
            'isActive': True,
            'updatedAt': datetime.now()
        },
        {
            'ruleId': 'high_value_return',
            'domain': 'return',
            'priority': 1,
            'conditions': {
                'amount': '> 50000'
            },
            'assignToRole': 'admin',
            'assignToUser': None,
            'isActive': True,
            'updatedAt': datetime.now()
        },
    ]
    
    for rule in rules:
        db.collection('config_routing_rules').add(rule)
        print(f"   ✓ {rule['ruleId']} (Priority: {rule['priority']}) → {rule['assignToRole']}")
    
    print(f"✅ Created {len(rules)} routing rules")

def create_uco_incentives():
    """4. UCO Incentives - Zone-based pricing"""
    print("\n💰 Creating UCO incentives...")
    
    incentives = [
        {
            'zone': 'Bangkok Central',
            'customerType': 'B2B',
            'minQty': 50.0,
            'cashRatePerKg': 45.0,
            'creditRatePerKg': 48.0,
            'pointsPerKg': 10.0,
            'qualityMultipliers': {
                'Premium A': 1.2,
                'Standard B': 1.0,
                'Basic C': 0.8
            },
            'isActive': True,
            'updatedAt': datetime.now()
        },
        {
            'zone': 'Bangkok Central',
            'customerType': 'B2C',
            'minQty': 20.0,
            'cashRatePerKg': 40.0,
            'creditRatePerKg': 43.0,
            'pointsPerKg': 8.0,
            'qualityMultipliers': {
                'Premium A': 1.2,
                'Standard B': 1.0,
                'Basic C': 0.8
            },
            'isActive': True,
            'updatedAt': datetime.now()
        },
        {
            'zone': 'Bangkok Suburbs',
            'customerType': 'B2B',
            'minQty': 50.0,
            'cashRatePerKg': 42.0,
            'creditRatePerKg': 45.0,
            'pointsPerKg': 9.0,
            'qualityMultipliers': {
                'Premium A': 1.2,
                'Standard B': 1.0,
                'Basic C': 0.8
            },
            'isActive': True,
            'updatedAt': datetime.now()
        },
        {
            'zone': 'Bangkok Suburbs',
            'customerType': 'B2C',
            'minQty': 20.0,
            'cashRatePerKg': 38.0,
            'creditRatePerKg': 40.0,
            'pointsPerKg': 7.0,
            'qualityMultipliers': {
                'Premium A': 1.2,
                'Standard B': 1.0,
                'Basic C': 0.8
            },
            'isActive': True,
            'updatedAt': datetime.now()
        },
        {
            'zone': 'Provinces',
            'customerType': 'B2B',
            'minQty': 50.0,
            'cashRatePerKg': 40.0,
            'creditRatePerKg': 42.0,
            'pointsPerKg': 8.0,
            'qualityMultipliers': {
                'Premium A': 1.2,
                'Standard B': 1.0,
                'Basic C': 0.8
            },
            'isActive': True,
            'updatedAt': datetime.now()
        },
        {
            'zone': 'Provinces',
            'customerType': 'B2C',
            'minQty': 20.0,
            'cashRatePerKg': 35.0,
            'creditRatePerKg': 37.0,
            'pointsPerKg': 6.0,
            'qualityMultipliers': {
                'Premium A': 1.2,
                'Standard B': 1.0,
                'Basic C': 0.8
            },
            'isActive': True,
            'updatedAt': datetime.now()
        },
    ]
    
    for incentive in incentives:
        db.collection('config_uco_incentives').add(incentive)
        print(f"   ✓ {incentive['zone']} - {incentive['customerType']}: ฿{incentive['cashRatePerKg']}/kg (≥{incentive['minQty']}kg)")
    
    print(f"✅ Created {len(incentives)} UCO incentives")

def create_delivery_slots():
    """5. Delivery Slots - Zone-based capacity"""
    print("\n🚚 Creating delivery slots...")
    
    slots = [
        # Bangkok Central
        {'zone': 'Bangkok Central', 'maxCapacity': 20, 'timeWindowStart': '08:00', 'timeWindowEnd': '12:00', 'isActive': True, 'bufferMinutes': 30, 'updatedAt': datetime.now()},
        {'zone': 'Bangkok Central', 'maxCapacity': 25, 'timeWindowStart': '13:00', 'timeWindowEnd': '17:00', 'isActive': True, 'bufferMinutes': 30, 'updatedAt': datetime.now()},
        {'zone': 'Bangkok Central', 'maxCapacity': 15, 'timeWindowStart': '18:00', 'timeWindowEnd': '21:00', 'isActive': True, 'bufferMinutes': 30, 'updatedAt': datetime.now()},
        
        # Bangkok Suburbs
        {'zone': 'Bangkok Suburbs', 'maxCapacity': 15, 'timeWindowStart': '08:00', 'timeWindowEnd': '12:00', 'isActive': True, 'bufferMinutes': 45, 'updatedAt': datetime.now()},
        {'zone': 'Bangkok Suburbs', 'maxCapacity': 18, 'timeWindowStart': '13:00', 'timeWindowEnd': '17:00', 'isActive': True, 'bufferMinutes': 45, 'updatedAt': datetime.now()},
        
        # Provinces
        {'zone': 'Provinces', 'maxCapacity': 10, 'timeWindowStart': '09:00', 'timeWindowEnd': '13:00', 'isActive': True, 'bufferMinutes': 60, 'updatedAt': datetime.now()},
        {'zone': 'Provinces', 'maxCapacity': 12, 'timeWindowStart': '14:00', 'timeWindowEnd': '18:00', 'isActive': True, 'bufferMinutes': 60, 'updatedAt': datetime.now()},
    ]
    
    for slot in slots:
        db.collection('config_delivery_slots').add(slot)
        print(f"   ✓ {slot['zone']}: {slot['timeWindowStart']}-{slot['timeWindowEnd']} (Capacity: {slot['maxCapacity']})")
    
    print(f"✅ Created {len(slots)} delivery slots")

def create_notification_templates():
    """6. Notification Templates - Multi-channel templates"""
    print("\n📧 Creating notification templates...")
    
    templates = [
        {
            'templateKey': 'approval_pending',
            'channel': 'email',
            'subjectTemplate': 'Approval Required: {{requestType}} #{{requestId}}',
            'bodyTemplate': 'Hello {{approverName}},\n\nA new approval request requires your attention:\n\nRequest ID: {{requestId}}\nType: {{requestType}}\nAmount: {{amount}}\nDue Date: {{dueDate}}\n\nPlease review and approve/reject at your earliest convenience.',
            'isActive': True,
            'updatedAt': datetime.now()
        },
        {
            'templateKey': 'approval_pending',
            'channel': 'push',
            'subjectTemplate': 'Approval Required',
            'bodyTemplate': '{{requestType}} #{{requestId}} awaiting your approval. Amount: {{amount}}',
            'isActive': True,
            'updatedAt': datetime.now()
        },
        {
            'templateKey': 'order_confirmed',
            'channel': 'email',
            'subjectTemplate': 'Order Confirmed: #{{orderId}}',
            'bodyTemplate': 'Dear {{customerName}},\n\nYour order #{{orderId}} has been confirmed.\n\nOrder Total: {{amount}}\nDelivery Date: {{deliveryDate}}\nTracking Link: {{trackingUrl}}\n\nThank you for your business!',
            'isActive': True,
            'updatedAt': datetime.now()
        },
        {
            'templateKey': 'uco_pickup_scheduled',
            'channel': 'email',
            'subjectTemplate': 'UCO Pickup Scheduled: #{{pickupId}}',
            'bodyTemplate': 'Hello {{customerName}},\n\nYour UCO pickup has been scheduled:\n\nPickup ID: {{pickupId}}\nScheduled Date: {{pickupDate}}\nEstimated Quantity: {{quantity}} kg\nEstimated Payment: {{amount}}\n\nOur team will contact you 30 minutes before arrival.',
            'isActive': True,
            'updatedAt': datetime.now()
        },
        {
            'templateKey': 'return_approved',
            'channel': 'email',
            'subjectTemplate': 'Return Request Approved: #{{returnId}}',
            'bodyTemplate': 'Dear {{customerName}},\n\nYour return request #{{returnId}} has been approved.\n\nRefund Amount: {{amount}}\nProcessing Time: 3-5 business days\n\nThank you for your patience.',
            'isActive': True,
            'updatedAt': datetime.now()
        },
    ]
    
    for template in templates:
        db.collection('config_notification_templates').add(template)
        print(f"   ✓ {template['templateKey']} ({template['channel']})")
    
    print(f"✅ Created {len(templates)} notification templates")

def create_status_sequences():
    """7. Status Sequences - Domain-specific status flows"""
    print("\n📊 Creating status sequences...")
    
    sequences = [
        {
            'domain': 'sales_order',
            'statuses': ['pending', 'confirmed', 'preparing', 'in_transit', 'delivered', 'completed'],
            'allowReopen': False,
            'terminalStatuses': ['completed', 'cancelled'],
            'updatedAt': datetime.now()
        },
        {
            'domain': 'uco_pickup',
            'statuses': ['requested', 'scheduled', 'collected', 'verified', 'paid', 'completed'],
            'allowReopen': False,
            'terminalStatuses': ['completed', 'cancelled'],
            'updatedAt': datetime.now()
        },
        {
            'domain': 'return_request',
            'statuses': ['requested', 'approved', 'collected', 'inspected', 'refunded', 'completed'],
            'allowReopen': True,
            'terminalStatuses': ['completed', 'rejected'],
            'updatedAt': datetime.now()
        },
    ]
    
    for sequence in sequences:
        db.collection('config_status_sequences').add(sequence)
        print(f"   ✓ {sequence['domain']}: {len(sequence['statuses'])} statuses, Terminal: {sequence['terminalStatuses']}")
    
    print(f"✅ Created {len(sequences)} status sequences")

def main():
    """Main execution"""
    print("=" * 70)
    print("🚀 PHASE 5: Advanced Configuration System - Data Population")
    print("=" * 70)
    
    try:
        create_system_settings()
        create_workflow_templates()
        create_routing_rules()
        create_uco_incentives()
        create_delivery_slots()
        create_notification_templates()
        create_status_sequences()
        
        print("\n" + "=" * 70)
        print("✅ Advanced config data populated successfully!")
        print("=" * 70)
        print("\n📊 Summary:")
        print("   • System Settings: 10 configuration parameters")
        print("   • Workflow Templates: 3 versioned templates")
        print("   • Routing Rules: 4 conditional rules")
        print("   • UCO Incentives: 6 zone/type combinations")
        print("   • Delivery Slots: 7 time windows across zones")
        print("   • Notification Templates: 5 multi-channel templates")
        print("   • Status Sequences: 3 domain workflows")
        print("\n🔗 Collections created:")
        print("   • config_system_settings")
        print("   • config_workflow_templates")
        print("   • config_routing_rules")
        print("   • config_uco_incentives")
        print("   • config_delivery_slots")
        print("   • config_notification_templates")
        print("   • config_status_sequences")
        print("\n✨ Config-driven system ready for testing!")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        exit(1)

if __name__ == '__main__':
    main()
