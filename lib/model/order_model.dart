import 'package:cloud_firestore/cloud_firestore.dart';

// ── Single item inside an order ───────────────────────────────────────────────
class OrderItem {
  final String name;
  final double price;
  final String image;
  final int quantity;

  const OrderItem({
    required this.name,
    required this.price,
    required this.image,
    required this.quantity,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toJson() => {
        'name':     name,
        'price':    price,
        'image':    image,
        'quantity': quantity,
      };

  factory OrderItem.fromJson(Map<String, dynamic> d) => OrderItem(
        name:     d['name']     ?? '',
        price:    (d['price']   as num?)?.toDouble() ?? 0.0,
        image:    d['image']    ?? '',
        quantity: (d['quantity'] as num?)?.toInt()   ?? 1,
      );
}

// ── Order status enum ─────────────────────────────────────────────────────────
enum OrderStatus { pending, confirmed, processing, shipped, delivered, cancelled }

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:    return 'Pending';
      case OrderStatus.confirmed:  return 'Confirmed';
      case OrderStatus.processing: return 'Processing';
      case OrderStatus.shipped:    return 'Shipped';
      case OrderStatus.delivered:  return 'Delivered';
      case OrderStatus.cancelled:  return 'Cancelled';
    }
  }
}

// ── Full order model ──────────────────────────────────────────────────────────
class OrderModel {
  final String          id;
  final String          userId;
  final String          userName;
  final String          phone;
  final String          address;
  final String          city;
  final List<OrderItem> items;
  final double          subtotal;
  final double          deliveryFee;
  final double          grandTotal;
  final OrderStatus     status;
  final DateTime        createdAt;
  final String          paymentMethod; // always "Cash on Delivery" for now

  const OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.phone,
    required this.address,
    required this.city,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.grandTotal,
    required this.status,
    required this.createdAt,
    this.paymentMethod = 'Cash on Delivery',
  });

  // ── Model → Firestore ───────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'userId':        userId,
        'userName':      userName,
        'phone':         phone,
        'address':       address,
        'city':          city,
        'items':         items.map((i) => i.toJson()).toList(),
        'subtotal':      subtotal,
        'deliveryFee':   deliveryFee,
        'grandTotal':    grandTotal,
        'status':        status.name,
        'paymentMethod': paymentMethod,
        'createdAt':     FieldValue.serverTimestamp(),
      };

  // ── Firestore → Model ───────────────────────────────────────────────────────
  factory OrderModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    final rawItems = (d['items'] as List<dynamic>?) ?? [];
    final items = rawItems
        .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
        .toList();

    OrderStatus status = OrderStatus.pending;
    try {
      status = OrderStatus.values.byName(d['status'] ?? 'pending');
    } catch (_) {}

    DateTime createdAt = DateTime.now();
    if (d['createdAt'] is Timestamp) {
      createdAt = (d['createdAt'] as Timestamp).toDate();
    }

    return OrderModel(
      id:            doc.id,
      userId:        d['userId']        ?? '',
      userName:      d['userName']      ?? '',
      phone:         d['phone']         ?? '',
      address:       d['address']       ?? '',
      city:          d['city']          ?? '',
      items:         items,
      subtotal:      (d['subtotal']     as num?)?.toDouble() ?? 0.0,
      deliveryFee:   (d['deliveryFee']  as num?)?.toDouble() ?? 0.0,
      grandTotal:    (d['grandTotal']   as num?)?.toDouble() ?? 0.0,
      status:        status,
      createdAt:     createdAt,
      paymentMethod: d['paymentMethod'] ?? 'Cash on Delivery',
    );
  }

  // ── Formatted date string ───────────────────────────────────────────────────
  String get formattedDate {
    final d = createdAt;
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}  •  '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}