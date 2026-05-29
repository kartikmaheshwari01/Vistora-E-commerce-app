import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fire_flutter/model/order_model.dart';
import 'package:fire_flutter/model/usermodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderHistoryScreen extends StatelessWidget {
  final UserModal user;

  const OrderHistoryScreen({super.key, required this.user});

  static final Color _green     = Colors.green.shade500;
  static final Color _greenDark = Colors.green.shade700;

  Stream<QuerySnapshot> _ordersStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? user.id;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:    return Colors.orange.shade400;
      case OrderStatus.confirmed:  return Colors.blue.shade400;
      case OrderStatus.processing: return Colors.purple.shade400;
      case OrderStatus.shipped:    return Colors.indigo.shade400;
      case OrderStatus.delivered:  return Colors.green.shade500;
      case OrderStatus.cancelled:  return Colors.red.shade400;
    }
  }

  IconData _statusIcon(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:    return Icons.access_time_rounded;
      case OrderStatus.confirmed:  return Icons.thumb_up_outlined;
      case OrderStatus.processing: return Icons.settings_outlined;
      case OrderStatus.shipped:    return Icons.local_shipping_outlined;
      case OrderStatus.delivered:  return Icons.check_circle_outline_rounded;
      case OrderStatus.cancelled:  return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_greenDark, _green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Orders',
            style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _ordersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(
                    color: _green, strokeWidth: 2.5));
          }
          if (snapshot.hasError) {
            return _centeredMessage(
              context, Icons.error_outline, Colors.red.shade300,
              'Something went wrong', snapshot.error.toString(),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _centeredMessage(
              context, Icons.shopping_bag_outlined,
              Theme.of(context).dividerColor,
              'No orders yet', 'Your placed orders will appear here.',
            );
          }
          final orders = docs.map((d) => OrderModel.fromDoc(d)).toList();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) => _OrderCard(
              order: orders[i],
              statusColor: _statusColor(orders[i].status),
              statusIcon: _statusIcon(orders[i].status),
            ),
          );
        },
      ),
    );
  }

  Widget _centeredMessage(BuildContext context, IconData icon,
      Color iconColor, String title, String subtitle) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 70, color: iconColor),
              const SizedBox(height: 16),
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge?.color)),
              const SizedBox(height: 6),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color)),
            ],
          ),
        ),
      );
}

// ─── Order Card ───────────────────────────────────────────────────────────────
class _OrderCard extends StatefulWidget {
  final OrderModel order;
  final Color      statusColor;
  final IconData   statusIcon;

  const _OrderCard({
    required this.order,
    required this.statusColor,
    required this.statusIcon,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;
  static final Color _green = Colors.green.shade500;

  @override
  Widget build(BuildContext context) {
    final order     = widget.order;
    final shortId   = order.id.substring(0, 8).toUpperCase();
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subColor  = Theme.of(context).textTheme.bodySmall?.color  ?? Colors.grey;
    final divColor  = Theme.of(context).dividerColor;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.receipt_long_outlined,
                            color: _green, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order #$shortId',
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: textColor)),
                            const SizedBox(height: 2),
                            Text(order.formattedDate,
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: subColor)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: widget.statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(widget.statusIcon,
                                color: widget.statusColor, size: 12),
                            const SizedBox(width: 4),
                            Text(order.status.label,
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: widget.statusColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: divColor, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _infoChip(context, Icons.shopping_bag_outlined,
                          '${order.items.length} item${order.items.length > 1 ? 's' : ''}'),
                      const SizedBox(width: 10),
                      _infoChip(context, Icons.money_rounded, 'Cash on Delivery'),
                      const Spacer(),
                      Text('Rs.${order.grandTotal.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.green.shade700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(_expanded ? 'Show less' : 'View details',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: _green,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: _green, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded ────────────────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(color: divColor),
                        const SizedBox(height: 10),

                        _sectionLabel(context, 'Delivery Address',
                            Icons.location_on_outlined),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _addressRow(context, Icons.person_outline,
                                  order.userName),
                              const SizedBox(height: 4),
                              _addressRow(context, Icons.phone_outlined,
                                  order.phone),
                              const SizedBox(height: 4),
                              _addressRow(context, Icons.home_outlined,
                                  order.address),
                              const SizedBox(height: 4),
                              _addressRow(context,
                                  Icons.location_city_outlined, order.city),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        _sectionLabel(context, 'Ordered Items',
                            Icons.shopping_bag_outlined),
                        const SizedBox(height: 8),
                        ...order.items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 50, height: 50,
                                      color: divColor,
                                      child: item.image.startsWith('http')
                                          ? Image.network(item.image,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) =>
                                                  Icon(Icons.image_outlined,
                                                      color: divColor))
                                          : Image.asset(item.image,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) =>
                                                  Icon(Icons.image_outlined,
                                                      color: divColor)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name,
                                            style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: textColor),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                        Text('Qty: ${item.quantity}',
                                            style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: subColor)),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'Rs.${item.totalPrice.toStringAsFixed(0)}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.green.shade700)),
                                ],
                              ),
                            )),

                        Divider(color: divColor, height: 20),
                        _billRow(context, 'Subtotal',
                            'Rs.${order.subtotal.toStringAsFixed(0)}'),
                        const SizedBox(height: 5),
                        _billRow(
                          context, 'Delivery',
                          order.deliveryFee == 0
                              ? 'FREE'
                              : 'Rs.${order.deliveryFee.toStringAsFixed(0)}',
                          valueColor: order.deliveryFee == 0
                              ? Colors.green.shade600
                              : null,
                        ),
                        Divider(color: divColor, height: 20),
                        _billRow(context, 'Total Paid (COD)',
                            'Rs.${order.grandTotal.toStringAsFixed(0)}',
                            isBold: true),
                      ],
                    ),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _infoChip(BuildContext context, IconData icon, String label) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: Theme.of(context).dividerColor),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color)),
      ]);

  Widget _sectionLabel(
      BuildContext context, String text, IconData icon) =>
      Row(children: [
        Icon(icon, color: _green, size: 15),
        const SizedBox(width: 6),
        Text(text,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.bodyLarge?.color)),
      ]);

  Widget _addressRow(
      BuildContext context, IconData icon, String value) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 14, color: Theme.of(context).dividerColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color)),
        ),
      ]);

  Widget _billRow(BuildContext context, String label, String value,
      {bool isBold = false, Color? valueColor}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: isBold ? 13 : 12,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: isBold
                    ? Theme.of(context).textTheme.bodyLarge?.color
                    : Theme.of(context).textTheme.bodySmall?.color)),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: isBold ? 15 : 13,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: valueColor ??
                    (isBold
                        ? Colors.green.shade700
                        : Theme.of(context).textTheme.bodyLarge?.color))),
      ]);
}