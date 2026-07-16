import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:acadia/src/widgets/common/gradient_button.dart';
import 'package:acadia/src/core/constants/colors.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _hasNetworkError = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasNetworkError = false;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;

      if (user == null || email == null) {
        throw Exception('No user logged in');
      }

      // Re-authenticate user before changing password (security requirement)
      final credential = EmailAuthProvider.credential(
        email: email,
        password: _currentPasswordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);
      
      // Change password after successful re-authentication
      await user.updatePassword(_newPasswordController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasNetworkError = true;
          _errorMessage = _getErrorMessage(e);
        });
        
        _showErrorSnackBar(_errorMessage!);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (errorString.contains('weak-password')) {
      return 'Password is too weak. Please choose a stronger password (min 6 characters).';
    } else if (errorString.contains('requires-recent-login')) {
      return 'For security, please log out and log back in to change your password.';
    } else if (errorString.contains('user-not-found') || errorString.contains('invalid-credential')) {
      return 'Current password is incorrect. Please try again.';
    } else if (errorString.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later.';
    } else {
      return 'Failed to change password. Please try again.';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _changePassword,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Change Password'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.blue[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'For security, you will need to re-enter your current password to confirm your identity.',
                        style: TextStyle(color: Colors.blue[700], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Current Password
              Text(
                'Current Password',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'Enter your current password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // New Password
              Text(
                'New Password',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'Enter new password (min 6 characters)',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  if (_currentPasswordController.text.isNotEmpty && 
                      value == _currentPasswordController.text) {
                    return 'New password must be different from current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              // Password strength indicator
              if (_newPasswordController.text.isNotEmpty)
                _buildPasswordStrengthIndicator(_newPasswordController.text),
              const SizedBox(height: 24),

              // Confirm New Password
              Text(
                'Confirm New Password',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'Confirm your new password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Update Button
              GradientButton(
                text: _isLoading ? 'UPDATING...' : 'UPDATE PASSWORD',
                isLoading: _isLoading,
                onPressed: _changePassword,
              ),
              
              const SizedBox(height: 16),
              
              // Security note
              Center(
                child: Text(
                  'Keep your password secure and never share it with anyone.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator(String password) {
    int strength = _getPasswordStrength(password);
    String strengthText;
    Color strengthColor;
    
    if (strength <= 2) {
      strengthText = 'Weak';
      strengthColor = Colors.red;
    } else if (strength <= 4) {
      strengthText = 'Medium';
      strengthColor = Colors.orange;
    } else {
      strengthText = 'Strong';
      strengthColor = Colors.green;
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: strength / 6,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              strengthText,
              style: TextStyle(color: strengthColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Password strength: ${_getPasswordFeedback(password)}',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  int _getPasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;
    return strength.clamp(0, 6);
  }

  String _getPasswordFeedback(String password) {
    if (password.length < 6) return 'Too short';
    if (!RegExp(r'[A-Z]').hasMatch(password)) return 'Add uppercase letters';
    if (!RegExp(r'[a-z]').hasMatch(password)) return 'Add lowercase letters';
    if (!RegExp(r'[0-9]').hasMatch(password)) return 'Add numbers';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) return 'Add special characters';
    return 'Good password';
  }
}