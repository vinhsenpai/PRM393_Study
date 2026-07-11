import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/auth_provider.dart';





class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isLoading = false;
  bool _isChecking = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.email_outlined,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Please verify your email address',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'We have sent a verification email to your inbox. '
                  'Please check your email and click the verification link to continue.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _resendVerificationEmail,
              icon: _isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.refresh),
              label: _isLoading
                  ? const Text('Sending...')
                  : const Text('Resend Verification Email'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isChecking ? null : _checkVerificationStatus,
              icon: _isChecking
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: _isChecking
                  ? const Text('Checking...')
                  : const Text('Check Verification Status'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Optionally, allow user to go back to login
                Navigator.of(context).pop();
              },
              child: const Text('Go Back to Login'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email resent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send verification email: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkVerificationStatus() async {
    setState(() => _isChecking = true);
    try {
      final isVerified = await context.read<AuthProvider>().isEmailVerified();
      if (!mounted) return;

      if (isVerified) {
        // Update Firestore to set emailVerified to true
        await _updateEmailVerifiedInFirestore();
        
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified successfully!')),
        );

        // Navigate to appropriate home screen based on role
        final authProvider = context.read<AuthProvider>();
        if (authProvider.isAdmin) {
          Navigator.of(context).pushReplacementNamed('/admin');
        } else if (authProvider.isSeller) {
          Navigator.of(context).pushReplacementNamed('/seller');
        } else {
          Navigator.of(context).pushReplacementNamed('/buyer');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email not yet verified. Please check your inbox.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking verification status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _updateEmailVerifiedInFirestore() async {
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.currentUser?.id;
    if (uid == null) return;

    final firestore = authProvider.firestore;
    final userRef = firestore.collection('users').doc(uid);




    await userRef.update({
      'emailVerified': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}