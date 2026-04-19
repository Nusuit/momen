import 'package:flutter/material.dart';
import 'package:momen/core/components/buttons/primary_button.dart';
import 'package:momen/core/components/inputs/custom_text_field.dart';
import 'package:momen/core/constants/app_sizes.dart';

class ProfileCompletionDialog extends StatefulWidget {
  const ProfileCompletionDialog({
    required this.onSubmit,
    this.initialName,
    this.initialUserCode,
    this.initialPhone,
    this.initialEmail,
    this.lockPhone = false,
    this.lockEmail = false,
    super.key,
  });

  final Future<bool> Function({
    required String fullName,
    required String userCode,
    required String phone,
    required String email,
    required DateTime dateOfBirth,
  }) onSubmit;
  final String? initialName;
  final String? initialUserCode;
  final String? initialPhone;
  final String? initialEmail;
  final bool lockPhone;
  final bool lockEmail;

  @override
  State<ProfileCompletionDialog> createState() => _ProfileCompletionDialogState();
}

class _ProfileCompletionDialogState extends State<ProfileCompletionDialog> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _userCodeController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  final _dobController = TextEditingController();
  DateTime? _selectedDob;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.initialName ?? '');
    _userCodeController = TextEditingController(text: widget.initialUserCode ?? '');
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _userCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final fullName = _fullNameController.text.trim();
    final userCode = _userCodeController.text.trim().toUpperCase();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final dob = _selectedDob;

    if (fullName.isEmpty || userCode.isEmpty || email.isEmpty || dob == null) {
      setState(() {
        _error = 'Please fill in full name, ID, email, and date of birth.';
      });
      return;
    }

    if (!RegExp(r'^[A-Z0-9_]{4,}$').hasMatch(userCode)) {
      setState(() {
        _error = 'ID must be at least 4 chars and only use A-Z, 0-9, _.';
      });
      return;
    }
    if (phone.isNotEmpty && !RegExp(r'^[+0-9]{8,}$').hasMatch(phone)) {
      setState(() {
        _error = 'Phone number is invalid.';
      });
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() {
        _error = 'Email is invalid.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final success = await widget.onSubmit(
      fullName: fullName,
      userCode: userCode,
      phone: phone,
      email: email,
      dateOfBirth: dob,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isSubmitting = false;
      _error = 'Unable to save profile. Please try again.';
    });
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate =
        _selectedDob ?? DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Select date of birth',
    );

    if (!mounted || picked == null) {
      return;
    }

    final normalized = DateTime(picked.year, picked.month, picked.day);
    setState(() {
      _selectedDob = normalized;
      _dobController.text = _formatDate(normalized);
      _error = null;
    });
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Complete your profile'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please add your basic info before continuing.'),
              const SizedBox(height: AppSizes.p16),
              CustomTextField(
                label: 'YOUR NAME',
                hintText: 'Your name',
                controller: _fullNameController,
              ),
              const SizedBox(height: AppSizes.p12),
              CustomTextField(
                label: 'ID',
                hintText: 'Your unique ID',
                controller: _userCodeController,
              ),
              const SizedBox(height: AppSizes.p12),
              Text(
                'PHONE (OPTIONAL)',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                      letterSpacing: 1.2,
                    ),
              ),
              const SizedBox(height: AppSizes.p8),
              TextField(
                controller: _phoneController,
                enabled: !widget.lockPhone,
                decoration: InputDecoration(
                  hintText: 'Add phone later if you want',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.r16),
                    borderSide:
                        BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  suffixIcon: widget.lockPhone
                      ? const Tooltip(
                          message: 'Managed by your current sign-in method.',
                          child: Icon(Icons.lock_outline),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: AppSizes.p12),
              Text(
                'EMAIL',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                      letterSpacing: 1.2,
                    ),
              ),
              const SizedBox(height: AppSizes.p8),
              TextField(
                controller: _emailController,
                enabled: !widget.lockEmail,
                decoration: InputDecoration(
                  hintText: 'you@example.com',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.r16),
                    borderSide:
                        BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  suffixIcon: widget.lockEmail
                      ? const Tooltip(
                          message: 'Managed by your current sign-in method.',
                          child: Icon(Icons.lock_outline),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: AppSizes.p12),
              Text(
                'DATE OF BIRTH',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      letterSpacing: 1.2,
                    ),
              ),
              const SizedBox(height: AppSizes.p8),
              TextField(
                key: const Key('profile_completion_dob_field'),
                controller: _dobController,
                readOnly: true,
                onTap: _pickDateOfBirth,
                decoration: InputDecoration(
                  hintText: 'Tap to choose date',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p16,
                    vertical: AppSizes.p16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.r16),
                    borderSide:
                        BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.r16),
                    borderSide:
                        BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.r16),
                    borderSide:
                        BorderSide(color: Theme.of(context).colorScheme.primary),
                  ),
                  suffixIcon: IconButton(
                    key: const Key('profile_completion_dob_picker_button'),
                    icon: const Icon(Icons.calendar_today_rounded),
                    onPressed: _pickDateOfBirth,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSizes.p12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: 180,
          child: PrimaryButton(
            label: _isSubmitting ? 'Saving...' : 'Save & Continue',
            onPressed: _isSubmitting ? () {} : _submit,
          ),
        ),
      ],
    );
  }
}
