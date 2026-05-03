import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:momen/app/routing/app_route.dart';
import 'package:momen/core/config/app_environment.dart';
import 'package:momen/core/constants/app_sizes.dart';
import 'package:momen/core/providers/core_providers.dart';
import 'package:momen/features/auth/domain/entities/friend_profile.dart';
import 'package:momen/features/auth/domain/entities/nearby_user_profile.dart';
import 'package:momen/features/auth/presentation/state/auth_controller.dart';
import 'package:momen/features/auth/presentation/state/friend_search_provider.dart';
import 'package:momen/features/recap/domain/entities/memory_owner_option.dart';
import 'package:momen/features/recap/presentation/state/memories_provider.dart';
import 'package:momen/features/spending/presentation/state/spending_summary_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

enum _ProfileSection { overview, friends, settings }
enum _SearchMode { name, nearby, contacts }

class PhoneContactInvite {
  const PhoneContactInvite({
    required this.name,
    required this.phoneNumber,
    required this.phoneHashes,
  });

  final String name;
  final String phoneNumber;
  final List<String> phoneHashes;
}

class _ProfileDetails {
  const _ProfileDetails({
    required this.fullName,
    required this.phone,
    required this.isPhoneVerified,
    required this.dateOfBirth,
    required this.userCode,
  });

  final String fullName;
  final String phone;
  final bool isPhoneVerified;
  final DateTime? dateOfBirth;
  final String userCode;

