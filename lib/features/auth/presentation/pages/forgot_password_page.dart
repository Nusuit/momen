import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momen/core/components/buttons/primary_button.dart';
import 'package:momen/core/components/inputs/custom_text_field.dart';
import 'package:momen/core/constants/app_sizes.dart';
import 'package:momen/features/auth/presentation/state/auth_controller.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({
    required this.onBack,
    required this.onContinueToReset,
    super.key,
  });

  final VoidCallback onBack;
  final void Function(String email) onContinueToReset;

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Please enter email first.');
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordResetEmail(email: email);

    if (!mounted) {
      return;
    }

    if (!success) {
      final message = ref.read(authControllerProvider).errorMessage;
      _showMessage(message ?? 'Cannot send reset email now.');
      return;
    }

    _showMessage('Reset email/OTP has been sent.');
    widget.onContinueToReset(email);
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
        title: const Text('Forgot Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your account email to receive password reset instructions.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSizes.p24),
            CustomTextField(
              label: 'EMAIL',
              hintText: 'you@example.com',
              controller: _emailController,
            ),
            const SizedBox(height: AppSizes.p24),
            PrimaryButton(
              label: isLoading ? 'Sending...' : 'Send Reset Email',
              onPressed: isLoading ? () {} : _sendResetEmail,
            ),
          ],
        ),
      ),
    );
  }
}
