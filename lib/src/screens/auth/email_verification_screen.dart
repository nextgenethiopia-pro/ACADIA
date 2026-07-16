import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/blocs/auth/auth_bloc.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/widgets/common/gradient_button.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  late Timer _verificationTimer;
  late Timer _resendTimer;
  int _resendCounter = 60;
  bool _canResend = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _startVerificationTimer();
  }

  @override
  void dispose() {
    _verificationTimer.cancel();
    _resendTimer.cancel();
    super.dispose();
  }

  void _startVerificationTimer() {
    // Auto-check verification status every 5 seconds
    _verificationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isChecking) {
        _checkVerification();
      }
    });
  }

  void _startResendTimer() {
    if (!mounted) return;
    setState(() {
      _canResend = false;
      _resendCounter = 60;
    });
    
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _resendCounter > 0) {
        setState(() => _resendCounter--);
      } else if (mounted) {
        timer.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  void _resendEmail() {
    if (_canResend && !_isChecking) {
      final authState = context.read<AuthBloc>().state;
      final email = authState is AuthEmailVerificationRequired 
          ? authState.user.email ?? '' 
          : '';
      
      if (email.isNotEmpty) {
        context.read<AuthBloc>().add(AuthResendEmailVerification(email: email));
        _startResendTimer(); // Restart the timer
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email resent! Please check your inbox.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to resend. Please logout and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _checkVerification() {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    context.read<AuthBloc>().add(const AuthCheckRequested());
    // Reset checking flag after a delay to prevent rapid successive checks
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    });
  }

  void _logout() {
    _verificationTimer.cancel();
    _resendTimer.cancel();
    context.read<AuthBloc>().add(const AuthSignOutRequested());
    context.go('/welcome');
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

          if (state is Authenticated) {
            // Stop timers when navigating away
            _verificationTimer.cancel();
            _resendTimer.cancel();
            context.pushReplacement('/profile-setup-complete');
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
          final isLoading = state is AuthLoading || _isChecking;
          final userEmail = state is AuthEmailVerificationRequired
              ? state.user.email ?? 'your email'
              : 'your email';

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: size.height * 0.05,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email Icon Animation
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.email_outlined,
                        size: 80,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Verify Your Email',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Instructions
                  Text(
                    'We\'ve sent a verification email to:',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  // Email Display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            userEmail,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Please check your inbox and spam folder for the verification email.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const SizedBox(width: 28),
                            Expanded(
                              child: Text(
                                'If you don\'t see it within a few minutes, click "Resend" below.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Verify Button
                  GradientButton(
                    text: 'I Have Verified',
                    onPressed: isLoading ? () {} : _checkVerification,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 20),

                  // Resend Button
                  Container(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _canResend && !isLoading ? _resendEmail : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: _canResend ? AppColors.primary : Colors.grey,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _canResend
                            ? 'Resend Verification Email'
                            : 'Resend in $_resendCounter seconds',
                        style: TextStyle(
                          color: _canResend ? AppColors.primary : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Logout Button
                  OutlinedButton.icon(
                    onPressed: isLoading ? null : _logout,
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text('Use Different Email'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}