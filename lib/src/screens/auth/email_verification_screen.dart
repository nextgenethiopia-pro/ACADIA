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
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _verificationTimer;
  Timer? _resendTimer;
  int _resendCounter = 60;
  bool _canResend = false;
  bool _isChecking = false;
  bool _isResending = false;

  final PageController _guidePageController = PageController();
  int _currentGuidePage = 0;

  static const List<_VerificationGuideStep> _guideSteps = [
    _VerificationGuideStep(
      imagePath: 'assets/images/email1.jpg',
      title: 'Open your inbox',
      description:
          'Check the email account you used to create your ACADIA account. The verification message may take a minute to arrive.',
    ),
    _VerificationGuideStep(
      imagePath: 'assets/images/email2.jpg',
      title: 'Look in Spam or Promotions',
      description:
          'If you do not see the email in your main inbox, check Spam, Junk, or Promotions folders and mark it as safe.',
    ),
    _VerificationGuideStep(
      imagePath: 'assets/images/email3.jpg',
      title: 'Tap the verification link',
      description:
          'Open the email and tap the verification link, then return to ACADIA. The app checks automatically every few seconds.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _startVerificationTimer();
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _resendTimer?.cancel();
    _guidePageController.dispose();
    super.dispose();
  }

  void _startVerificationTimer() {
    _verificationTimer?.cancel();
    _verificationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isChecking && mounted) {
        _checkVerification(showLoader: false);
      }
    });
  }

  void _startResendTimer() {
    _resendTimer?.cancel();

    if (!mounted) return;

    setState(() {
      _canResend = false;
      _resendCounter = 60;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendCounter > 0) {
        setState(() => _resendCounter--);
      } else {
        timer.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  Future<void> _checkVerification({bool showLoader = true}) async {
    if (_isChecking) return;

    if (showLoader && mounted) {
      setState(() => _isChecking = true);
    } else {
      _isChecking = true;
    }

    context.read<AuthBloc>().add(const AuthCheckRequested());

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _isChecking = false);
    });
  }

  Future<void> _resendEmail() async {
    if (!_canResend || _isChecking || _isResending) return;

    final authState = context.read<AuthBloc>().state;
    final email = authState is AuthEmailVerificationRequired
        ? authState.user.email ?? ''
        : '';

    if (email.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to resend right now. Try signing in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isResending = true;
      _canResend = false;
    });

    context.read<AuthBloc>().add(AuthResendEmailVerification(email: email));

    _startResendTimer();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Verification email requested again. Please check your inbox and spam folder.',
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _isResending = false);
    });
  }

  void _logout() {
    _verificationTimer?.cancel();
    _resendTimer?.cancel();
    context.read<AuthBloc>().add(const AuthSignOutRequested());
    context.go('/welcome');
  }

  Widget _buildGuideCard(_VerificationGuideStep step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withAlpha(((255 * 0.12)).toInt())),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                step.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.primary.withAlpha(((255 * 0.06)).toInt()),
                    child: const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 56,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          step.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          step.description,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            height: 1.45,
          ),
        ),
      ],
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

          if (state is Authenticated) {
            _verificationTimer?.cancel();
            _resendTimer?.cancel();
            context.pushReplacement('/profile-setup-complete');
          } else if (state is AuthError) {
            setState(() {
              _isChecking = false;
              _isResending = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is AuthVerificationEmailResent) {
            if (!mounted) return;
            setState(() => _isResending = false);
          }
        },
        builder: (context, state) {
          final isBusy = state is AuthLoading || _isChecking || _isResending;
          final userEmail = state is AuthEmailVerificationRequired
              ? state.user.email ?? 'your email'
              : 'your email';

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: isBusy ? null : () => context.pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(((255 * 0.10)).toInt()),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      size: 72,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Verify Your Email',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We sent a verification email to:',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(((255 * 0.06)).toInt()),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(((255 * 0.14)).toInt()),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            userEmail,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(((255 * 0.12)).toInt()),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.amber.withAlpha(((255 * 0.28)).toInt()),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.amber.shade800,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Check your inbox, spam, junk, or promotions folder. After opening the email and tapping the link, return here. ACADIA will keep checking automatically.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Verification Guide',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 360,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(((255 * 0.10)).toInt()),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(((255 * 0.04)).toInt()),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: PageView.builder(
                            controller: _guidePageController,
                            itemCount: _guideSteps.length,
                            onPageChanged: (index) {
                              setState(() => _currentGuidePage = index);
                            },
                            itemBuilder: (context, index) {
                              return _buildGuideCard(_guideSteps[index]);
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _guideSteps.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: _currentGuidePage == index ? 22 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: _currentGuidePage == index
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    text: 'I HAVE VERIFIED',
                    onPressed: isBusy ? () {} : () => _checkVerification(),
                    isLoading: _isChecking,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _canResend && !isBusy ? _resendEmail : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: _canResend
                              ? AppColors.primary
                              : Colors.grey.shade400,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _isResending
                            ? 'Resending...'
                            : _canResend
                                ? 'Resend Verification Email'
                                : 'Resend available in $_resendCounter seconds',
                        style: TextStyle(
                          color: _canResend
                              ? AppColors.primary
                              : Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: isBusy ? null : () => _checkVerification(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Check Again'),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : _logout,
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text('Use Different Email'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VerificationGuideStep {
  final String imagePath;
  final String title;
  final String description;

  const _VerificationGuideStep({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}
