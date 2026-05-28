import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/account_provider.dart';
import '../models/account.dart';
import 'chat_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.fact_check), text: 'Approvals'),
            Tab(icon: Icon(Icons.gamepad), text: 'Game Accounts'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildApprovalsTab(),
          _buildGameAccountsTab(),
          _buildUsersTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen(otherUser: 'Support Center')));
        },
        child: const Icon(Icons.chat),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenue Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              _statCard('Monthly Revenue', '45.000.000₫', Colors.green, Icons.trending_up),
              const SizedBox(width: 16),
              _statCard('Total Orders', '128', Colors.blue, Icons.shopping_cart),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statCard('New Users', '24', Colors.orange, Icons.person_add),
              const SizedBox(width: 16),
              _statCard('Success Rate', '98%', Colors.purple, Icons.check_circle),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _activityTile('New account submitted for approval', '2 mins ago'),
          _activityTile('Order #ORD-992 completed', '15 mins ago'),
          _activityTile('New user registered: Minh Anh', '1 hour ago'),
        ],
      ),
    );
  }

  Widget _buildApprovalsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.gamepad)),
                  title: const Text('Genshin Impact AR 58 Account'),
                  subtitle: const Text('Seller: ProPlayer99 • Price: 2.000.000₫'),
                ),
                const Text('Description: High end account with many 5* heroes...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () {}, child: const Text('View Details')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Approve'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Reject'),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameAccountsTab() {
    final accounts = context.watch<AccountProvider>().accounts;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search accounts...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return ListTile(
                leading: Image.network(account.imageUrls.first, width: 50, height: 50, fit: BoxFit.cover),
                title: Text(account.title),
                subtitle: Text(currencyFormat.format(account.price)),
                trailing: const Icon(Icons.more_vert),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text('User ${index + 1}'),
          subtitle: Text(index % 3 == 0 ? 'Role: Seller' : 'Role: Buyer'),
          trailing: const Icon(Icons.edit_note),
          onTap: () {},
        );
      },
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _activityTile(String title, String time) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.circle, size: 10, color: Colors.blue),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    );
  }
}
