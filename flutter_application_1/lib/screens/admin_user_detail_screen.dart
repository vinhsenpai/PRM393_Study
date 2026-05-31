import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminUserDetailScreen extends StatelessWidget {
  final String userId;

  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Hero(
              tag: 'user-avatar-$userId',
              child: const CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150'),
              ),
            ).animate().scale(duration: 400.ms),
            const SizedBox(height: 16),
            const Text('Nguyen Van A', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('van-a@example.com', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 32),
            _buildDetailSection('Account Stats'),
            _buildInfoRow('Total Spend', '5.200.000₫'),
            _buildInfoRow('Total Sales', '12.000.000₫'),
            _buildInfoRow('Success Rate', '100%'),
            const SizedBox(height: 24),
            _buildDetailSection('System Logs'),
            _buildLogTile('Logged in from Chrome / Windows', 'Today, 10:45 AM'),
            _buildLogTile('Changed password', '2 days ago'),
            _buildLogTile('Account created', 'May 24, 2026'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.block),
            label: const Text('Ban User'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.email_outlined),
            label: const Text('Email'),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildDetailSection(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildLogTile(String msg, String time) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.history, size: 20),
      title: Text(msg, style: const TextStyle(fontSize: 14)),
      subtitle: Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    );
  }
}
