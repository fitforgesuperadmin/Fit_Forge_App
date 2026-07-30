import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/atmospheric_background.dart';
import '../services/hive_service.dart';

class S16bTrainerProfileSetupScreen extends StatefulWidget {
  const S16bTrainerProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<S16bTrainerProfileSetupScreen> createState() => _S16bTrainerProfileSetupScreenState();
}

class _S16bTrainerProfileSetupScreenState extends State<S16bTrainerProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final currentName = HiveService.userProfileBox.get('name');
    if (currentName != null) {
      _nameController.text = currentName;
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

  Future<void> _submitProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a profile picture')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Replace with real backend upload to R2 and profile update
      // Mocked API call for now (Part 1)
      await Future.delayed(const Duration(seconds: 2));

      await HiveService.userProfileBox.put('name', name);
      // We don't save the image locally permanently yet, since it will be a network image later.
      // But we will save a mock key just to have something.
      await HiveService.userProfileBox.put('profile_picture_key', 'mock_key');
      
      if (mounted) {
        context.go('/trainer-dashboard');
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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text('TRAINER PROFILE', style: AppTextStyles.labelAllcaps),
        ),
        body: Stack(
          children: [
            const AtmosphericBackground(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),
                    Text('Complete Your Profile', style: AppTextStyles.h2, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Text(
                      'Please provide your full name and a profile picture before continuing.',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.elevatedSurface,
                          border: Border.all(
                            color: _selectedImage != null ? AppColors.primaryAccent : AppColors.border,
                            width: 2,
                          ),
                        ),
                        child: _selectedImage != null
                            ? ClipOval(
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, color: AppColors.primaryText, size: 32),
                                  SizedBox(height: 8),
                                  Text('Add Photo', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    CustomTextField(
                      hintText: 'Full Name',
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const Spacer(),
                    PrimaryButton(
                      text: 'CONTINUE TO DASHBOARD',
                      isLoading: _isLoading,
                      onPressed: _submitProfile,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
