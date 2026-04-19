import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momen/core/components/buttons/primary_button.dart';
import 'package:momen/core/components/inputs/custom_text_field.dart';
import 'package:momen/core/constants/app_sizes.dart';
import 'package:momen/features/auth/presentation/pages/otp_verification_page.dart';
import 'package:momen/features/auth/presentation/state/auth_controller.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({
    required this.onBack,
    required this.onRequireOtpVerification,
    required this.onSignIn,
    super.key,
  });

  final VoidCallback onBack;
  final void Function(OtpChannel channel, String value)
      onRequireOtpVerification;
  final VoidCallback onSignIn;

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _contactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Password confirmation does not match.');
      return;
    }

    final contact = _contactController.text.trim();
    if (contact.isEmpty) {
      _showMessage('Please enter your email or phone number.');
      return;
    }

    final isEmail = contact.contains('@');
    final isPhone = RegExp(r'^[+0-9]{8,}$').hasMatch(contact);
    if (!isEmail && !isPhone) {
      _showMessage('Enter a valid email or phone number.');
      return;
    }

    final success = isEmail
        ? await ref.read(authControllerProvider.notifier).signUpWithEmail(
              email: contact,
              password: _passwordController.text,
            )
        : await ref.read(authControllerProvider.notifier).signUpWithPhone(
              phone: contact,
              password: _passwordController.text,
            );

    if (!mounted) {
      return;
    }

    if (!success) {
      final message = ref.read(authControllerProvider).errorMessage;
      _showMessage(message ?? 'Cannot create account now.');
      return;
    }

    _showMessage('Account created. Verify OTP to continue.');
    widget.onRequireOtpVerification(
      isEmail ? OtpChannel.email : OtpChannel.phone,
      contact,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
              const SizedBox(height: AppSizes.p12),
              Text('Create your account',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSizes.p24),
              CustomTextField(
                label: 'EMAIL OR PHONE',
                hintText: 'you@example.com or +84901234567',
                controller: _contactController,
              ),
              const SizedBox(height: AppSizes.p16),
              CustomTextField(
                label: 'PASSWORD',
                hintText: 'Create password',
                controller: _passwordController,
                obscureText: true,
              ),
              const SizedBox(height: AppSizes.p16),
              CustomTextField(
                label: 'CONFIRM PASSWORD',
                hintText: 'Retype password',
                controller: _confirmPasswordController,
                obscureText: true,
              ),
              const SizedBox(height: AppSizes.p24),
              PrimaryButton(
                label: isLoading ? 'Creating...' : 'Create Account',
                onPressed: isLoading ? () {} : _signUp,
              ),
              const SizedBox(height: AppSizes.p16),
              Center(
                child: TextButton(
                  onPressed: isLoading ? null : widget.onSignIn,
                  child: const Text('Already have account? Sign In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
