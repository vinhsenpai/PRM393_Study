import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminReportScreen extends StatelessWidget {
  const AdminReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revenue Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 24),
          const Text('Revenue by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildCategoryItem('League of Legends', '15.000.000₫', 0.4, Colors.blue),
          _buildCategoryItem('Genshin Impact', '12.500.000₫', 0.3, Colors.green),
          _buildCategoryItem('Valorant', '8.000.000₫', 0.2, Colors.red),
          _buildCategoryItem('Other Games', '4.500.000₫', 0.1, Colors.orange),
          const SizedBox(height: 32),
          _buildTrendSection(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      color: Colors.deepPurple,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Total Net Revenue', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('45.200.000₫', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.trending_up, color: Colors.greenAccent),
                const SizedBox(width: 8),
                const Text('+12.5% from last month', style: TextStyle(color: Colors.greenAccent)),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildCategoryItem(String title, String value, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    ).animate().slideX(begin: -0.1, delay: 200.ms);
  }

  Widget _buildTrendSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Monthly Growth', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text('Chart Placeholder', style: TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }
}
