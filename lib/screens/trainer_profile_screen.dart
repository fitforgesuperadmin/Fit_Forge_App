import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../services/hive_service.dart';

class TrainerProfileScreen extends StatefulWidget {
  const TrainerProfileScreen({Key? key}) : super(key: key);

  @override
  State<TrainerProfileScreen> createState() => _TrainerProfileScreenState();
}

class _TrainerProfileScreenState extends State<TrainerProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  File? _selectedImage;
  bool _isEditing = false;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  String _currentName = '';
  String? _profilePictureUrl; // Will be presigned URL from backend

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    _currentName = HiveService.userProfileBox.get('name', defaultValue: 'Trainer');
    _nameController.text = _currentName;
    
    // In part 2, this will be fetched from the backend (a presigned URL).
    // For part 1, we just mock the URL or leave it null.
    final mockKey = HiveService.userProfileBox.get('profile_picture_key');
    if (mockKey != null) {
      // _profilePictureUrl = 'https://mock-url.com/image.jpg'; // If we had a real mock
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Replace with real backend upload to R2 and profile update
      // Mocked API call for now (Part 1)
      await Future.delayed(const Duration(seconds: 2));

      await HiveService.userProfileBox.put('name', name);
      setState(() {
        _currentName = name;
        _isEditing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    try {
      // Clear local Hive cache for trainer
      await HiveService.userProfileBox.clear();
      await HiveService.setGymLinked(false);
      await HiveService.setUserRole('member');
      
      // Real Supabase sign out
      await Supabase.instance.client.auth.signOut();
      
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sign out')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () {
            if (_isEditing) {
              setState(() {
                _isEditing = false;
                _nameController.text = _currentName;
                _selectedImage = null;
              });
            } else {
              context.pop();
            }
          },
        ),
        title: Text(_isEditing ? 'EDIT PROFILE' : 'PROFILE', style: AppTextStyles.labelAllcaps),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primaryText),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _isEditing ? _pickImage : null,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.elevatedSurface,
                        border: Border.all(
                          color: _isEditing ? AppColors.primaryAccent : AppColors.border, 
                          width: 2
                        ),
                      ),
                      child: _buildAvatarImage(),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.strongAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              if (_isEditing) ...[
                CustomTextField(
                  hintText: 'Full Name',
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 48),
                PrimaryButton(
                  text: 'SAVE CHANGES',
                  isLoading: _isLoading,
                  onPressed: _saveProfile,
                ),
              ] else ...[
                Text(_currentName, style: AppTextStyles.h2),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.elevatedSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text('Trainer', style: AppTextStyles.bodySmall),
                ),
                const SizedBox(height: 64),
                SecondaryButton(
                  text: 'SIGN OUT',
                  onPressed: _logout,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarImage() {
    if (_selectedImage != null) {
      return ClipOval(child: Image.file(_selectedImage!, fit: BoxFit.cover));
    } else if (_profilePictureUrl != null) {
      return ClipOval(child: Image.network(_profilePictureUrl!, fit: BoxFit.cover));
    } else {
      return const Icon(Icons.person, color: AppColors.primaryText, size: 50);
    }
  }
}
