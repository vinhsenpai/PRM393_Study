import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'admin_dashboard_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Console')),
      drawer: _buildDrawer(context),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('System Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _adminActionCard('User Management', Icons.people, Colors.blue),
          _adminActionCard('System Reports', Icons.analytics, Colors.green),
          _adminActionCard('Account Moderation', Icons.gavel, Colors.red),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
            child: const Text('Open Full Dashboard'),
          ),
        ],
      ),
    );
  }

  Widget _adminActionCard(String title, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.black87),
            child: Center(child: Text('Admin Control', style: TextStyle(color: Colors.white, fontSize: 20))),
          ),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Logout'), onTap: () => auth.logout()),
        ],
      ),
    );
  }
}
