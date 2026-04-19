import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momen/core/components/buttons/primary_button.dart';
import 'package:momen/core/components/inputs/custom_text_field.dart';
import 'package:momen/core/constants/app_sizes.dart';
import 'package:momen/features/auth/domain/repositories/auth_repository.dart';
import 'package:momen/features/auth/presentation/state/auth_controller.dart';
import 'package:momen/features/auth/presentation/widgets/profile_completion_dialog.dart';

enum OtpChannel {
  email,
  phone,
}

class OtpVerificationPage extends ConsumerStatefulWidget {
  const OtpVerificationPage({
    required this.onBack,
    required this.onVerified,
    this.initialEmail,
    this.initialPhone,
    this.initialChannel = OtpChannel.email,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onVerified;
  final String? initialEmail;
  final String? initialPhone;
  final OtpChannel initialChannel;

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  final _tokenController = TextEditingController();
  late OtpChannel _channel;

  @override
  void initState() {
    super.initState();
    _channel = widget.initialChannel;
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      _showMessage('Please enter OTP token first.');
      return;
    }

    if (_channel == OtpChannel.phone) {
      final phone = _phoneController.text.trim();
      final success = await ref.read(authControllerProvider.notifier).verifyPhoneOtp(
            phone: phone,
            token: token,
          );
      if (!mounted) {
        return;
      }
      if (success) {
        final completed = await _ensureProfileCompleted();
        if (!mounted) {
          return;
        }
        if (completed) {
          widget.onVerified();
        }
      } else {
        _showError();
      }
      return;
    }

    final email = _emailController.text.trim();
    final success = await ref.read(authControllerProvider.notifier).verifyEmailOtp(
          email: email,
          token: token,
          type: EmailOtpType.signup,
        );
    if (!mounted) {
      return;
    }
    if (success) {
      final completed = await _ensureProfileCompleted();
      if (!mounted) {
        return;
      }
      if (completed) {
        widget.onVerified();
      }
      return;
    }
    _showError();
  }

  Future<void> _resendPhoneOtp() async {
    if (_channel != OtpChannel.phone) {
      return;
    }

    final phone = _phoneController.text.trim();
    final success = await ref.read(authControllerProvider.notifier).requestPhoneOtp(
          phone: phone,
        );

    if (!mounted) {
      return;
    }

    if (success) {
      _showMessage('OTP sent again.');
      return;
    }
    _showError();
  }

  void _showError() {
    final message = ref.read(authControllerProvider).errorMessage;
    _showMessage(message ?? 'OTP verification failed.');
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
        title: const Text('OTP Verification'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<OtpChannel>(
              segments: const [
                ButtonSegment<OtpChannel>(
                  value: OtpChannel.email,
                  label: Text('Email OTP'),
                ),
                ButtonSegment<OtpChannel>(
                  value: OtpChannel.phone,
                  label: Text('Phone OTP'),
                ),
              ],
              selected: {_channel},
              onSelectionChanged: (selection) {
                setState(() {
                  _channel = selection.first;
                });
              },
            ),
            const SizedBox(height: AppSizes.p16),
            if (_channel == OtpChannel.email)
              CustomTextField(
                label: 'EMAIL',
                hintText: 'you@example.com',
                controller: _emailController,
              )
            else
              CustomTextField(
                label: 'PHONE',
                hintText: '+84901234567',
                controller: _phoneController,
              ),
            const SizedBox(height: AppSizes.p16),
            CustomTextField(
              label: 'OTP TOKEN',
              hintText: 'Enter OTP code/token',
              controller: _tokenController,
            ),
            const SizedBox(height: AppSizes.p24),
            PrimaryButton(
              label: isLoading ? 'Verifying...' : 'Verify OTP',
              onPressed: isLoading ? () {} : _verify,
            ),
            const SizedBox(height: AppSizes.p12),
            if (_channel == OtpChannel.phone)
              OutlinedButton(
                onPressed: isLoading ? null : _resendPhoneOtp,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Resend Phone OTP'),
              ),
          ],
        ),
      ),
    );
  }
}