  _ProfileDetails copyWith({
    String? fullName,
    String? phone,
    bool? isPhoneVerified,
    DateTime? dateOfBirth,
    String? userCode,
  }) {
    return _ProfileDetails(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      userCode: userCode ?? this.userCode,
    );
  }
}

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({
    required this.onEditProfile,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    required this.showAmountInput,
    required this.onShowAmountInputChanged,
    this.loadContactsOverride,
    super.key,
  });

  final VoidCallback onEditProfile;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final bool showAmountInput;
  final ValueChanged<bool> onShowAmountInputChanged;
  final Future<List<PhoneContactInvite>> Function()? loadContactsOverride;

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late final TextEditingController _searchController;
  _ProfileSection _section = _ProfileSection.overview;
  _SearchMode _searchMode = _SearchMode.name;

  // Nearby state
  NearbySearchParams? _nearbyParams;
  bool _isLoadingLocation = false;
  String? _locationError;

  // Contacts state
  List<String>? _contactHashes;
  List<PhoneContactInvite> _contactInvites = const [];
  bool _isLoadingContacts = false;
  String? _contactsError;
  bool _isLoadingProfile = true;
  bool _isSavingProfile = false;
  bool _isSigningOut = false;
  String? _profileError;
  _ProfileDetails? _profileDetails;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadProfileDetails();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatAmount(int amount) {
    final value = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final reverseIndex = value.length - i;
      buffer.write(value[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) buffer.write('.');
    }
    return buffer.toString();
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '--';
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _loadProfileDetails() async {
    final client = ref.read(supabaseClientProvider);
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      if (!mounted) return;
      setState(() {
        _profileError = 'Please sign in.';
        _isLoadingProfile = false;
      });
      return;
    }

    setState(() {
      _isLoadingProfile = true;
      _profileError = null;
    });

    try {
      final row = await client
          .from('profiles')
          .select('full_name,date_of_birth,user_code,phone_number,is_phone_verified')
          .eq('id', user.id)
          .maybeSingle();

      final rawDob = (row?['date_of_birth'] as String?)?.trim() ?? '';
      final parsedDob = rawDob.isEmpty ? null : DateTime.tryParse(rawDob);
      final metadata = user.userMetadata;
      final metadataPhone = (metadata?['contact_phone'] as String?)?.trim();
      final authPhone = user.phone?.trim();
      final profilePhone = (row?['phone_number'] as String?)?.trim();
      final effectivePhone = (profilePhone?.isNotEmpty ?? false)
          ? profilePhone!
          : (authPhone?.isNotEmpty ?? false)
              ? authPhone!
              : (metadataPhone?.isNotEmpty ?? false)
                  ? metadataPhone!
                  : '--';

      if (!mounted) return;
      setState(() {
        _profileDetails = _ProfileDetails(
          fullName: (row?['full_name'] as String?)?.trim() ?? '',
          phone: effectivePhone,
          isPhoneVerified: (row?['is_phone_verified'] as bool?) ?? false,
          dateOfBirth: parsedDob,
          userCode: (row?['user_code'] as String?)?.trim() ?? '',
        );
        _isLoadingProfile = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _profileError = '$error';
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _openEditProfileInfoDialog() async {
    final details = _profileDetails;
    if (details == null || _isSavingProfile) return;

    final nameController = TextEditingController(text: details.fullName);
    final idController = TextEditingController(text: details.userCode);
    DateTime? selectedDob = details.dateOfBirth;
    String? formError;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Edit profile info'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'User name'),
                    ),
                    const SizedBox(height: AppSizes.p12),
                    TextField(
                      controller: idController,
                      decoration: const InputDecoration(labelText: 'ID'),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: AppSizes.p12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date of birth'),
                      subtitle: Text(_formatDate(selectedDob)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDob ?? DateTime(2000, 1, 1),
                          firstDate: DateTime(1900, 1, 1),
                          lastDate: DateTime.now(),
                        );
                        if (picked == null) return;
                        setLocalState(() {
                          selectedDob = DateTime(picked.year, picked.month, picked.day);
                        });
                      },
                    ),
                    const SizedBox(height: AppSizes.p8),
                    Text('Phone: ${details.phone}'),
                    if (formError != null) ...[
                      const SizedBox(height: AppSizes.p8),
                      Text(
                        formError!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final normalizedName = nameController.text.trim();
                    final normalizedId = idController.text.trim().toUpperCase();
                    if (normalizedName.isEmpty) {
                      setLocalState(() => formError = 'Name is required.');
                      return;
                    }
                    if (normalizedId.length < 4) {
                      setLocalState(() => formError = 'ID must be at least 4 characters.');
                      return;
                    }
                    if (!RegExp(r'^[A-Z0-9_]+$').hasMatch(normalizedId)) {
                      setLocalState(() => formError = 'ID supports A-Z, 0-9, _ only.');
                      return;
                    }
                    if (selectedDob == null) {
                      setLocalState(() => formError = 'Date of birth is required.');
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true || !mounted) return;

    final normalizedName = nameController.text.trim();
    final normalizedId = idController.text.trim().toUpperCase();
    final selected = selectedDob ?? details.dateOfBirth;
    if (selected == null) return;

    final client = ref.read(supabaseClientProvider);
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;

    setState(() {
      _isSavingProfile = true;
      _profileError = null;
    });

    try {
      final isoDob = '${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
      await client.from('profiles').update({
        'full_name': normalizedName,
        'date_of_birth': isoDob,
        'user_code': normalizedId,
      }).eq('id', user.id);

      if (!mounted) return;
      setState(() {
        _profileDetails = details.copyWith(
          fullName: normalizedName,
          dateOfBirth: selected,
          userCode: normalizedId,
        );
      });
    } on PostgrestException catch (error) {
      if (!mounted) return;
      final isDuplicate = error.code == '23505' ||
          (error.message).toLowerCase().contains('profiles_user_code_key');
      setState(() {
        _profileError = isDuplicate
            ? 'ID already exists. Please choose another one.'
            : 'Cannot update profile: ${error.message}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _profileError = 'Cannot update profile: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProfile = false;
        });
      }
    }
  }

  Future<NearbySearchParams?> _fetchNearby() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled.';
          _isLoadingLocation = false;
        });
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _locationError = 'Location permission denied.';
          _isLoadingLocation = false;
        });
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      // Also update our own location in the DB for discoverability
      ref.read(friendRequestPendingIdsProvider.notifier).updateLocation(
            lat: pos.latitude,
            lon: pos.longitude,
          );

      final params = NearbySearchParams(lat: pos.latitude, lon: pos.longitude);
      setState(() {
        _nearbyParams = params;
        _isLoadingLocation = false;
      });
      return params;
    } catch (e) {
      setState(() {
        _locationError = 'Could not get location: $e';
        _isLoadingLocation = false;
      });
      return null;
    }
  }

  Future<void> _fetchContacts() async {
    setState(() {
      _isLoadingContacts = true;
      _contactsError = null;
    });

    try {
      if (widget.loadContactsOverride != null) {
        final contacts = await widget.loadContactsOverride!();
        final hashes = <String>{
          for (final contact in contacts) ...contact.phoneHashes,
        };
        if (!mounted) return;
        setState(() {
          _contactHashes = hashes.toList(growable: false);
          _contactInvites = contacts;
          _isLoadingContacts = false;
        });
        return;
      }

      if (!await FlutterContacts.requestPermission(readonly: true)) {
        if (!mounted) return;
        setState(() {
          _contactsError = 'Contacts permission denied.';
          _isLoadingContacts = false;
        });
        return;
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
      );

      final hashes = <String>{};
      final invitesByPhone = <String, PhoneContactInvite>{};
      for (final contact in contacts) {
        for (final phone in contact.phones) {
          final normalized = phone.number.replaceAll(RegExp(r'\D'), '');
          if (normalized.isNotEmpty) {
            final hash =
                sha256.convert(utf8.encode(normalized)).toString();
            hashes.add(hash);
            invitesByPhone.putIfAbsent(
              normalized,
              () => PhoneContactInvite(
                name: contact.displayName.trim().isEmpty
                    ? normalized
                    : contact.displayName.trim(),
                phoneNumber: phone.number,
                phoneHashes: [hash],
              ),
            );
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _contactHashes = hashes.toList(growable: false);
        _contactInvites = invitesByPhone.values.toList(growable: false)
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _isLoadingContacts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _contactsError = 'Could not read contacts: $e';
        _isLoadingContacts = false;
      });
    }
  }

  Future<void> _handleSignOut() async {
    if (_isSigningOut) return;

    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out'),
          content: const Text('Do you want to sign out from this device?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: TextButton.styleFrom(foregroundColor: Colors.black),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true || !mounted) return;

    setState(() => _isSigningOut = true);
    await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;

    final authState = ref.read(authControllerProvider);
    setState(() => _isSigningOut = false);
    if (authState.errorMessage != null && authState.errorMessage!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out warning: ${authState.errorMessage}')),
      );
    }
  }

  Future<void> _inviteContactBySms(PhoneContactInvite contact) async {
    final message = await _buildInviteMessage();

    final smsUri = Uri(
      scheme: 'sms',
      path: contact.phoneNumber,
      queryParameters: {'body': message},
    );

    if (!await launchUrl(smsUri, mode: LaunchMode.externalApplication)) {
      throw Exception('Cannot open SMS app.');
    }
  }

  Future<String> _buildInviteMessage() async {
    final senderId = await _resolveSenderInviteId();
    final apkDownloadUrl = AppEnvironment.apkDownloadUrl.trim();
    if (apkDownloadUrl.isEmpty) {
      throw Exception('APK download link is not configured. Set APK_DOWNLOAD_URL first.');
    }

    final currentUserId =
        ref.read(supabaseClientProvider)?.auth.currentUser?.id ?? '';
    final profileLink = currentUserId.isEmpty
        ? ''
        : 'momen://friend-profile?uid=$currentUserId';

    return [
      'Momen invite from ID: $senderId',
      if (profileLink.isNotEmpty) 'Profile link: $profileLink',
      'Download latest APK: $apkDownloadUrl',
      'After install, open Friends > ID and enter: $senderId',
    ].join('\n');
  }

  Future<String> _resolveSenderInviteId() async {
    final client = ref.read(supabaseClientProvider);
    final uid = client?.auth.currentUser?.id ?? '';
    if (client == null || uid.isEmpty) return uid;

    try {
      final row = await client
          .from('profiles')
          .select('user_code')
          .eq('id', uid)
          .maybeSingle();
      final userCode = (row?['user_code'] as String?)?.trim();
      if (userCode != null && userCode.isNotEmpty) {
        return userCode;
      }
    } catch (_) {
      // Fall back to auth uid if user_code cannot be resolved.
    }

    return uid;
  }

  Future<void> _openNearbyDiscovery() async {
    final params = _nearbyParams ?? await _fetchNearby();
    if (!mounted || params == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NearbyDiscoverySheet(params: params),
    );
  }

  void _selectSearchMode(_SearchMode mode) {
    setState(() {
      _searchMode = mode;
      _searchController.clear();
      ref.read(friendSearchQueryProvider.notifier).setQuery('');
    });
    if (mode == _SearchMode.contacts &&
        _contactHashes == null &&
        !_isLoadingContacts) {
      _fetchContacts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final memoriesCountAsync = ref.watch(memoryCountProvider);
    final friendsCountAsync = ref.watch(friendCountProvider);
    final spendingSummaryAsync = ref.watch(spendingSummaryProvider(null));
    final searchQuery = ref.watch(friendSearchQueryProvider).trim();
    final searchResultsAsync = ref.watch(friendSearchResultsProvider);
    final incomingRequestsAsync = ref.watch(incomingFriendRequestsProvider);
    final requestPendingIds = ref.watch(friendRequestPendingIdsProvider);
    final currentUserId =
        ref.watch(supabaseClientProvider)?.auth.currentUser?.id;
    final authUser = ref.watch(authControllerProvider).user;
    final profileName = ((_profileDetails?.fullName ?? authUser?.displayName) ?? '').trim();
    final profileAvatarUrl = (authUser?.avatarUrl ?? '').trim();
    final showFriendsDock = _section == _ProfileSection.friends;

    final memoriesValue = memoriesCountAsync.maybeWhen(
      data: (count) => '$count',
      orElse: () => '--',
    );
    final friendsValue = friendsCountAsync.maybeWhen(
      data: (count) => '$count',
      orElse: () => '--',
    );
    final weeklyValue = spendingSummaryAsync.maybeWhen(
      data: (summary) => _formatAmount(summary.monthlyTotalVnd),
      orElse: () => '--',
    );

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(
            AppSizes.p24,
            AppSizes.p24,
            AppSizes.p24,
            showFriendsDock ? 118 : AppSizes.p24,
          ),
          children: [
        // ── Avatar & stats ──────────────────────────────────────────────
        Column(
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: colorScheme.secondary,
              backgroundImage: profileAvatarUrl.isEmpty
                  ? null
                  : NetworkImage(profileAvatarUrl),
              child: profileAvatarUrl.isEmpty
                  ? const Icon(Icons.person, size: AppSizes.i32)
                  : null,
            ),
            const SizedBox(height: AppSizes.p12),
            Text(
              profileName.isEmpty ? 'You' : profileName,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(label: 'Memories', value: memoriesValue),
                _StatItem(label: 'Friends', value: friendsValue),
                _StatItem(label: 'Monthly', value: weeklyValue),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.p16),
        Column(
          key: const Key('profile_section_rows'),
          children: [
            _ProfileSectionRowButton(
              label: 'Overview',
              icon: Icons.person_outline,
              selected: _section == _ProfileSection.overview,
              onTap: () => setState(() => _section = _ProfileSection.overview),
            ),
            const SizedBox(height: AppSizes.p8),
            _ProfileSectionRowButton(
              label: 'Friends',
              icon: Icons.group_outlined,
              selected: _section == _ProfileSection.friends,
              onTap: () => setState(() => _section = _ProfileSection.friends),
            ),
            const SizedBox(height: AppSizes.p8),
            _ProfileSectionRowButton(
              label: 'Settings',
              icon: Icons.tune,
              selected: _section == _ProfileSection.settings,
              onTap: () => setState(() => _section = _ProfileSection.settings),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p16),

        // ── Incoming friend requests ────────────────────────────────────
        if (_section == _ProfileSection.friends) ...[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Friends',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSizes.p8),
                incomingRequestsAsync.when(
                  data: (requests) {
                    if (requests.isEmpty) return const SizedBox.shrink();
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSizes.p12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppSizes.r12),
                        border: Border.all(color: colorScheme.outline),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Incoming requests',
                              style:
                                  Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: AppSizes.p8),
                          ...requests.map((request) {
                            final accepting = requestPendingIds.contains(
                                'accept:${request.requesterId}');
                            final rejecting = requestPendingIds.contains(
                                'reject:${request.requesterId}');
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                  child: Icon(Icons.person_outline)),
                              title: Text(request.fullName),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: accepting || rejecting
                                        ? null
                                        : () async {
                                            try {
                                              await ref
                                                  .read(
                                                      friendRequestPendingIdsProvider
                                                          .notifier)
                                                  .respondToRequest(
                                                      requesterId: request
                                                          .requesterId,
                                                      accept: false);
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(
                                                          'Error: $e')));
                                            }
                                          },
                                    icon: const Icon(Icons.close),
                                    color: Colors.red,
                                  ),
                                  FilledButton.tonal(
                                    onPressed: accepting || rejecting
                                        ? null
                                        : () async {
                                            final share = await _showShareHistoryDialog(
                                                context, request.fullName);
                                            if (share == null) return;
                                            
                                            try {
                                              await ref
                                                  .read(
                                                      friendRequestPendingIdsProvider
                                                          .notifier)
                                                  .respondToRequest(
                                                      requesterId: request
                                                          .requesterId,
                                                      accept: true,
                                                      shareHistory: share,
                                                  );
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(
                                                          'Error: $e')));
                                            }
                                          },
                                    child: const Text('Accept'),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                  loading: () => const Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: AppSizes.p8),
                    child: LinearProgressIndicator(),
                  ),
                  error: (error, _) => Text('Cannot load requests: $error'),
                ),
                const SizedBox(height: AppSizes.p12),

                // ── Search mode selector ──────────────────────────────
                SegmentedButton<_SearchMode>(
                  segments: const [
                    ButtonSegment(
                      value: _SearchMode.name,
                      icon: Icon(Icons.search, size: 18),
                      label: Text('ID'),
                    ),
                    ButtonSegment(
                      value: _SearchMode.contacts,
                      icon: Icon(Icons.contacts, size: 18),
                      label: Text('Contacts'),
                    ),
                    ButtonSegment(
                      value: _SearchMode.nearby,
                      icon: Icon(Icons.near_me, size: 18),
                      label: Text('Nearby'),
                    ),
                  ],
                  selected: {_searchMode},
                  onSelectionChanged: (modes) =>
                      _selectSearchMode(modes.first),
                ),
                const SizedBox(height: AppSizes.p12),

                // ── Mode-specific content ─────────────────────────────
                if (_searchMode == _SearchMode.name) ...[
                  TextField(
                    key: const Key('profile_friend_search_field'),
                    controller: _searchController,
                    onChanged: (value) => ref
                        .read(friendSearchQueryProvider.notifier)
                        .setQuery(value),
                    decoration: InputDecoration(
                      hintText: 'Name or #CODE',
                      prefixIcon: const Icon(Icons.search),
                      suffixText: searchQuery.startsWith('#')
                          ? 'Exact code'
                          : null,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p12),
                  if (searchQuery.isEmpty)
                    _InfoBox(
                      text:
                          'Type #CODE to find an exact user code, or search by name.',
                      color: colorScheme.surface,
                      borderColor: colorScheme.outline,
                    )
                  else
                    searchResultsAsync.when(
                      data: (friends) => friends.isEmpty
                          ? _InfoBox(
                              text: 'No users found.',
                              color: colorScheme.surface,
                              borderColor: colorScheme.outline,
                            )
                          : _FriendResultList(
                              friends: friends,
                              pendingIds: requestPendingIds,
                              onAdd: (id, name) async {
                                try {
                                  await ref
                                      .read(friendRequestPendingIdsProvider
                                          .notifier)
                                      .sendRequest(id);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Request sent to $name')),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Error: $e')));
                                }
                              },
                              onTap: (id) => context.goNamed(
                                AppRoute.friendProfile.name,
                                queryParameters: {'uid': id},
                              ),
                            ),
                      loading: () => const Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: AppSizes.p12),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text('Search failed: $e'),
                    ),
                ] else if (_searchMode == _SearchMode.nearby) ...[
                  if (_isLoadingLocation)
                    const Center(child: CircularProgressIndicator())
                  else if (_locationError != null)
                    _InfoBox(
                        text: _locationError!,
                        color: colorScheme.errorContainer,
                        borderColor: colorScheme.error)
                  else
                    FilledButton.icon(
                      onPressed: _openNearbyDiscovery,
                      icon: const Icon(Icons.near_me),
                      label: const Text('Kết bạn 4 phương'),
                    ),
                ] else ...[
                  if (_isLoadingContacts)
                    const Center(child: CircularProgressIndicator())
                  else if (_contactsError != null)
                    _InfoBox(
                        text: _contactsError!,
                        color: colorScheme.errorContainer,
                        borderColor: colorScheme.error)
                  else if (_contactHashes == null)
                    _InfoBox(
                      text: 'Preparing your contact list...',
                      color: colorScheme.surface,
                      borderColor: colorScheme.outline,
                    )
                  else if (_contactHashes!.isEmpty)
                    _InfoBox(
                      text: 'No contacts with phone numbers found.',
                      color: colorScheme.surface,
                      borderColor: colorScheme.outline,
                    )
                  else
                    _ContactInviteList(
                      contacts: _contactInvites,
                      hashes: _contactHashes!,
                      pendingIds: requestPendingIds,
                      onAdd: (id, name) async {
                        try {
                          await ref
                              .read(
                                  friendRequestPendingIdsProvider.notifier)
                              .sendRequest(id);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Request sent to $name')));
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                            content: Text('Error: $e'),
                          ));
                        }
                      },
                      onTap: (id) => context.goNamed(
                        AppRoute.friendProfile.name,
                        queryParameters: {'uid': id},
                      ),
                      onInvite: (contact) async {
                        try {
                          await _inviteContactBySms(contact);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                            content: Text('Error: $e'),
                          ));
                        }
                      },
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.p16),
        ],

        // ── Settings ───────────────────────────────────────────────────
        if (_section == _ProfileSection.settings) ...[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Settings',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSizes.p8),
                SwitchListTile.adaptive(
                  key: const Key('profile_dark_mode_toggle'),
                  value: widget.isDarkMode,
                  onChanged: widget.onDarkModeChanged,
                  title: const Text('Dark mode'),
                  subtitle:
                      const Text('Use the black and gold interface'),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile.adaptive(
                  key: const Key('profile_show_amount_toggle'),
                  value: widget.showAmountInput,
                  onChanged: widget.onShowAmountInputChanged,
                  title: const Text('Show spending input in camera'),
                  subtitle: const Text(
                      'Turn off to keep photo area near full-screen'),
                  contentPadding: EdgeInsets.zero,
                ),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.notifications_none),
                  title: Text('Notification options'),
                  subtitle: Text('Upcoming'),
                ),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.lock_outline),
                  title: Text('Privacy options'),
                  subtitle: Text('Upcoming'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.p24),
        ],
        if (_section == _ProfileSection.overview) ...[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: _isLoadingProfile
                ? const Center(child: CircularProgressIndicator())
                : _profileError != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cannot load profile: $_profileError'),
                          const SizedBox(height: AppSizes.p8),
                          FilledButton.tonal(
                            onPressed: _loadProfileDetails,
                            child: const Text('Retry'),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Profile Info',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              IconButton(
                                key: const Key('profile_edit_info_button'),
                                tooltip: 'Edit profile info',
                                onPressed: _isSavingProfile ? null : _openEditProfileInfoDialog,
                                icon: _isSavingProfile
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.edit),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.p8),
                          _ProfileInfoRow(
                            label: 'User name',
                            value: (_profileDetails?.fullName ?? '').isEmpty
                                ? '--'
                                : _profileDetails!.fullName,
                          ),
                          _ProfileInfoRow(
                            label: 'Phone number',
                            value: (_profileDetails?.phone ?? '').isEmpty
                                ? '--'
                                : _profileDetails!.phone,
                          ),
                          _ProfileInfoRow(
                            label: 'Phone status',
                            value: (_profileDetails?.phone ?? '--') == '--'
                                ? 'Not provided'
                                : (_profileDetails?.isPhoneVerified ?? false)
                                    ? 'Verified'
                                    : 'Unverified',
                          ),
                          _ProfileInfoRow(
                            label: 'Date of birth',
                            value: _formatDate(_profileDetails?.dateOfBirth),
                          ),
                          _ProfileInfoRow(
                            label: 'ID',
                            value: (_profileDetails?.userCode ?? '').isEmpty
                                ? '--'
                                : '#${_profileDetails!.userCode}',
                          ),
                          if (_profileError != null) ...[
                            const SizedBox(height: AppSizes.p8),
                            Text(
                              _profileError!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
                            ),
                          ],
                        ],
                      ),
          ),
        ),
        const SizedBox(height: AppSizes.p12),
        FilledButton.icon(
          onPressed: currentUserId == null
              ? null
              : () async {
                  try {
                    final inviteMessage = await _buildInviteMessage();
                    await Clipboard.setData(
                      ClipboardData(text: inviteMessage),
                    );
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $error')),
                    );
                    return;
                  }
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Invite message copied with latest APK link. Share it with your friends.')),
                  );
                },
          icon: const Icon(Icons.link),
          label: const Text('Copy Invite Message'),
        ),
        const SizedBox(height: AppSizes.p12),
        FilledButton.icon(
          onPressed: widget.onEditProfile,
          icon: const Icon(Icons.edit),
          label: const Text('Edit Profile'),
        ),
        const SizedBox(height: AppSizes.p12),
        FilledButton.icon(
          key: const Key('profile_sign_out_button_overview'),
          onPressed: _isSigningOut ? null : _handleSignOut,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.black,
          ),
          icon: _isSigningOut
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Icon(Icons.logout),
          label: Text(_isSigningOut ? 'Signing out...' : 'Sign out'),
        ),
        ],
          ],
        ),
        if (showFriendsDock)
          Positioned(
            left: AppSizes.p16,
            right: AppSizes.p16,
            bottom: AppSizes.p8,
            child: SafeArea(
              top: false,
              child: _FriendsBubbleDock(currentUserId: currentUserId),
            ),
          ),
      ],
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSizes.p4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _ProfileSectionRowButton extends StatelessWidget {
  const _ProfileSectionRowButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colorScheme.primaryContainer : colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSizes.r12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.r12),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p12,
            vertical: AppSizes.p12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.r12),
            border: Border.all(
              color: selected ? colorScheme.primary : colorScheme.outline,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon, 
                size: 18,
                color: selected ? Colors.black : null,
              ),
              const SizedBox(width: AppSizes.p8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.black : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.text,
    required this.color,
    required this.borderColor,
  });
  final String text;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSizes.r12),
        border: Border.all(color: borderColor),
      ),
      child: Text(text),
    );
  }
}

