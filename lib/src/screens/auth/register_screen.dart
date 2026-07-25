import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:acadia/src/core/blocs/auth/auth_bloc.dart';
import 'package:acadia/src/core/constants/colors.dart';
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
  final _highSchoolNameController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _isLoadingAcademicInfo = true;
  bool _isNormalizingPhone = false;

  String _academicPath = '';
  String _academicInfo = '';
  String _academicSubInfo = '';
  bool _isHighSchool = false;

  @override
  void initState() {
    super.initState();
    _loadAcademicInfo();
    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.removeListener(_onPhoneChanged);
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _highSchoolNameController.dispose();
    super.dispose();
  }

  Future<void> _loadAcademicInfo() async {
    final prefs = await SharedPreferences.getInstance();

    final academicPath = prefs.getString('academic_path') ??
        prefs.getString('academic_level') ??
        '';
    final grade = prefs.getString('selected_grade') ?? prefs.getString('grade');
    final stream =
        prefs.getString('selected_stream') ?? prefs.getString('stream');
    final generation =
        prefs.getString('selected_generation') ?? prefs.getString('generation');
    final university =
        prefs.getString('selected_university') ?? prefs.getString('university');
    final universityName = prefs.getString('university_name');
    final semester = prefs.getString('semester');
    final selectedYear = prefs.getString('selected_year');
    final selectedTrack = prefs.getString('selected_track');

    String pathLabel = '';
    String info = '';
    String subInfo = '';
    bool isHighSchool = false;

    final normalizedPath = academicPath.toUpperCase();

    if (normalizedPath.contains('UNIVERSITY')) {
      pathLabel = 'UNIVERSITY';
      final displayUniversity =
          universityName ?? _extractUniversityName(university);

      if (generation != null && generation.isNotEmpty) {
        info = generation;
      } else {
        info = 'University Student';
      }

      final details = <String>[];
      if (displayUniversity.isNotEmpty) {
        details.add(displayUniversity);
      }
      if (selectedYear != null && selectedYear.isNotEmpty) {
        details.add(_formatYear(selectedYear));
      }
      if (semester != null && semester.isNotEmpty) {
        details.add('Semester $semester');
      }
      if (selectedTrack != null && selectedTrack.isNotEmpty) {
        details.add(_formatTrack(selectedTrack));
      }
      subInfo = details.join(' • ');
    } else {
      pathLabel = 'HIGH SCHOOL';
      isHighSchool = true;

      if (grade != null && grade.isNotEmpty) {
        info = 'Grade $grade';
      } else {
        info = 'High School Student';
      }

      if (grade == '11' || grade == '12') {
        final streamLabel = _formatHighSchoolStream(stream);
        if (streamLabel.isNotEmpty) {
          subInfo = streamLabel;
        }
      } else {
        subInfo = 'General Program';
      }
    }

    if (!mounted) return;

    setState(() {
      _academicPath = pathLabel;
      _academicInfo = info;
      _academicSubInfo = subInfo;
      _isHighSchool = isHighSchool;
      _isLoadingAcademicInfo = false;
    });
  }

  void _onPhoneChanged() {
    if (_isNormalizingPhone) return;

    final original = _phoneController.text;
    final normalized = _normalizePhoneInput(original);

    if (original == normalized) return;

    _isNormalizingPhone = true;
    _phoneController.value = TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
    _isNormalizingPhone = false;
  }

  String _normalizePhoneInput(String input) {
    var text = input.trim();

    if (text.startsWith('09')) {
      return '9${text.substring(2)}';
    }

    if (text.startsWith('0') && text.length > 1) {
      final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.startsWith('09')) {
        return digitsOnly.substring(1);
      }
    }

    if (text.startsWith('+2510')) {
      return '+251${text.substring(5)}';
    }

    if (text.startsWith('2510')) {
      return '251${text.substring(4)}';
    }

    return text;
  }

  String _sanitizePhone(String input) {
    return input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  String _formatHighSchoolStream(String? stream) {
    switch ((stream ?? '').toLowerCase()) {
      case 'natural':
        return 'Natural Science';
      case 'social':
        return 'Social Science';
      case 'general':
        return 'General Program';
      default:
        return '';
    }
  }

  String _formatYear(String value) {
    switch (value.toLowerCase()) {
      case 'freshman':
        return 'Freshman';
      case 'senior':
        return 'Senior';
      default:
        return value
            .split('_')
            .map(
              (part) => part.isEmpty
                  ? part
                  : '${part[0].toUpperCase()}${part.substring(1)}',
            )
            .join(' ');
    }
  }

  String _formatTrack(String value) {
    return value
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  String _extractUniversityName(String? fullValue) {
    if (fullValue == null || fullValue.trim().isEmpty) return '';
    final parts = fullValue.split(' - ');
    if (parts.length > 1) {
      return parts.sublist(1).join(' - ').trim();
    }
    return fullValue.trim();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

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
    final academicPath = prefs.getString('academic_path') ??
        (academicLevel == 'university' ? 'UNIVERSITY' : 'HIGH SCHOOL');

    if (academicLevel == 'high_school') academicLevel = 'HIGH SCHOOL';
    if (academicLevel == 'university') academicLevel = 'UNIVERSITY';

    final grade = prefs.getString('selected_grade') ?? prefs.getString('grade');
    final stream =
        prefs.getString('selected_stream') ?? prefs.getString('stream');
    final generation =
        prefs.getString('selected_generation') ?? prefs.getString('generation');
    final university =
        prefs.getString('selected_university') ?? prefs.getString('university');
    final universityYear = prefs.getString('selected_year');
    final semester = prefs.getString('semester');
    final track = prefs.getString('selected_track');

    final normalizedPhone = _sanitizePhone(_phoneController.text.trim());

    if (!mounted) return;

    context.read<AuthBloc>().add(
          AuthSignUpRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            phoneNumber: normalizedPhone,
            academicPath: academicLevel ?? academicPath,
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

  String? _validateFullName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please enter your full name';
    if (text.length < 3) return 'Name must be at least 3 characters';
    return null;
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(text)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'Please enter your phone number';

    final phone = _sanitizePhone(raw);

    if (phone.startsWith('+251')) {
      final nationalNumber = phone.substring(4);
      if (!RegExp(r'^9\d{8}$').hasMatch(nationalNumber)) {
        return 'Use +251 followed by 9 digits';
      }
      return null;
    }

    if (phone.startsWith('251')) {
      final nationalNumber = phone.substring(3);
      if (!RegExp(r'^9\d{8}$').hasMatch(nationalNumber)) {
        return 'Use 251 followed by 9 digits';
      }
      return null;
    }

    if (phone.startsWith('09')) {
      if (!RegExp(r'^09\d{8}$').hasMatch(phone)) {
        return 'Use 09 followed by 8 digits';
      }
      return null;
    }

    if (phone.startsWith('9')) {
      if (!RegExp(r'^9\d{8}$').hasMatch(phone)) {
        return 'Use 9 followed by 8 digits';
      }
      return null;
    }

    return 'Phone must start with +251, 251, 09, or 9';
  }

  String? _validateHighSchoolName(String? value) {
    if (!_isHighSchool) return null;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please enter your high school name';
    if (text.length < 2) return 'High school name is too short';
    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Please enter your password';
    if (text.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
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

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    String? helperText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: isLoading ? null : () => context.pop(),
                            icon: const Icon(Icons.arrow_back),
                          ),
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withAlpha(((255 * 0.1)).toInt()),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logos/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.school,
                                size: 28,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Create Account',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete your registration and continue your ACADIA learning journey.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_isLoadingAcademicInfo)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(((255 * 0.06)).toInt()),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text('Loading your academic selection...'),
                            ),
                          ],
                        ),
                      )
                    else
                      _buildAcademicSummaryCard(theme),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _fullNameController,
                      enabled: !isLoading,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        icon: Icons.person_outline,
                      ),
                      validator: _validateFullName,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      enabled: !isLoading,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        label: 'Email Address',
                        hint: 'Enter your email',
                        icon: Icons.email_outlined,
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      enabled: !isLoading,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(
                        label: 'Phone Number',
                        hint: '+251 9XX XXX XXX or 09XXXXXXXX',
                        icon: Icons.phone_outlined,
                        helperText:
                            'Leading 0 is handled automatically for Ethiopian mobile numbers',
                      ),
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 16),
                    if (_isHighSchool)
                      Column(
                        children: [
                          TextFormField(
                            controller: _highSchoolNameController,
                            enabled: !isLoading,
                            textCapitalization: TextCapitalization.words,
                            decoration: _inputDecoration(
                              label: 'High School Name',
                              hint: 'Enter your high school name',
                              icon: Icons.apartment_outlined,
                            ),
                            validator: _validateHighSchoolName,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    TextFormField(
                      controller: _passwordController,
                      enabled: !isLoading,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration(
                        label: 'Password',
                        hint: 'Create a password',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      enabled: !isLoading,
                      obscureText: _obscureConfirmPassword,
                      decoration: _inputDecoration(
                        label: 'Confirm Password',
                        hint: 'Re-enter your password',
                        icon: Icons.lock_reset_outlined,
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      validator: _validateConfirmPassword,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _agreedToTerms,
                                activeColor: AppColors.primary,
                                onChanged: isLoading
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _agreedToTerms = value ?? false;
                                        });
                                      },
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Wrap(
                                    children: [
                                      const Text('I agree to the '),
                                      GestureDetector(
                                        onTap:
                                            isLoading ? null : _showTermsDialog,
                                        child: const Text(
                                          'Terms of Service',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const Text(' and '),
                                      GestureDetector(
                                        onTap: isLoading
                                            ? null
                                            : _showPrivacyDialog,
                                        child: const Text(
                                          'Privacy Policy',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const Text('.'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      text: 'CREATE ACCOUNT',
                      onPressed: isLoading ? () {} : _register,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already a member? ',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        TextButton(
                          onPressed:
                              isLoading ? null : () => context.push('/login'),
                          child: const Text(
                            'LOG IN',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAcademicSummaryCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(((255 * 0.06)).toInt()),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withAlpha(((255 * 0.14)).toInt())),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(((255 * 0.12)).toInt()),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _academicPath == 'UNIVERSITY'
                  ? Icons.account_balance_outlined
                  : Icons.school_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Academic Path',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _academicPath.isEmpty ? 'Not selected' : _academicPath,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _academicInfo.isEmpty
                      ? 'Academic details unavailable'
                      : _academicInfo,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                if (_academicSubInfo.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _academicSubInfo,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(((255 * 0.14)).toInt()),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.amber.withAlpha(((255 * 0.28)).toInt())),
                  ),
                  child: Text(
                    'This academic selection will be used for your account setup',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
