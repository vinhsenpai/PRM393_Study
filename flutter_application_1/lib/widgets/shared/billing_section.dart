import 'package:flutter/material.dart';

import 'order_detail_section.dart';

class BillingSection extends StatelessWidget {
  final double subtotal;
  final double tax;
  final double serviceFee;
  final double total;

  const BillingSection({
    super.key,
    required this.subtotal,
    required this.tax,
    required this.serviceFee,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return OrderDetailSection(
      title: 'Billing Information',
      children: [
        _buildBillingRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
        _buildBillingRow('Tax', '\$${tax.toStringAsFixed(2)}'),
        _buildBillingRow('Service Fee', '\$${serviceFee.toStringAsFixed(2)}'),
        const Divider(height: 24),
        _buildBillingRow(
          'Total',
          '\$${total.toStringAsFixed(2)}',
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildBillingRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black87 : Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black87 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}