class _FriendsBubbleDock extends ConsumerWidget {
  const _FriendsBubbleDock({required this.currentUserId});

  final String? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownersAsync = ref.watch(memoryOwnersProvider);
    return ownersAsync.maybeWhen(
      data: (owners) {
        final filtered = owners
            .where((owner) => owner.id != currentUserId)
            .toList(growable: false);
        if (filtered.isEmpty) return const SizedBox.shrink();

        return Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(AppSizes.r24),
          color: Theme.of(context).colorScheme.surface,
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.r24),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSizes.p8),
              itemBuilder: (context, index) {
                final owner = filtered[index];
                return _DockFriendBubble(
                  owner: owner,
                  onTap: () => context.goNamed(
                    AppRoute.friendProfile.name,
                    queryParameters: {'uid': owner.id},
                  ),
                );
              },
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _DockFriendBubble extends StatelessWidget {
  const _DockFriendBubble({required this.owner, required this.onTap});

  final MemoryOwnerOption owner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.r24),
      onTap: onTap,
      child: SizedBox(
        width: 52,
        child: Center(
          child: Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                owner.fullName.isNotEmpty
                    ? owner.fullName[0].toUpperCase()
                    : '?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          const SizedBox(width: AppSizes.p12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendResultList extends StatelessWidget {
  const _FriendResultList({
    required this.friends,
    required this.pendingIds,
    required this.onAdd,
    required this.onTap,
  });
  final List<FriendProfile> friends;
  final Set<String> pendingIds;
  final void Function(String id, String name) onAdd;
  final void Function(String id) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: friends
          .map((f) => ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => onTap(f.id),
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Row(
                  children: [
                    Expanded(child: Text(f.fullName)),
                    if (f.userCode != null && f.userCode!.isNotEmpty)
                      Text(
                        '#${f.userCode}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                  ],
                ),
                trailing: FilledButton.tonal(
                  onPressed: pendingIds.contains(f.id)
                      ? null
                      : () => onAdd(f.id, f.fullName),
                  child: Text(
                      pendingIds.contains(f.id) ? 'Sending...' : 'Add'),
                ),
              ))
          .toList(growable: false),
    );
  }
}

class _NearbyDiscoverySheet extends ConsumerStatefulWidget {
  const _NearbyDiscoverySheet({required this.params});

