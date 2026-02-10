import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_branch_model.dart';

enum OrderStatus {
  submitted,
  confirmed,
  scheduled,
  outForDelivery,
  delivered,
  invoiced,
  completed,
  cancelled,
}

enum PaymentMethod {
  cod,
  transfer,
  credit,
}

class SalesOrder {
  final String orderId;
  final String? orderNumber;
  final String customerType;
  final String customerAccountId;
  final String? branchId;
  final AddressModel deliveryAddress;
  final DateTime preferredWindowStart;
  final DateTime preferredWindowEnd;
  final OrderStatus status;
  final double totalAmount;
  final String currency;
  final PaymentMethod paymentMethod;
  final String createdByUid;
  final DateTime createdAt;
  final DateTime lastStatusAt;

  SalesOrder({
    required this.orderId,
    this.orderNumber,
    required this.customerType,
    required this.customerAccountId,
    this.branchId,
    required this.deliveryAddress,
    required this.preferredWindowStart,
    required this.preferredWindowEnd,
    required this.status,
    required this.totalAmount,
    required this.currency,
    required this.paymentMethod,
    required this.createdByUid,
    required this.createdAt,
    required this.lastStatusAt,
  });

  factory SalesOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SalesOrder(
      orderId: doc.id,
      orderNumber: data['orderNumber'] as String?,
      customerType: data['customerType'] as String? ?? 'B2C',
      customerAccountId: data['customerAccountId'] as String? ?? '',
      branchId: data['branchId'] as String?,
      deliveryAddress: AddressModel.fromMap(
          data['deliveryAddress'] as Map<String, dynamic>? ?? {}),
      preferredWindowStart:
          (data['preferredWindowStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      preferredWindowEnd:
          (data['preferredWindowEnd'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _parseOrderStatus(data['status'] as String? ?? 'Submitted'),
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'USD',
      paymentMethod: _parsePaymentMethod(data['paymentMethod'] as String? ?? 'COD'),
      createdByUid: data['createdByUid'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastStatusAt: (data['lastStatusAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orderNumber': orderNumber,
      'customerType': customerType,
      'customerAccountId': customerAccountId,
      'branchId': branchId,
      'deliveryAddress': deliveryAddress.toMap(),
      'preferredWindowStart': Timestamp.fromDate(preferredWindowStart),
      'preferredWindowEnd': Timestamp.fromDate(preferredWindowEnd),
      'status': _orderStatusToString(status),
      'totalAmount': totalAmount,
      'currency': currency,
      'paymentMethod': _paymentMethodToString(paymentMethod),
      'createdByUid': createdByUid,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastStatusAt': Timestamp.fromDate(lastStatusAt),
    };
  }

  static OrderStatus _parseOrderStatus(String status) {
    switch (status) {
      case 'Submitted':
        return OrderStatus.submitted;
      case 'Confirmed':
        return OrderStatus.confirmed;
      case 'Scheduled':
        return OrderStatus.scheduled;
      case 'OutForDelivery':
        return OrderStatus.outForDelivery;
      case 'Delivered':
        return OrderStatus.delivered;
      case 'Invoiced':
        return OrderStatus.invoiced;
      case 'Completed':
        return OrderStatus.completed;
      case 'Cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.submitted;
    }
  }

  static String _orderStatusToString(OrderStatus status) {
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

  static PaymentMethod _parsePaymentMethod(String method) {
    switch (method) {
      case 'COD':
        return PaymentMethod.cod;
      case 'Transfer':
        return PaymentMethod.transfer;
      case 'Credit':
        return PaymentMethod.credit;
      default:
        return PaymentMethod.cod;
    }
  }

  static String _paymentMethodToString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cod:
        return 'COD';
      case PaymentMethod.transfer:
        return 'Transfer';
      case PaymentMethod.credit:
        return 'Credit';
    }
  }
}

class SalesOrderLine {
  final String orderId;
  final String sku;
  final double qty;
  final double unitPrice;
  final double lineTotal;

  SalesOrderLine({
    required this.orderId,
    required this.sku,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory SalesOrderLine.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SalesOrderLine(
      orderId: data['orderId'] as String? ?? '',
      sku: data['sku'] as String? ?? '',
      qty: (data['qty'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (data['lineTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orderId': orderId,
      'sku': sku,
      'qty': qty,
      'unitPrice': unitPrice,
      'lineTotal': lineTotal,
    };
  }
}
