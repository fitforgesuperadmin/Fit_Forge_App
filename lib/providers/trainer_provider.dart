import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class TrainerProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _assignedUsers = [];
  int _count = 0;
  bool _isLoading = false;
  String _error = '';
  Map<String, dynamic>? _selectedUserDetail;

  List<Map<String, dynamic>> get assignedUsers => _assignedUsers;
  int get count => _count;
  bool get isLoading => _isLoading;
  String get error => _error;
  Map<String, dynamic>? get selectedUserDetail => _selectedUserDetail;

  Future<void> fetchAssignedUsers() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      _error = 'Session expired';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://gymos-backend-production.up.railway.app/api/app/trainer/assigned-users'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _count = data['count'] ?? 0;
          _assignedUsers = List<Map<String, dynamic>>.from(data['assignedUsers'] ?? []);
        } else {
          _error = 'Failed to load assigned users.';
        }
      } else {
        _error = 'Error loading users (Status: ${response.statusCode})';
      }
    } catch (e) {
      _error = 'Network error or unable to connect.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserDetail(int gymUserId) async {
    _isLoading = true;
    _error = '';
    _selectedUserDetail = null;
    notifyListeners();

    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      _error = 'Session expired';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://gymos-backend-production.up.railway.app/api/app/trainer/assigned-users/$gymUserId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _selectedUserDetail = data;
        } else {
          _error = 'Failed to load user detail.';
        }
      } else if (response.statusCode == 404) {
         _error = 'User not found or not assigned to you.';
      } else {
        _error = 'Error loading user detail (Status: ${response.statusCode})';
      }
    } catch (e) {
      _error = 'Network error or unable to connect.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
