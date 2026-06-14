import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;



class EmailVerificationRequiredScreen extends StatelessWidget {

  const EmailVerificationRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
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
              onPressed: () async {
                try {
                  await context.read<AuthProvider>().sendEmailVerification();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verification email resent!')),
                  );
                } on fb.FirebaseAuthException catch (e) {
                  if (!context.mounted) return;

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
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Resend Verification Email'),
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
}