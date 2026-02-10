#!/usr/bin/env python3
"""
Populate sample workflow data for Phase 4: Workflow Engine
Creates workflow instances, approval requests, exceptions, and audit logs
"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta
import random

# Initialize Firebase Admin SDK
try:
    cred = credentials.Certificate('/opt/flutter/firebase-admin-sdk.json')
    firebase_admin.initialize_app(cred)
    print("✅ Firebase Admin SDK initialized successfully")
except Exception as e:
    print(f"❌ Error initializing Firebase: {e}")
    exit(1)

db = firestore.client()

def create_workflow_instances():
    """Create sample workflow instances"""
    print("\n📦 Creating workflow instances...")
    
    instances = [
        # Sales Order Workflows
        {
            'workflowType': 'sales_order',
            'entityId': 'order_001',
            'entityType': 'sales_order',
            'currentStatus': 'pending',
            'currentStepId': 'step_approval',
            'initiatedBy': 'customer_001',
            'initiatedAt': datetime.now() - timedelta(hours=2),
            'completedAt': None,
            'isCompleted': False,
            'hasException': False,
            'exceptionReason': None,
            'metadata': {
                'totalAmount': 450.00,
                'itemCount': 3,
                'customerName': 'ABC Restaurant',
                'deliveryAddress': '123 Main St, Bangkok'
            },
            'slaDeadline': datetime.now() + timedelta(hours=22),
            'isOverdue': False,
        },
        {
            'workflowType': 'sales_order',
            'entityId': 'order_002',
            'entityType': 'sales_order',
            'currentStatus': 'approved',
            'currentStepId': 'step_processing',
            'initiatedBy': 'customer_002',
            'initiatedAt': datetime.now() - timedelta(days=1),
            'completedAt': None,
            'isCompleted': False,
            'hasException': True,
            'exceptionReason': 'Product out of stock',
            'metadata': {
                'totalAmount': 1200.00,
                'itemCount': 5,
                'customerName': 'XYZ Hotel',
                'deliveryAddress': '456 Sukhumvit Rd, Bangkok'
            },
            'slaDeadline': datetime.now() - timedelta(hours=2),
            'isOverdue': True,
        },
        
        # UCO Pickup Workflows
        {
            'workflowType': 'uco_pickup',
            'entityId': 'pickup_001',
            'entityType': 'uco_pickup',
            'currentStatus': 'pending',
            'currentStepId': 'step_approval',
            'initiatedBy': 'customer_003',
            'initiatedAt': datetime.now() - timedelta(hours=5),
            'completedAt': None,
            'isCompleted': False,
            'hasException': False,
            'exceptionReason': None,
            'metadata': {
                'estimatedQuantity': 50,
                'ucoGrade': 'Premium A',
                'pickupAddress': '789 Restaurant Row, Bangkok',
                'estimatedPayment': 2500.00
            },
            'slaDeadline': datetime.now() + timedelta(hours=19),
            'isOverdue': False,
        },
        {
            'workflowType': 'uco_pickup',
            'entityId': 'pickup_002',
            'entityType': 'uco_pickup',
            'currentStatus': 'approved',
            'currentStepId': 'step_scheduling',
            'initiatedBy': 'customer_004',
            'initiatedAt': datetime.now() - timedelta(hours=10),
            'completedAt': None,
            'isCompleted': False,
            'hasException': False,
            'exceptionReason': None,
            'metadata': {
                'estimatedQuantity': 75,
                'ucoGrade': 'Standard B',
                'pickupAddress': '321 Industrial Zone, Bangkok',
                'estimatedPayment': 3000.00
            },
            'slaDeadline': datetime.now() + timedelta(hours=14),
            'isOverdue': False,
        },
        
        # Return Request Workflows
        {
            'workflowType': 'return_request',
            'entityId': 'return_001',
            'entityType': 'return_request',
            'currentStatus': 'pending',
            'currentStepId': 'step_approval',
            'initiatedBy': 'customer_005',
            'initiatedAt': datetime.now() - timedelta(hours=1),
            'completedAt': None,
            'isCompleted': False,
            'hasException': False,
            'exceptionReason': None,
            'metadata': {
                'orderId': 'order_003',
                'returnReason': 'Damaged Product',
                'returnAmount': 350.00
            },
            'slaDeadline': datetime.now() + timedelta(hours=23),
            'isOverdue': False,
        },
        {
            'workflowType': 'return_request',
            'entityId': 'return_002',
            'entityType': 'return_request',
            'currentStatus': 'rejected',
            'currentStepId': 'step_closed',
            'initiatedBy': 'customer_006',
            'initiatedAt': datetime.now() - timedelta(days=2),
            'completedAt': datetime.now() - timedelta(days=1),
            'isCompleted': True,
            'hasException': False,
            'exceptionReason': None,
            'metadata': {
                'orderId': 'order_004',
                'returnReason': 'Changed Mind',
                'returnAmount': 200.00,
                'rejectionReason': 'Return window expired'
            },
            'slaDeadline': datetime.now() - timedelta(days=1),
            'isOverdue': False,
        },
    ]
    
    for instance in instances:
        doc_ref = db.collection('workflow_instances').add(instance)
        print(f"   ✓ Created workflow: {instance['workflowType']} - {instance['entityId']}")
    
    print(f"✅ Created {len(instances)} workflow instances")
    return instances

def create_approval_requests():
    """Create sample approval requests"""
    print("\n🔔 Creating approval requests...")
    
    requests = [
        # Sales order approval - Urgent
        {
            'workflowInstanceId': 'wf_001',
            'workflowStepId': 'step_approval_001',
            'workflowType': 'sales_order',
            'entityId': 'order_001',
            'requestType': 'order_approval',
            'requestedBy': 'customer_001',
            'requestedAt': datetime.now() - timedelta(hours=2),
            'assignedTo': None,
            'assignedToRole': 'operations_manager',
            'status': 'pending',
            'approvedBy': None,
            'approvedAt': None,
            'rejectionReason': None,
            'requestData': {
                'orderTotal': 450.00,
                'itemCount': 3,
                'customerName': 'ABC Restaurant',
                'deliveryDate': (datetime.now() + timedelta(days=1)).strftime('%Y-%m-%d'),
                'paymentMethod': 'Credit Card'
            },
            'priority': 'high',
            'slaDeadline': datetime.now() + timedelta(hours=22),
        },
        
        # UCO pickup approval - Medium priority
        {
            'workflowInstanceId': 'wf_003',
            'workflowStepId': 'step_approval_003',
            'workflowType': 'uco_pickup',
            'entityId': 'pickup_001',
            'requestType': 'uco_approval',
            'requestedBy': 'customer_003',
            'requestedAt': datetime.now() - timedelta(hours=5),
            'assignedTo': None,
            'assignedToRole': 'operations_manager',
            'status': 'pending',
            'approvedBy': None,
            'approvedAt': None,
            'rejectionReason': None,
            'requestData': {
                'estimatedQuantity': 50,
                'ucoGrade': 'Premium A',
                'estimatedPayment': 2500.00,
                'pickupDate': (datetime.now() + timedelta(days=2)).strftime('%Y-%m-%d'),
                'customerName': 'Green Restaurant'
            },
            'priority': 'medium',
            'slaDeadline': datetime.now() + timedelta(hours=19),
        },
        
        # Return request approval - High priority
        {
            'workflowInstanceId': 'wf_005',
            'workflowStepId': 'step_approval_005',
            'workflowType': 'return_request',
            'entityId': 'return_001',
            'requestType': 'return_approval',
            'requestedBy': 'customer_005',
            'requestedAt': datetime.now() - timedelta(hours=1),
            'assignedTo': None,
            'assignedToRole': 'finance_manager',
            'status': 'pending',
            'approvedBy': None,
            'approvedAt': None,
            'rejectionReason': None,
            'requestData': {
                'orderId': 'order_003',
                'returnReason': 'Damaged Product',
                'returnAmount': 350.00,
                'customerName': 'DEF Cafe',
                'orderDate': (datetime.now() - timedelta(days=5)).strftime('%Y-%m-%d')
            },
            'priority': 'high',
            'slaDeadline': datetime.now() + timedelta(hours=23),
        },
        
        # Price override approval - Urgent
        {
            'workflowInstanceId': 'wf_007',
            'workflowStepId': 'step_approval_007',
            'workflowType': 'sales_order',
            'entityId': 'order_005',
            'requestType': 'price_override',
            'requestedBy': 'sales_rep_001',
            'requestedAt': datetime.now() - timedelta(minutes=30),
            'assignedTo': None,
            'assignedToRole': 'finance_manager',
            'status': 'pending',
            'approvedBy': None,
            'approvedAt': None,
            'rejectionReason': None,
            'requestData': {
                'orderId': 'order_005',
                'originalPrice': 1000.00,
                'discountedPrice': 850.00,
                'discountPercent': 15,
                'reason': 'Bulk order discount for loyal customer',
                'customerName': 'Premium Hotel Chain'
            },
            'priority': 'urgent',
            'slaDeadline': datetime.now() + timedelta(hours=2),
        },
        
        # Credit limit approval - Medium priority
        {
            'workflowInstanceId': 'wf_008',
            'workflowStepId': 'step_approval_008',
            'workflowType': 'sales_order',
            'entityId': 'order_006',
            'requestType': 'credit_limit',
            'requestedBy': 'customer_007',
            'requestedAt': datetime.now() - timedelta(hours=3),
            'assignedTo': None,
            'assignedToRole': 'finance_manager',
            'status': 'pending',
            'approvedBy': None,
            'approvedAt': None,
            'rejectionReason': None,
            'requestData': {
                'customerName': 'New Restaurant Chain',
                'currentCreditLimit': 5000.00,
                'requestedCreditLimit': 10000.00,
                'orderAmount': 6500.00,
                'businessYears': 2,
                'paymentHistory': 'Good'
            },
            'priority': 'medium',
            'slaDeadline': datetime.now() + timedelta(hours=21),
        },
    ]
    
    for request in requests:
        doc_ref = db.collection('approval_requests').add(request)
        print(f"   ✓ Created approval: {request['requestType']} - Priority: {request['priority']}")
    
    print(f"✅ Created {len(requests)} approval requests")
    return requests

def create_exceptions():
    """Create sample exception records"""
    print("\n⚠️  Creating exception records...")
    
    exceptions = [
        # Critical: Payment failed
        {
            'workflowInstanceId': 'wf_009',
            'entityType': 'sales_order',
            'entityId': 'order_002',
            'exceptionType': 'payment_failed',
            'severity': 'critical',
            'description': 'Customer credit card payment declined. Transaction ID: TXN123456. Error: Insufficient funds.',
            'occurredAt': datetime.now() - timedelta(hours=6),
            'assignedTo': None,
            'status': 'open',
            'resolution': None,
            'resolvedAt': None,
            'resolvedBy': None,
            'metadata': {
                'orderId': 'order_002',
                'paymentMethod': 'Credit Card',
                'amount': 1200.00,
                'transactionId': 'TXN123456',
                'errorCode': 'INSUFFICIENT_FUNDS'
            }
        },
        
        # High: Stock unavailable
        {
            'workflowInstanceId': 'wf_002',
            'entityType': 'sales_order',
            'entityId': 'order_002',
            'exceptionType': 'stock_unavailable',
            'severity': 'high',
            'description': 'Product "Bulk Cooking Oil 20L" is out of stock. Required: 10 units, Available: 5 units.',
            'occurredAt': datetime.now() - timedelta(hours=4),
            'assignedTo': 'warehouse_manager_001',
            'status': 'in_progress',
            'resolution': None,
            'resolvedAt': None,
            'resolvedBy': None,
            'metadata': {
                'productId': 'prod_003',
                'productName': 'Bulk Cooking Oil 20L',
                'requiredQuantity': 10,
                'availableQuantity': 5,
                'orderId': 'order_002'
            }
        },
        
        # Medium: Address invalid
        {
            'workflowInstanceId': 'wf_010',
            'entityType': 'sales_order',
            'entityId': 'order_007',
            'exceptionType': 'address_invalid',
            'severity': 'medium',
            'description': 'Delivery address could not be validated by Google Maps API. Address: "123 Non-existent Street".',
            'occurredAt': datetime.now() - timedelta(hours=2),
            'assignedTo': None,
            'status': 'open',
            'resolution': None,
            'resolvedAt': None,
            'resolvedBy': None,
            'metadata': {
                'orderId': 'order_007',
                'invalidAddress': '123 Non-existent Street, Bangkok',
                'customerPhone': '+66 81 234 5678'
            }
        },
        
        # High: Quality issue
        {
            'workflowInstanceId': 'wf_011',
            'entityType': 'uco_pickup',
            'entityId': 'pickup_003',
            'exceptionType': 'quality_issue',
            'severity': 'high',
            'description': 'UCO quality score (45) below minimum threshold (60) for Premium A grade. May need re-grading.',
            'occurredAt': datetime.now() - timedelta(hours=1),
            'assignedTo': 'quality_inspector_001',
            'status': 'in_progress',
            'resolution': None,
            'resolvedAt': None,
            'resolvedBy': None,
            'metadata': {
                'pickupId': 'pickup_003',
                'expectedGrade': 'Premium A',
                'actualQualityScore': 45,
                'minQualityScore': 60,
                'suggestedGrade': 'Basic C'
            }
        },
        
        # Low: Other - Documentation missing
        {
            'workflowInstanceId': 'wf_012',
            'entityType': 'return_request',
            'entityId': 'return_003',
            'exceptionType': 'other',
            'severity': 'low',
            'description': 'Return request missing required documentation. Customer needs to provide proof of purchase.',
            'occurredAt': datetime.now() - timedelta(minutes=30),
            'assignedTo': None,
            'status': 'open',
            'resolution': None,
            'resolvedAt': None,
            'resolvedBy': None,
            'metadata': {
                'returnId': 'return_003',
                'missingDocuments': ['Purchase Invoice', 'Product Photos'],
                'customerEmail': 'customer@example.com'
            }
        },
    ]
    
    for exception in exceptions:
        doc_ref = db.collection('exceptions').add(exception)
        print(f"   ✓ Created exception: {exception['exceptionType']} - Severity: {exception['severity']}")
    
    print(f"✅ Created {len(exceptions)} exception records")
    return exceptions

def create_audit_logs():
    """Create sample audit log entries"""
    print("\n📋 Creating audit log entries...")
    
    logs = [
        # Workflow created
        {
            'workflowInstanceId': 'wf_001',
            'entityType': 'sales_order',
            'entityId': 'order_001',
            'action': 'created',
            'performedBy': 'customer_001',
            'performedAt': datetime.now() - timedelta(hours=2),
            'fromStatus': None,
            'toStatus': 'pending',
            'notes': 'New sales order created by customer',
            'changes': {
                'totalAmount': 450.00,
                'status': 'pending'
            }
        },
        
        # Approval request created
        {
            'workflowInstanceId': 'wf_001',
            'entityType': 'sales_order',
            'entityId': 'order_001',
            'action': 'approval_requested',
            'performedBy': 'system',
            'performedAt': datetime.now() - timedelta(hours=2),
            'fromStatus': None,
            'toStatus': None,
            'notes': 'Approval request sent to operations manager',
            'changes': {
                'approvalType': 'order_approval',
                'assignedToRole': 'operations_manager'
            }
        },
        
        # Status changed
        {
            'workflowInstanceId': 'wf_004',
            'entityType': 'uco_pickup',
            'entityId': 'pickup_002',
            'action': 'status_changed',
            'performedBy': 'operations_manager_001',
            'performedAt': datetime.now() - timedelta(hours=9),
            'fromStatus': 'pending',
            'toStatus': 'approved',
            'notes': 'UCO pickup request approved',
            'changes': {
                'status': 'approved',
                'approvedBy': 'operations_manager_001'
            }
        },
        
        # Approved
        {
            'workflowInstanceId': 'wf_004',
            'entityType': 'uco_pickup',
            'entityId': 'pickup_002',
            'action': 'approved',
            'performedBy': 'operations_manager_001',
            'performedAt': datetime.now() - timedelta(hours=9),
            'fromStatus': 'pending',
            'toStatus': 'approved',
            'notes': 'Approved via Approval Inbox',
            'changes': {}
        },
        
        # Rejected
        {
            'workflowInstanceId': 'wf_006',
            'entityType': 'return_request',
            'entityId': 'return_002',
            'action': 'rejected',
            'performedBy': 'finance_manager_001',
            'performedAt': datetime.now() - timedelta(days=1),
            'fromStatus': 'pending',
            'toStatus': 'rejected',
            'notes': 'Return window expired (30 days)',
            'changes': {
                'status': 'rejected',
                'rejectionReason': 'Return window expired'
            }
        },
        
        # Exception raised
        {
            'workflowInstanceId': 'wf_002',
            'entityType': 'sales_order',
            'entityId': 'order_002',
            'action': 'exception_raised',
            'performedBy': 'system',
            'performedAt': datetime.now() - timedelta(hours=4),
            'fromStatus': None,
            'toStatus': None,
            'notes': 'Product "Bulk Cooking Oil 20L" is out of stock',
            'changes': {
                'hasException': True,
                'exceptionType': 'stock_unavailable'
            }
        },
        
        # Assigned
        {
            'workflowInstanceId': 'wf_002',
            'entityType': 'sales_order',
            'entityId': 'order_002',
            'action': 'assigned',
            'performedBy': 'warehouse_manager_001',
            'performedAt': datetime.now() - timedelta(hours=3, minutes=30),
            'fromStatus': None,
            'toStatus': None,
            'notes': 'Exception assigned to warehouse manager for resolution',
            'changes': {
                'assignedTo': 'warehouse_manager_001'
            }
        },
    ]
    
    for log in logs:
        doc_ref = db.collection('audit_log').add(log)
        print(f"   ✓ Created log: {log['action']} - {log['entityType']}")
    
    print(f"✅ Created {len(logs)} audit log entries")
    return logs

def main():
    """Main execution function"""
    print("=" * 60)
    print("🚀 PHASE 4: Workflow Engine Data Population")
    print("=" * 60)
    
    try:
        # Create all sample data
        create_workflow_instances()
        create_approval_requests()
        create_exceptions()
        create_audit_logs()
        
        print("\n" + "=" * 60)
        print("✅ Sample workflow data populated successfully!")
        print("=" * 60)
        print("\n📊 Summary:")
        print("   • Workflow Instances: 6 (2 sales, 2 UCO, 2 returns)")
        print("   • Approval Requests: 5 (pending approvals)")
        print("   • Exceptions: 5 (open and in-progress)")
        print("   • Audit Log Entries: 7 (various actions)")
        print("\n🔗 Collections created:")
        print("   • workflow_instances")
        print("   • approval_requests")
        print("   • exceptions")
        print("   • audit_log")
        print("\n✨ Ready to test Phase 4 features!")
        
    except Exception as e:
        print(f"\n❌ Error populating data: {e}")
        import traceback
        traceback.print_exc()
        exit(1)

if __name__ == '__main__':
    main()
