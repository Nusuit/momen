import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momen/core/components/buttons/primary_button.dart';
import 'package:momen/core/components/inputs/custom_text_field.dart';
import 'package:momen/core/constants/app_sizes.dart';
import 'package:momen/features/auth/presentation/state/auth_controller.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({
    required this.onBack,
    required this.onCompleted,
    this.initialEmail,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onCompleted;
  final String? initialEmail;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  late final TextEditingController _emailController;
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitReset() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showMessage('Password confirmation does not match.');
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .verifyRecoveryOtpAndResetPassword(
          email: _emailController.text,
          token: _tokenController.text,
          newPassword: _newPasswordController.text,
        );

    if (!mounted) {
      return;
    }

    if (!success) {
      final message = ref.read(authControllerProvider).errorMessage;
      _showMessage(message ?? 'Cannot reset password now.');
      return;
    }

    _showMessage('Password has been reset.');
    widget.onCompleted();
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
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Reset Password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              label: 'EMAIL',
              hintText: 'you@example.com',
              controller: _emailController,
            ),
            const SizedBox(height: AppSizes.p16),
            CustomTextField(
              label: 'OTP TOKEN',
              hintText: 'Enter OTP token from email',
              controller: _tokenController,
            ),
            const SizedBox(height: AppSizes.p16),
            CustomTextField(
              label: 'NEW PASSWORD',
              hintText: 'Create new password',
              controller: _newPasswordController,
              obscureText: true,
            ),
            const SizedBox(height: AppSizes.p16),
            CustomTextField(
              label: 'CONFIRM PASSWORD',
              hintText: 'Retype new password',
              controller: _confirmPasswordController,
              obscureText: true,
            ),
            const SizedBox(height: AppSizes.p24),
            PrimaryButton(
              label: isLoading ? 'Updating...' : 'Reset Password',
              onPressed: isLoading ? () {} : _submitReset,
            ),
          ],
        ),
      ),
    );
  }
}
