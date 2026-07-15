import 'package:flutter/material.dart';
import '../models/account.dart';
import '../screens/account_detail_screen.dart';
import '../theme/app_theme.dart';

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _gameName = '';
  double _price = 0;
  String _description = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Add New Listing'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Title',
                ),
                style: const TextStyle(color: Color(0xFFF8FAFC)),
                validator: (v) => v!.trim().isEmpty ? 'Enter title' : null,
                onSaved: (v) => _title = v!.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Game Name',
                ),
                style: const TextStyle(color: Color(0xFFF8FAFC)),
                validator: (v) => v!.trim().isEmpty ? 'Enter game name' : null,
                onSaved: (v) => _gameName = v!.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Price',
                ),
                style: const TextStyle(color: Color(0xFFF8FAFC)),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    double.tryParse(v!) == null ? 'Enter valid price' : null,
                onSaved: (v) => _price = double.parse(v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                style: const TextStyle(color: Color(0xFFF8FAFC)),
                maxLines: 4,
                onSaved: (v) => _description = v!.trim(),
              ),
              const SizedBox(height: 24),
              _buildImageUploadSection(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      
                      final account = GameAccount(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: _title,
                        gameName: _gameName,
                        price: _price,
                        status: AccountStatus.available,
                        description: _description,
                        sellerName: 'Me',
                        imageUrls: const ['https://picsum.photos/id/1/800/600'],
                        specs: const {'Level': '1', 'Rank': 'Unranked'},
                        createdAt: DateTime.now(),
                      );
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Listing submitted successfully!'),
                          duration: Duration(seconds: 2),
                        ),
                      );

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AccountDetailScreen(account: account),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Submit for Review'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Images',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF8FAFC)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            InkWell(
              onTap: () {
                // Image picker logic placeholder
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Icon(
                  Icons.add_a_photo_outlined,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Add at least one clear image of the account status and inventory.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
