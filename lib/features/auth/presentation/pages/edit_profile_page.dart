import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momen/core/components/buttons/primary_button.dart';
import 'package:momen/core/components/inputs/custom_text_field.dart';
import 'package:momen/core/constants/app_sizes.dart';
import 'package:momen/core/providers/core_providers.dart';
import 'package:momen/features/auth/presentation/state/auth_controller.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  DateTime? _selectedDob;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final client = ref.read(supabaseClientProvider);
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Please sign in first.';
      });
      return;
    }

    try {
      final row = await client
          .from('profiles')
          .select('full_name,date_of_birth,user_code,phone_number')
          .eq('id', user.id)
          .maybeSingle();

      final metadata = user.userMetadata;
      final phoneFromMetadata = (metadata?['contact_phone'] as String?)?.trim();
      final emailFromMetadata = (metadata?['contact_email'] as String?)?.trim();

        final profilePhone = ((row?['phone_number'] as String?) ?? '').trim();
      _nameController.text = ((row?['full_name'] as String?) ?? '').trim();
      _idController.text = ((row?['user_code'] as String?) ?? '').trim();
        _phoneController.text = profilePhone.isNotEmpty
          ? profilePhone
          : (user.phone?.trim().isNotEmpty ?? false)
            ? user.phone!.trim()
          : (phoneFromMetadata ?? '');
      _emailController.text = (user.email?.trim().isNotEmpty ?? false)
          ? user.email!.trim()
          : (emailFromMetadata ?? '');

      final rawDob = ((row?['date_of_birth'] as String?) ?? '').trim();
      _selectedDob = rawDob.isEmpty ? null : DateTime.tryParse(rawDob);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '$error';
      });
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '--';
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _selectedDob = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _save() async {
    final fullName = _nameController.text.trim();
    final userCode = _idController.text.trim().toUpperCase();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final dob = _selectedDob;

    if (fullName.isEmpty || userCode.isEmpty || email.isEmpty || dob == null) {
      setState(() {
        _error = 'Please fill name, ID, email, and date of birth before saving.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final success = await ref.read(authControllerProvider.notifier).completeProfile(
          fullName: fullName,
          userCode: userCode,
          phone: phone,
          email: email,
          dateOfBirth: dob,
        );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      if (!success) {
        _error = 'Cannot save profile. ID may already exist.';
      }
    });

    if (success) {
      widget.onBack();
    }
  }

  void _showUpcomingMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Changing phone and email is upcoming later.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
        title: const Text('Edit profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      label: 'USER NAME',
                      hintText: 'Your user name',
                      controller: _nameController,
                    ),
                    const SizedBox(height: AppSizes.p16),
                    CustomTextField(
                      label: 'ID',
                      hintText: 'Your unique ID',
                      controller: _idController,
                    ),
                    const SizedBox(height: AppSizes.p16),
                    GestureDetector(
                      onTap: _showUpcomingMessage,
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'PHONE (LOCKED)',
                            suffixIcon: Tooltip(
                              message: 'Changing phone is upcoming later.',
                              child: Icon(Icons.info_outline),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.p16),
                    GestureDetector(
                      onTap: _showUpcomingMessage,
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'EMAIL (LOCKED)',
                            suffixIcon: Tooltip(
                              message: 'Changing email is upcoming later.',
                              child: Icon(Icons.info_outline),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.p16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('DATE OF BIRTH'),
                      subtitle: Text(_formatDate(_selectedDob)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _pickDob,
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSizes.p8),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    const SizedBox(height: AppSizes.p24),
                    PrimaryButton(
                      label: _isSaving ? 'Saving...' : 'Save changes',
                      onPressed: _isSaving ? () {} : _save,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
