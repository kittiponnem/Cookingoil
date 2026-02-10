import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/sales_order_model.dart';
import '../models/pickup_request_model.dart';
import '../models/job_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get customerBranches => _firestore.collection('customer_branches');
  CollectionReference get productsCache => _firestore.collection('products_cache');
  CollectionReference get salesOrders => _firestore.collection('sales_orders');
  CollectionReference get salesOrderLines => _firestore.collection('sales_order_lines');
  CollectionReference get pickupRequests => _firestore.collection('pickup_requests');
  CollectionReference get jobs => _firestore.collection('jobs');
  CollectionReference get jobEvents => _firestore.collection('job_events');
  CollectionReference get documents => _firestore.collection('documents');
  CollectionReference get driverLocations => _firestore.collection('driver_locations');

  // User operations
  Future<UserModel?> getUserById(String uid) async {
    final doc = await users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> createUser(UserModel user) async {
    await users.doc(user.uid).set(user.toFirestore());
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await users.doc(uid).update(data);
  }

  // Product operations
  Future<List<Product>> getActiveProducts() async {
    final snapshot = await productsCache
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final snapshot = await productsCache
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }

  // Sales Order operations
  Future<String> createSalesOrder(SalesOrder order) async {
    final docRef = await salesOrders.add(order.toFirestore());
    return docRef.id;
  }

  Future<void> createSalesOrderLine(SalesOrderLine line) async {
    await salesOrderLines.add(line.toFirestore());
  }

  Future<List<SalesOrder>> getCustomerOrders(String customerAccountId) async {
    final snapshot = await salesOrders
        .where('customerAccountId', isEqualTo: customerAccountId)
        .get();
    
    final orders = snapshot.docs.map((doc) => SalesOrder.fromFirestore(doc)).toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  Future<SalesOrder?> getOrderById(String orderId) async {
    final doc = await salesOrders.doc(orderId).get();
    if (!doc.exists) return null;
    return SalesOrder.fromFirestore(doc);
  }

  Future<List<SalesOrderLine>> getOrderLines(String orderId) async {
    final snapshot = await salesOrderLines
        .where('orderId', isEqualTo: orderId)
        .get();
    return snapshot.docs.map((doc) => SalesOrderLine.fromFirestore(doc)).toList();
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await salesOrders.doc(orderId).update({
      'status': _orderStatusToString(status),
      'lastStatusAt': Timestamp.now(),
    });
  }

  String _orderStatusToString(OrderStatus status) {
    switch (status) {
      case OrderStatus.submitted:
        return 'Submitted';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.scheduled:
        return 'Scheduled';
      case OrderStatus.outForDelivery:
        return 'OutForDelivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.invoiced:
        return 'Invoiced';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Pickup Request operations
  Future<String> createPickupRequest(PickupRequest pickup) async {
    final docRef = await pickupRequests.add(pickup.toFirestore());
    return docRef.id;
  }

  Future<List<PickupRequest>> getCustomerPickups(String customerAccountId) async {
    final snapshot = await pickupRequests
        .where('customerAccountId', isEqualTo: customerAccountId)
        .get();
    
    final pickups = snapshot.docs.map((doc) => PickupRequest.fromFirestore(doc)).toList();
    pickups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return pickups;
  }

  Future<PickupRequest?> getPickupById(String pickupId) async {
    final doc = await pickupRequests.doc(pickupId).get();
    if (!doc.exists) return null;
    return PickupRequest.fromFirestore(doc);
  }

  Future<void> updatePickupStatus(String pickupId, PickupStatus status) async {
    await pickupRequests.doc(pickupId).update({
      'status': _pickupStatusToString(status),
      'lastStatusAt': Timestamp.now(),
    });
  }

  String _pickupStatusToString(PickupStatus status) {
    switch (status) {
      case PickupStatus.submitted:
        return 'Submitted';
      case PickupStatus.approved:
        return 'Approved';
      case PickupStatus.scheduled:
        return 'Scheduled';
      case PickupStatus.driverAssigned:
        return 'DriverAssigned';
      case PickupStatus.collected:
        return 'Collected';
      case PickupStatus.settled:
        return 'Settled';
      case PickupStatus.rejected:
        return 'Rejected';
      case PickupStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Job operations
  Future<String> createJob(Job job) async {
    final docRef = await jobs.add(job.toFirestore());
    return docRef.id;
  }

  Future<List<Job>> getDriverJobs(String driverUid, {DateTime? date}) async {
    Query query = jobs.where('assignedDriverUid', isEqualTo: driverUid);
    
    if (date != null) {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      query = query
          .where('scheduledDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('scheduledDate', isLessThan: Timestamp.fromDate(endOfDay));
    }

    final snapshot = await query.get();
    final jobList = snapshot.docs.map((doc) => Job.fromFirestore(doc)).toList();
    jobList.sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
    return jobList;
  }

  Future<Job?> getJobById(String jobId) async {
    final doc = await jobs.doc(jobId).get();
    if (!doc.exists) return null;
    return Job.fromFirestore(doc);
  }

  Future<void> updateJobStatus(String jobId, JobStatus status) async {
    await jobs.doc(jobId).update({
      'status': _jobStatusToString(status),
    });
  }

  String _jobStatusToString(JobStatus status) {
    switch (status) {
      case JobStatus.assigned:
        return 'Assigned';
      case JobStatus.enRoute:
        return 'EnRoute';
      case JobStatus.arrived:
        return 'Arrived';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.failed:
        return 'Failed';
      case JobStatus.rescheduled:
        return 'Rescheduled';
    }
  }

  // Job Event operations
  Future<void> createJobEvent(JobEvent event) async {
    await jobEvents.add(event.toFirestore());
  }

  Future<List<JobEvent>> getJobEvents(String jobId) async {
    final snapshot = await jobEvents
        .where('jobId', isEqualTo: jobId)
        .get();
    
    final events = snapshot.docs.map((doc) => JobEvent.fromFirestore(doc)).toList();
    events.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return events;
  }

  // Driver Location operations
  Future<void> updateDriverLocation({
    required String driverUid,
    required double lat,
    required double lng,
    double? speed,
    double? heading,
  }) async {
    await driverLocations.doc(driverUid).set({
      'driverUid': driverUid,
      'lat': lat,
      'lng': lng,
      'speed': speed,
      'heading': heading,
      'updatedAt': Timestamp.now(),
    });
  }

  Stream<DocumentSnapshot> watchDriverLocation(String driverUid) {
    return driverLocations.doc(driverUid).snapshots();
  }
}
