import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/blocs/auth/auth_bloc.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acadia/src/widgets/common/gradient_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  
  // Store academic info for display
  String _academicInfo = '';

  @override
  void initState() {
    super.initState();
    _loadAcademicInfo();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadAcademicInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('academic_path');
    final grade = prefs.getString('selected_grade');
    final stream = prefs.getString('selected_stream');
    final generation = prefs.getString('selected_generation');
    final university = prefs.getString('selected_university');
    final semester = prefs.getString('semester');

    String info = '';
    if (path == 'UNIVERSITY') {
      if (generation != null && university != null) {
        info = '$generation - $university';
        if (semester != null) info += ' - Semester $semester';
      } else {
        info = 'University Student';
      }
    } else if (grade != null) {
      if (grade == '11' || grade == '12') {
        info = 'Grade $grade - ${stream == 'natural' ? 'Natural Science' : 'Social Science'}';
      } else {
        info = 'Grade $grade';
      }
    }

    if (mounted) {
      setState(() => _academicInfo = info);
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (!_agreedToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please agree to the terms and conditions'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      var academicLevel = prefs.getString('academic_level');
      
      // Normalize academic level
      if (academicLevel == 'high_school') academicLevel = 'HIGH SCHOOL';
      if (academicLevel == 'university') academicLevel = 'UNIVERSITY';
      
      final grade = prefs.getString('selected_grade') ?? '9';
      final stream = prefs.getString('selected_stream') ?? 'natural';
      
      // University specific fields
      final generation = prefs.getString('selected_generation');
      final university = prefs.getString('selected_university');
      final universityYear = prefs.getString('selected_year');
      final semester = prefs.getString('semester');
      final track = prefs.getString('selected_track');

      if (!mounted) return;

      context.read<AuthBloc>().add(
            AuthSignUpRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              fullName: _fullNameController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
              academicPath: academicLevel ?? 'HIGH SCHOOL',
              grade: grade,
              stream: stream,
              generation: generation,
              university: university,
              universityYear: universityYear,
              semester: semester,
              track: track,
            ),
          );
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    // Remove any spaces, dashes, or plus signs
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-+]'), '');
    
    // Ethiopian phone validation
    if (cleanPhone.startsWith('251')) {
      if (cleanPhone.length != 12) {
        return 'Phone must be +251 followed by 9 digits';
      }
    } else if (cleanPhone.startsWith('09')) {
      if (cleanPhone.length != 10) {
        return 'Phone must be 09 followed by 8 digits';
      }
    } else {
      return 'Phone must start with +251 or 09';
    }
    return null;
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'By using ACADIA, you agree to:\n\n'
            '1. Provide accurate information\n'
            '2. Keep your account secure\n'
            '3. Respect intellectual property rights\n'
            '4. Not share your account with others\n'
            '5. Use the app for educational purposes only\n\n'
            'For full terms, please visit our website.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'We value your privacy:\n\n'
            '• Your data is stored securely\n'
            '• We never share your personal information\n'
            '• Your payment info is encrypted\n'
            '• You can request data deletion at any time\n\n'
            'For full policy, please visit our website.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (ModalRoute.of(context)?.isCurrent != true) return;

          if (state is AuthEmailVerificationRequired) {
            context.push('/verify-email');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: isLoading ? null : () => context.pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      'Create Account',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join ACADIA and start your learning journey',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Academic Path Summary Card
                    if (_academicInfo.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.school, color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selected Academic Path',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    _academicInfo,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.check_circle, color: Colors.green, size: 16),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Full Name Field
                    TextFormField(
                      controller: _fullNameController,
                      enabled: !isLoading,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        if (value.length < 3) {
                          return 'Name must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'Enter your email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone Number Field
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '+251 9XX XXX XXX',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                        helperText: 'Ethiopian phone numbers only',
                        helperStyle: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Minimum 8 characters',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        // Check for at least one number
                        if (!value.contains(RegExp(r'[0-9]'))) {
                          return 'Password must contain at least one number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        hintText: 'Re-enter your password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
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
                    const SizedBox(height: 16),

                    // Terms Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreedToTerms,
                            onChanged: isLoading
                                ? null
                                : (value) {
                                    setState(() {
                                      _agreedToTerms = value ?? false;
                                    });
                                  },
                            activeColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _agreedToTerms = !_agreedToTerms;
                                    });
                                  },
                            child: Text.rich(
                              TextSpan(
                                text: 'I agree to the ',
                                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                children: [
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: _showTermsDialog,
                                      child: const Text(
                                        'Terms of Service',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const TextSpan(text: ' and '),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: _showPrivacyDialog,
                                      child: const Text(
                                        'Privacy Policy',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Register Button
                    GradientButton(
                      text: 'Create Account',
                      onPressed: isLoading ? () {} : _register,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 20),

                    // Or divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => context.push('/login'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                          child: const Text('Sign In'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}