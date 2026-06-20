import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../models/user.dart';

class SellerProfileScreen extends StatelessWidget {
  const SellerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return const Center(child: Text('User not found'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('sellerId', isEqualTo: user.id)
            .snapshots(),
        builder: (context, snapshot) {
          final productCount = snapshot.hasData ? snapshot.data?.docs.length : 0;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('sellerId', isEqualTo: user.id)
                .where('status', isEqualTo: 'completed')
                .snapshots(),
            builder: (context, salesSnapshot) {
              double totalSales = 0.0;
              if (salesSnapshot.hasData) {
                for (var doc in salesSnapshot.data?.docs ?? []) {
                  final data = doc.data() as Map<String, dynamic>;
                  totalSales += (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
                }
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Avatar
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: user.photoUrl?.isNotEmpty ?? false
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: !(user.photoUrl?.isNotEmpty ?? false)
                          ? const Icon(Icons.person, size: 60, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Store Name (using name for now)
                  ListTile(
                    leading: const Icon(Icons.store),
                    title: Text(
                      user.name.isNotEmpty ?? false ? user.name : 'No name set',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  // Email
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: Text(
                      user.email.isNotEmpty ? user.email : 'No email set',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  // Role
                  ListTile(
                    leading: const Icon(Icons.badge),
                    title: Text(
                      user.role.toString().split('.').last.toUpperCase(),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const Divider(height: 32),
                  // Stats
                  ListTile(
                    leading: const Icon(Icons.inventory_outlined),
                    title: const Text('Total Listings'),
                    trailing: Text(
                      productCount.toString(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.attach_money),
                    title: const Text('Total Sales'),
                    trailing: Text(
                      '\$${totalSales.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(height: 32),
                  // Actions
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Edit Profile'),
                    onTap: () {
                      // TODO: Navigate to edit profile screen
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Change Password'),
                    onTap: () {
                      // TODO: Navigate to change password screen
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    onTap: () {
                      auth.logout();
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}