  final NearbySearchParams params;

  @override
  ConsumerState<_NearbyDiscoverySheet> createState() =>
      _NearbyDiscoverySheetState();
}

class _NearbyDiscoverySheetState extends ConsumerState<_NearbyDiscoverySheet> {
  int _index = 0;

  Future<void> _accept(NearbyUserProfile user) async {
    await ref.read(friendRequestPendingIdsProvider.notifier).sendRequest(user.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Request sent to ${user.fullName}')),
    );
  }

  void _next() => setState(() => _index += 1);

  @override
  Widget build(BuildContext context) {
    final nearbyAsync = ref.watch(nearbyUsersProvider(widget.params));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.p16,
          AppSizes.p12,
          AppSizes.p16,
          AppSizes.p24,
        ),
        child: nearbyAsync.when(
          data: (users) {
            if (users.isEmpty || _index >= users.length) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: AppSizes.p16),
                  Text(
                    'No more nearby people right now.',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.p16),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              );
            }

            final user = users[_index];
            final km = (user.distanceM / 1000).toStringAsFixed(1);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Kết bạn 4 phương',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSizes.p8),
                Text(
                  'Swipe left to add. Swipe right to skip.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.p16),
                Dismissible(
                  key: ValueKey(user.id),
                  direction: DismissDirection.horizontal,
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: AppSizes.p24),
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: const Icon(Icons.close),
                  ),
                  secondaryBackground: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSizes.p24),
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: const Icon(Icons.person_add),
                  ),
                  onDismissed: (direction) async {
                    _next();
                    if (direction == DismissDirection.endToStart) {
                      await _accept(user);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.p24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppSizes.r8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundImage: user.avatarUrl == null
                              ? null
                              : NetworkImage(user.avatarUrl!),
                          child: user.avatarUrl == null
                              ? const Icon(Icons.person, size: AppSizes.i32)
                              : null,
                        ),
                        const SizedBox(height: AppSizes.p12),
                        Text(
                          user.fullName,
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        if (user.userCode != null && user.userCode!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSizes.p4),
                            child: Text('#${user.userCode}'),
                          ),
                        const SizedBox(height: AppSizes.p8),
                        Text('~$km km away'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.p16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _next,
                        icon: const Icon(Icons.close),
                        label: const Text('Skip'),
                      ),
                    ),
                    const SizedBox(width: AppSizes.p12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          _next();
                          await _accept(user);
                        },
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSizes.p24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(AppSizes.p24),
            child: Text('Cannot load nearby people: $error'),
          ),
        ),
      ),
    );
  }
}

