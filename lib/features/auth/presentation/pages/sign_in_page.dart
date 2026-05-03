import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momen/core/components/buttons/primary_button.dart';
import 'package:momen/core/config/app_environment.dart';
import 'package:momen/core/components/inputs/custom_text_field.dart';
import 'package:momen/core/constants/app_sizes.dart';
import 'package:momen/features/auth/presentation/state/auth_controller.dart';
import 'package:momen/features/auth/presentation/widgets/profile_completion_dialog.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({
    required this.onBack,
    required this.onSignUp,
    required this.onForgotPassword,
    required this.onOpenOtpVerification,
    required this.onSignedIn,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onSignUp;
  final VoidCallback onForgotPassword;
  final void Function(String phone) onOpenOtpVerification;
  final VoidCallback onSignedIn;

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _handledAuthenticatedEntry = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Reset stuck loading state from a previous incomplete auth flow
      final authState = ref.read(authControllerProvider);
      if (authState.status == AuthStatus.loading) {
        ref.read(authControllerProvider.notifier).resetToUnauthenticated();
      }
      _maybeHandleAuthenticatedEntry();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    setState(() => _isLoading = true);
    try {
      final success = await ref.read(authControllerProvider.notifier).signInWithEmail(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (!mounted) return;
      if (success) {
        final completed = await _ensureProfileCompleted();
        if (!mounted) return;
        if (completed) widget.onSignedIn();
        return;
      }
      final message = ref.read(authControllerProvider).errorMessage;
      _showMessage(message ?? 'Sign in failed.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final success = await ref.read(authControllerProvider.notifier).signInWithGoogle(
            redirectTo: AppEnvironment.googleOAuthRedirectUri,
          );
      if (!mounted) return;
      if (success && ref.read(authControllerProvider).status == AuthStatus.authenticated) {
        final completed = await _ensureProfileCompleted();
        if (!mounted) return;
        if (completed) widget.onSignedIn();
        return;
      }
      final message = ref.read(authControllerProvider).errorMessage;
      if (message != null && message.isNotEmpty) {
        _showMessage(message);
        return;
      }
      _showMessage('Google sign-in started. Complete the flow in browser.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _requestPhoneOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showMessage('Please enter phone number first.');
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).requestPhoneOtp(
          phone: phone,
        );

    if (!mounted) {
      return;
    }

    if (success) {
      _showMessage('OTP has been sent.');
      widget.onOpenOtpVerification(phone);
      return;
    }

    final message = ref.read(authControllerProvider).errorMessage;
    _showMessage(message ?? 'Cannot send OTP now.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool> _ensureProfileCompleted() async {
    final notifier = ref.read(authControllerProvider.notifier);
    final authState = ref.read(authControllerProvider);
    final requiresProfileCompletion = await notifier.requiresProfileCompletion();

    if (!mounted) {
      return false;
    }

    if (!requiresProfileCompletion) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ProfileCompletionDialog(
          initialName: authState.user?.displayName,
          initialPhone: authState.user?.phone,
          initialEmail: authState.user?.email,
          lockPhone: (authState.user?.phone?.trim().isNotEmpty ?? false),
          lockEmail: (authState.user?.email?.trim().isNotEmpty ?? false),
          onSubmit: ({
            required String fullName,
            required String userCode,
            required String phone,
            required String email,
            required DateTime dateOfBirth,
          }) {
            return notifier.completeProfile(
              fullName: fullName,
              userCode: userCode,
              phone: phone,
              email: email,
              dateOfBirth: dateOfBirth,
            );
          },
        );
      },
    );

    if (result != true) {
      _showMessage('Please complete your profile to continue.');
      return false;
    }

    return true;
  }

  Future<void> _maybeHandleAuthenticatedEntry() async {
    if (_handledAuthenticatedEntry) {
      return;
    }

    final authState = ref.read(authControllerProvider);
    if (authState.status != AuthStatus.authenticated) {
      return;
    }

    _handledAuthenticatedEntry = true;
    final completed = await _ensureProfileCompleted();
    if (!mounted || !completed) {
      return;
    }
    widget.onSignedIn();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
              const SizedBox(height: AppSizes.p12),
              Text('Momen', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSizes.p8),
              Text(
                'Welcome back, Curator',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSizes.p24),
              CustomTextField(
                label: 'EMAIL',
                hintText: 'you@example.com',
                controller: _emailController,
              ),
              const SizedBox(height: AppSizes.p16),
              CustomTextField(
                label: 'PASSWORD',
                hintText: 'Enter your password',
                controller: _passwordController,
                obscureText: true,
              ),
              const SizedBox(height: AppSizes.p8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading ? null : widget.onForgotPassword,
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: AppSizes.p24),
              PrimaryButton(
                label: isLoading ? 'Signing in...' : 'Sign In',
                onPressed: isLoading ? () {} : _signInWithEmail,
                icon: Icons.arrow_forward,
              ),
              const SizedBox(height: AppSizes.p12),
              OutlinedButton.icon(
                onPressed: isLoading ? null : _signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata),
                label: const Text('Continue with Google'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
              const SizedBox(height: AppSizes.p20),
              Text(
                'OR LOGIN WITH PHONE',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: AppSizes.p8),
              CustomTextField(
                label: 'PHONE',
                hintText: '+84901234567',
                controller: _phoneController,
              ),
              const SizedBox(height: AppSizes.p12),
              OutlinedButton(
                onPressed: isLoading ? null : _requestPhoneOtp,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Send OTP'),
              ),
              const SizedBox(height: AppSizes.p16),
              Center(
                child: TextButton(
                  onPressed: isLoading ? null : widget.onSignUp,
                  child: const Text('No account yet? Sign Up'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
