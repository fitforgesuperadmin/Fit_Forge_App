import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class S21SongRequestScreen extends StatefulWidget {
  const S21SongRequestScreen({Key? key}) : super(key: key);

  @override
  State<S21SongRequestScreen> createState() => _S21SongRequestScreenState();
}

class _S21SongRequestScreenState extends State<S21SongRequestScreen> {
  final _songNameController = TextEditingController();
  final _songUrlController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _songNameController.dispose();
    _songUrlController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    setState(() {
      _errorMessage = null;
    });

    final songName = _songNameController.text.trim();
    final songUrl = _songUrlController.text.trim();

    if (songName.isEmpty) {
      setState(() {
        _errorMessage = 'Song Name is required.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'User not authenticated.';
          });
        }
        return;
      }

      final response = await http.post(
        Uri.parse('https://gymos-backend-production.up.railway.app/api/app/song-requests'),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'songName': songName,
          'songUrl': songUrl,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _songNameController.clear();
        _songUrlController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Song request submitted!')),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to submit request. Please try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'A network error occurred.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
          onPressed: () => context.pop(),
        ),
        title: Text('SONG REQUEST', style: AppTextStyles.labelAllcaps),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submit a Request',
                  style: AppTextStyles.h2,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your song will be added to the live requests queue on the admin dashboard.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 32),
                
                Text('SONG NAME *', style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
                const SizedBox(height: 8),
                CustomTextField(
                  hintText: 'e.g. Eye of the Tiger',
                  controller: _songNameController,
                ),
                
                const SizedBox(height: 24),
                Text('SONG URL (OPTIONAL)', style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
                const SizedBox(height: 8),
                CustomTextField(
                  hintText: 'e.g. Spotify or YouTube link',
                  controller: _songUrlController,
                  keyboardType: TextInputType.url,
                ),
                
                if (_errorMessage != null) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 32),
                PrimaryButton(
                  text: 'Submit Request',
                  isLoading: _isLoading,
                  onPressed: _submitRequest,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
