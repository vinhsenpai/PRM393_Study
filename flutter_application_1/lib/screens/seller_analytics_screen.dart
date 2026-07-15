import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class SellerAnalyticsScreen extends StatelessWidget {
  const SellerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sellerId = auth.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Sales by Month Chart
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sales by Month',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('orders')
                          .where('sellerId', isEqualTo: sellerId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }

                        final orders = snapshot.data?.docs ?? [];

                        // Group by month and calculate total sales
                        Map<String, double> monthlySales = {};
                        for (var doc in orders) {
                          final data = doc.data() as Map<String, dynamic>;
                          final timestamp = data['createdAt'] as Timestamp?;
                          if (timestamp == null) continue;
                          final date = timestamp.toDate();
                          final monthKey =
                              '${date.year}-${date.month.toString().padLeft(2, '0')}';
                          final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
                          monthlySales.update(
                              monthKey, (value) => value + amount, ifAbsent: () => amount);
                        }

                        // Convert to list of FlSpot for the chart
                        List<FlSpot> spots = [];
                        int i = 0;
                        monthlySales.forEach((month, total) {
                          spots.add(FlSpot(i.toDouble(), total));
                          i++;
                        });

                        // Sort by month (optional)
                        spots.sort((a, b) => a.x.compareTo(b.x));

                        return LineChart(
                          LineChartData(
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: Colors.blue,
                                barWidth: 4,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(show: true),
                              ),
                            ],
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: AxisTitles(),
                              topTitles: AxisTitles(),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    int index = value.toInt();
                                    if (index >= 0 && index < monthlySales.length) {
                                      final monthKeys = monthlySales.keys.toList()
                                        ..sort(); // Sort by month
                                      final monthKey = monthKeys[index];
                                      return Text(monthKey,
                                          style: const TextStyle(
                                              fontSize: 10, color: Colors.black));
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Text('\$${value.toInt()}',
                                        style: const TextStyle(
                                            fontSize: 10, color: Colors.black));
                                  },
                                ),
                              ),
                            ),
                            gridData: const FlGridData(show: true),
                            borderData: FlBorderData(show: true),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Orders by Month Chart
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Orders by Month',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('orders')
                          .where('sellerId', isEqualTo: sellerId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }

                        final orders = snapshot.data?.docs ?? [];

                        // Group by month and count orders
                        Map<String, int> monthlyOrders = {};
                        for (var doc in orders) {
                          final data = doc.data() as Map<String, dynamic>;
                          final timestamp = data['createdAt'] as Timestamp?;
                          if (timestamp == null) continue;
                          final date = timestamp.toDate();
                          final monthKey =
                              '${date.year}-${date.month.toString().padLeft(2, '0')}';
                          monthlyOrders.update(
                              monthKey, (value) => value + 1, ifAbsent: () => 1);
                        }

                        // Convert to list of FlSpot for the chart
                        List<FlSpot> spots = [];
                        int i = 0;
                        monthlyOrders.forEach((month, orderCount) {
                          spots.add(FlSpot(i.toDouble(), orderCount.toDouble()));
                          i++;
                        });

                        // Sort by month
                        spots.sort((a, b) => a.x.compareTo(b.x));

                        return LineChart(
                          LineChartData(
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: Colors.green,
                                barWidth: 4,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(show: true),
                              ),
                            ],
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: AxisTitles(),
                              topTitles: AxisTitles(),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    int index = value.toInt();
                                    if (index >= 0 && index < monthlyOrders.length) {
                                      final monthKeys = monthlyOrders.keys.toList()
                                        ..sort(); // Sort by month
                                      final monthKey = monthKeys[index];
                                      return Text(monthKey,
                                          style: const TextStyle(
                                              fontSize: 10, color: Colors.black));
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Text(value.toInt().toString(),
                                        style: const TextStyle(
                                            fontSize: 10, color: Colors.black));
                                  },
                                ),
                              ),
                            ),
                            gridData: const FlGridData(show: true),
                            borderData: FlBorderData(show: true),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}