class _ContactInviteList extends ConsumerWidget {
  const _ContactInviteList({
    required this.contacts,
    required this.hashes,
    required this.pendingIds,
    required this.onAdd,
    required this.onTap,
    required this.onInvite,
  });
  final List<PhoneContactInvite> contacts;
  final List<String> hashes;
  final Set<String> pendingIds;
  final void Function(String id, String name) onAdd;
  final void Function(String id) onTap;
  final Future<void> Function(PhoneContactInvite contact) onInvite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(contactMatchesProvider(hashes));
    return matchesAsync.when(
      data: (matches) {
        if (contacts.isEmpty) {
          return const _InfoBox(
            text: 'No contacts with phone numbers found.',
            color: Colors.transparent,
            borderColor: Colors.grey,
          );
        }
        final matchesByHash = {
          for (final match in matches)
            if (match.matchedPhoneHash != null) match.matchedPhoneHash!: match,
        };
        return Column(
          children: contacts.map((contact) {
            FriendProfile? match;
            for (final hash in contact.phoneHashes) {
              match = matchesByHash[hash];
              if (match != null) break;
            }

            if (match == null) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person_add_alt)),
                title: Text(contact.name),
                subtitle: Text(contact.phoneNumber),
                trailing: FilledButton.tonal(
                  onPressed: () => onInvite(contact),
                  child: const Text('Invite'),
                ),
              );
            }

            final matched = match;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => onTap(matched.id),
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Row(
                children: [
                  Expanded(child: Text(matched.fullName)),
                  if (matched.userCode != null && matched.userCode!.isNotEmpty)
                    Text(
                      '#${matched.userCode}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                ],
              ),
              subtitle: Text(contact.phoneNumber),
              trailing: FilledButton.tonal(
                onPressed: pendingIds.contains(matched.id)
                    ? null
                    : () => onAdd(matched.id, matched.fullName),
                child: Text(
                  pendingIds.contains(matched.id) ? 'Sending...' : 'Kết bạn',
                ),
              ),
            );
          }).toList(growable: false),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }
}

Future<bool?> _showShareHistoryDialog(BuildContext context, String fullName) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Chia sẻ lịch sử?'),
      content: Text('Bạn có muốn chia sẻ lịch sử ảnh 30 ngày qua của mình với $fullName không?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không, chỉ ảnh mới')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Có, chia sẻ')),
      ],
    ),
  );
}



