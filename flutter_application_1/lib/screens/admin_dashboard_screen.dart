import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/account_provider.dart';
import '../providers/auth_provider.dart';
import 'admin_account_detail_screen.dart';
import 'admin_user_detail_screen.dart';
import 'admin_report_screen.dart';
import 'admin_chat_screen.dart';
import 'notifications_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Badge(
              label: Text('3'),
              child: Icon(Icons.notifications_none_rounded),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment:
              TabAlignment.start, // Better alignment for scrollable tabs
          indicatorWeight: 4,
          indicatorColor: Colors.white,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.analytics_rounded, size: 20), text: 'Stats'),
            Tab(
              icon: Icon(Icons.verified_user_rounded, size: 20),
              text: 'Verify',
            ),
            Tab(
              icon: Icon(Icons.sports_esports_rounded, size: 20),
              text: 'Games',
            ),
            Tab(icon: Icon(Icons.people_rounded, size: 20), text: 'Users'),
            Tab(
              icon: Icon(Icons.receipt_long_rounded, size: 20),
              text: 'History',
            ),
            Tab(
              icon: Icon(Icons.support_agent_rounded, size: 20),
              text: 'Chat',
            ),
          ],
        ),
      ),
      drawer: _buildDrawer(context, auth),
      body: TabBarView(
        controller: _tabController,
        physics:
            const BouncingScrollPhysics(), // Smoother scrolling between tabs
        children: [
          _buildOverviewTab()
              .animate()
              .fadeIn(duration: 500.ms, curve: Curves.easeOut)
              .slideY(begin: 0.05, end: 0, duration: 500.ms),
          _buildApprovalsTab().animate().fadeIn(
            duration: 500.ms,
            curve: Curves.easeOut,
          ),
          _buildGameAccountsTab().animate().fadeIn(
            duration: 500.ms,
            curve: Curves.easeOut,
          ),
          _buildUsersTab().animate().fadeIn(
            duration: 500.ms,
            curve: Curves.easeOut,
          ),
          _buildTransactionsTab().animate().fadeIn(
            duration: 500.ms,
            curve: Curves.easeOut,
          ),
          _buildChatTab().animate().fadeIn(
            duration: 500.ms,
            curve: Curves.easeOut,
          ),
        ],
      ),
    );
  }

  void _showReasonDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Function(String) onConfirm,
  }) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter reason here...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              onConfirm(controller.text.trim());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  confirmLabel == 'Delete' ||
                      confirmLabel == 'Ban' ||
                      confirmLabel == 'Reject'
                  ? Colors.red
                  : Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider auth) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Colors.deepPurple.shade800,
                ],
              ),
            ),
            accountName: Text(auth.currentUser?.name ?? 'Admin'),
            accountEmail: Text(auth.currentUser?.email ?? 'admin@test.com'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.admin_panel_settings,
                size: 40,
                color: Colors.deepPurple,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Detailed Reports'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminReportScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('System Settings'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => auth.logout(),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quick Insights',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminReportScreen()),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Full Report'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8, // Adjusted for better fit on small screens
            children: [
              _statCard(
                'Revenue',
                '45.2M₫',
                Colors.green,
                Icons.payments_rounded,
              ),
              _statCard(
                'Orders',
                '128',
                Colors.blue,
                Icons.shopping_cart_rounded,
              ),
              _statCard('Users', '1.2k', Colors.orange, Icons.people_rounded),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Recent Submissions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) => _activityTile(
              'Genshin Account #${1024 + index}',
              'Pending verification',
              '${index + 1}h ago',
              Colors.orange,
            ),
          ),
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
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sports_esports, color: Colors.blue),
                ),
                title: Text(
                  'High Rank Account #${2048 + index}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Seller: Hunter_X • Game: Valorant'),
                trailing: Text(
                  '1.5M₫',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          final provider = context.read<AccountProvider>();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminAccountDetailScreen(
                                account: provider.accounts[0],
                                isApprovalMode: true,
                              ),
                            ),
                          );
                        },
                        child: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(
                      onPressed: () {},
                      icon: const Icon(Icons.check),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () {
                        _showReasonDialog(
                          context,
                          title: 'Reject Listing',
                          message: 'Why are you rejecting this account?',
                          confirmLabel: 'Reject',
                          onConfirm: (reason) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Listing rejected. Reason: $reason',
                                ),
                              ),
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ).animate().slideX(begin: 0.2, delay: (index * 100).ms).fadeIn();
      },
    );
  }

  Widget _buildGameAccountsTab() {
    final accounts = context.watch<AccountProvider>().accounts;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SearchBar(
            hintText: 'Search by title or seller...',
            leading: const Icon(Icons.search),
            elevation: WidgetStateProperty.all(2),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    account.imageUrls.first,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  account.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Game: ${account.gameName} • Seller: ${account.sellerName}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminAccountDetailScreen(account: account),
                  ),
                ),
              ).animate().fadeIn(delay: (index * 50).ms);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'All', label: Text('All')),
                    ButtonSegment(value: 'Sellers', label: Text('Sellers')),
                    ButtonSegment(value: 'Banned', label: Text('Banned')),
                  ],
                  selected: const {'All'},
                  onSelectionChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 8,
            itemBuilder: (context, index) {
              final isBanned = index == 2;
              final isSeller = index % 3 == 0;
              return ListTile(
                leading: Hero(
                  tag: 'user-avatar-$index',
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?u=$index',
                    ),
                  ),
                ),
                title: Text(
                  'User ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  isBanned ? 'Status: Banned' : 'Joined: 24/05/2026',
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    if (isSeller)
                      const Chip(
                        label: Text('Seller', style: TextStyle(fontSize: 10)),
                        padding: EdgeInsets.zero,
                      ),
                    IconButton(
                      icon: Icon(
                        isBanned ? Icons.settings_backup_restore : Icons.block,
                        color: isBanned ? Colors.green : Colors.red,
                      ),
                      onPressed: () {
                        if (isBanned) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User unbanned')),
                          );
                        } else {
                          _showReasonDialog(
                            context,
                            title: 'Ban User',
                            message: 'Are you sure you want to ban this user?',
                            confirmLabel: 'Ban',
                            onConfirm: (reason) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('User banned. Reason: $reason'),
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AdminUserDetailScreen(userId: index.toString()),
                  ),
                ),
              ).animate().slideY(begin: 0.1, delay: (index * 50).ms).fadeIn();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SearchBar(
            hintText: 'Search transaction ID or user...',
            leading: const Icon(Icons.search),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 5,
            itemBuilder: (context, index) {
              final buyers = [
                'Nguyen Van A',
                'Tran Thi B',
                'Le Van C',
                'Pham Van D',
                'Hoang Thi E',
              ];
              final amounts = ['1.5M₫', '2.5M₫', '800k₫', '1.2M₫', '3.0M₫'];
              final dates = [
                'Today, 10:45 AM',
                'Today, 09:20 AM',
                'Yesterday',
                'May 28, 2026',
                'May 27, 2026',
              ];
              final status = index == 4 ? 'Refunded' : 'Completed';
              final statusColor = index == 4 ? Colors.orange : Colors.green;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withValues(alpha: 0.1),
                    child: Icon(Icons.receipt_outlined, color: statusColor),
                  ),
                  title: Text('Transaction #TRX-${1000 + index}'),
                  subtitle: Text('Buyer: ${buyers[index]} • $dates'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        amounts[index],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SearchBar(
            hintText: 'Search conversations...',
            leading: const Icon(Icons.search),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 5,
            itemBuilder: (context, index) {
              final users = [
                'Nguyen Van A',
                'Tran Thi B',
                'Le Van C',
                'Pham Van D',
                'Hoang Thi E',
              ];
              final times = [
                '2m ago',
                '15m ago',
                '1h ago',
                '3h ago',
                'Yesterday',
              ];
              final messages = [
                'I can\'t login to my account',
                'Payment failed but money deducted',
                'How to verify my seller account?',
                'I want to report a scammer',
                'Account recovery request',
              ];
              final isUnread = index < 2;

              return ListTile(
                leading: Badge(
                  isLabelVisible: isUnread,
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?u=support$index',
                    ),
                  ),
                ),
                title: Text(
                  users[index],
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  messages[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isUnread ? Colors.black87 : Colors.grey,
                    fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      times[index],
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnread
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                      ),
                    ),
                    if (isUnread)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '1',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminChatScreen(otherUser: users[index]),
                  ),
                ),
              ).animate().fadeIn(delay: (index * 50).ms);
            },
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack);
  }

  Widget _activityTile(
    String title,
    String status,
    String time,
    Color statusColor,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.history_edu, color: statusColor),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          status,
          style: TextStyle(color: statusColor, fontSize: 13),
        ),
        trailing: Text(
          time,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
}
