import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../models/user.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

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
      body: ListView(
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
          // Full Name
          ListTile(
            leading: const Icon(Icons.person),
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
          // Email Verification Status
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email Verification'),
            trailing: user.emailVerified
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.cancel, color: Colors.red),
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
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Account',
                style: TextStyle(color: Colors.red)),
            onTap: () {
              // TODO: Show confirmation dialog and delete account
            },
          ),
        ],
      ),
    );
  }
}