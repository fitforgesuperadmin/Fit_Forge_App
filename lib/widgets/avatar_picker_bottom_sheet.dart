import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../widgets/custom_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AvatarPickerBottomSheet extends StatefulWidget {
  final int? currentAvatarId;
  final Function(int) onAvatarSelected;

  const AvatarPickerBottomSheet({
    Key? key,
    this.currentAvatarId,
    required this.onAvatarSelected,
  }) : super(key: key);

  @override
  State<AvatarPickerBottomSheet> createState() => _AvatarPickerBottomSheetState();
}

class _AvatarPickerBottomSheetState extends State<AvatarPickerBottomSheet> {
  int? _selectedAvatarId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedAvatarId = widget.currentAvatarId;
  }

  Future<void> _saveAvatar() async {
    if (_selectedAvatarId == null) return;
    
    setState(() => _isLoading = true);

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await Supabase.instance.client.from('profiles').update({
          'avatar_id': _selectedAvatarId,
        }).eq('id', session.user.id);
        
        widget.onAvatarSelected(_selectedAvatarId!);
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update avatar. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('CHANGE AVATAR', style: AppTextStyles.h3),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    final avatarId = index + 1;
                    final isSelected = _selectedAvatarId == avatarId;
                    final imagePath = 'assets/avatars/avatar_${avatarId.toString().padLeft(2, '0')}.png';
                    
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatarId = avatarId),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryAccent : AppColors.border,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'SAVE CHANGES',
                isLoading: _isLoading,
                onPressed: _selectedAvatarId != null && _selectedAvatarId != widget.currentAvatarId
                    ? _saveAvatar
                    : null,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

void showAvatarPicker(BuildContext context, {int? currentAvatarId, required Function(int) onAvatarSelected}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AvatarPickerBottomSheet(
      currentAvatarId: currentAvatarId,
      onAvatarSelected: onAvatarSelected,
    ),
  );
}
