import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/cloudinary_service.dart';


class EditProfileScreen extends StatefulWidget {
  final String userId;

  const EditProfileScreen({super.key, required this.userId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _isSaving = false;
  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user != null) {
      _nameController.text = user.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      _pickedImage = picked;
    });
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên đầy đủ')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final auth = context.read<AuthProvider>();
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User không tồn tại')),
        );
        return;
      }

      String? photoUrl;
      if (_pickedImage != null) {
        photoUrl = await CloudinaryService.uploadImage(_pickedImage!);
      }

      await auth.firestore.collection('users').doc(widget.userId).update({
        'name': name,
        'photoUrl': ?photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // refresh user
      final doc = await auth.firestore.collection('users').doc(widget.userId).get();
      if (doc.exists) {
        auth.refreshCurrentUser(User.fromDocument(widget.userId, doc.data()!));
      }


      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: user == null
          ? const Center(child: Text('User not found'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _pickedImage != null
                            ? (kIsWeb
                                ? NetworkImage(_pickedImage!.path)
                                : FileImage(File(_pickedImage!.path))) as ImageProvider
                            : (user.photoUrl?.isNotEmpty ?? false)
                                ? NetworkImage(user.photoUrl!)
                                : null,
                        child: _pickedImage == null && (user.photoUrl?.isNotEmpty ?? false) == false
                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                            : null,
                      ),
                      IconButton(
                        onPressed: _isSaving ? null : _pickImage,
                        icon: const CircleAvatar(
                          radius: 20,
                          child: Icon(Icons.camera_alt, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _onSave,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label: Text(_isSaving ? 'Saving...' : 'Save'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Email: ${user.email}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

