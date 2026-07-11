import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

class EmailVerificationRequiredScreen extends StatefulWidget {
  const EmailVerificationRequiredScreen({super.key});

  @override
  State<EmailVerificationRequiredScreen> createState() => _EmailVerificationRequiredScreenState();
}

class _EmailVerificationRequiredScreenState extends State<EmailVerificationRequiredScreen> {
  bool _isResending = false;
  bool _isChecking = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(authProvider),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
              'Please check your email and click the verification link, then return here to check your status.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isChecking ? null : () => _checkVerificationStatus(authProvider),
              icon: _isChecking
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: _isChecking
                  ? const Text('Checking Status...')
                  : const Text('Check Verification Status'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isResending ? null : () => _resendVerificationEmail(authProvider),
              icon: _isResending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: _isResending
                  ? const Text('Resending...')
                  : const Text('Resend Verification Email'),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => _handleLogout(authProvider),
              child: const Text('Go Back to Login'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkVerificationStatus(AuthProvider auth) async {
    setState(() => _isChecking = true);
    try {
      final isVerified = await auth.isEmailVerified();
      if (!mounted) return;

      if (isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified successfully! Welcome.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email not yet verified. Please check your inbox and spam folder.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resendVerificationEmail(AuthProvider auth) async {
    setState(() => _isResending = true);
    try {
      await auth.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email resent!')),
        );
      }
    } on fb.FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'too-many-requests' => 'Too many requests. Please wait a while and try again.',
        'invalid-email' => 'Invalid email.',
        'user-not-found' => 'User not found.',
        _ => e.message ?? 'Failed to resend verification email.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _handleLogout(AuthProvider auth) async {
    try {
      await auth.logout();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }
}