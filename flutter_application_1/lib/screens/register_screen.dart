import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../utils/error_utils.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserRole _selectedRole = UserRole.buyer;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
               validator: (value) =>
                     value!.isEmpty ? 'Please enter your name' : null,
               ),
               const SizedBox(height: 16),
               TextFormField(
                 controller: _emailController,
                 decoration: const InputDecoration(
                   labelText: 'Email',
                   border: OutlineInputBorder(),
                   prefixIcon: Icon(Icons.email_outlined),
                 ),
                 keyboardType: TextInputType.emailAddress,
                 validator: (value) {
                   if (value == null || value.isEmpty) {
                     return 'Please enter your email';
                   }
                   // Simple email regex pattern
                   final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                   if (!emailRegExp.hasMatch(value)) {
                     return 'Please enter a valid email';
                   }
                   return null;
                 },
               ),
               const SizedBox(height: 16),
               TextFormField(
                 controller: _passwordController,
                 obscureText: true,
                 decoration: const InputDecoration(
                   labelText: 'Password',
                   border: OutlineInputBorder(),
                   prefixIcon: Icon(Icons.lock_outline),
                 ),
                 validator: (value) {
                   if (value == null || value.isEmpty) {
                     return 'Please enter your password';
                   }
                   if (value.length < 6) {
                     return 'Password must be at least 6 characters';
                   }
                   // Optional: Add stronger password validation
                   // final hasUpperCase = RegExp(r'[A-Z]').hasMatch(value);
                   // final hasLowerCase = RegExp(r'[a-z]').hasMatch(value);
                   // final hasDigits = RegExp(r'[0-9]').hasMatch(value);
                   // final hasSpecialChars = RegExp(r'[!@#\$&*~]').hasMatch(value);
                   // if (!hasUpperCase || !hasLowerCase || !hasDigits || !hasSpecialChars) {
                   //   return 'Password must contain uppercase, lowercase, number and special character';
                   // }
                   return null;
                 },
               ),
               const SizedBox(height: 16),
               TextFormField(
                 controller: _confirmPasswordController,
                 obscureText: true,
                 decoration: const InputDecoration(
                   labelText: 'Confirm Password',
                   border: OutlineInputBorder(),
                   prefixIcon: Icon(Icons.lock_reset_outlined),
                 ),
                 validator: (value) {
                   if (value == null || value.isEmpty) {
                     return 'Please confirm your password';
                   }
                   if (value != _passwordController.text) {
                     return 'Passwords do not match';
                   }
                   return null;
                 },
               ),
              const SizedBox(height: 24),
              const Text(
                'I want to be a:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SegmentedButton<UserRole>(
                segments: const [
                  ButtonSegment(
                    value: UserRole.buyer,
                    label: Text('Buyer'),
                    icon: Icon(Icons.shopping_bag_outlined),
                  ),
                  ButtonSegment(
                    value: UserRole.seller,
                    label: Text('Seller'),
                    icon: Icon(Icons.storefront),
                  ),
                ],
                selected: {_selectedRole},
                onSelectionChanged: (Set<UserRole> newSelection) {
                  setState(() => _selectedRole = newSelection.first);
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Register the user
      await context.read<AuthProvider>().register(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
        _selectedRole,
      );
      
      if (!mounted) return;

      // Send verification email while still logged in
      bool emailSent = false;
      String? emailError;
      try {
        await context.read<AuthProvider>().sendEmailVerification();
        emailSent = true;
      } catch (e) {
        emailError = e.toString();
      }

      // Log out immediately so main.dart doesn't transition to the home shell with an unverified session
      if (!mounted) return;
      await context.read<AuthProvider>().logout();
      
      if (!mounted) return;

      if (emailSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Verification email sent. Please check your inbox.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration successful! But verification email failed: $emailError')),
        );
      }

      Navigator.of(context).pop(); // Go back to login screen
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AuthErrorUtils.parseAuthErrorMessage(e))));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}