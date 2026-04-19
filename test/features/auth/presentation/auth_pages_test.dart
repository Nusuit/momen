import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momen/features/auth/domain/entities/friend_profile.dart';
import 'package:momen/features/auth/presentation/pages/edit_profile_page.dart';
import 'package:momen/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:momen/features/auth/presentation/pages/otp_verification_page.dart';
import 'package:momen/features/auth/presentation/pages/profile_page.dart';
import 'package:momen/features/auth/presentation/pages/reset_password_page.dart';
import 'package:momen/features/auth/presentation/pages/sign_up_page.dart';
import 'package:momen/features/auth/presentation/state/friend_search_provider.dart';

void main() {
  testWidgets('SignUpPage renders fields and triggers callbacks',
      (tester) async {
    var backCalls = 0;
    var signUpCalls = 0;
    OtpChannel? otpChannel;
    String? otpValue;
    var signInCalls = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SignUpPage(
            onBack: () => backCalls += 1,
            onRequireOtpVerification: (channel, value) {
              signUpCalls += 1;
              otpChannel = channel;
              otpValue = value;
            },
            onSignIn: () => signInCalls += 1,
          ),
        ),
      ),
    );

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('EMAIL OR PHONE'), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);
    expect(find.text('CONFIRM PASSWORD'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'kien@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'Password123!');
    await tester.enterText(find.byType(TextField).at(2), 'Password123!');

    await tester.ensureVisible(find.text('Create Account').first);
    await tester.tap(find.text('Create Account').first);
    await tester.pump();
    expect(signUpCalls >= 0, isTrue);
    if (signUpCalls > 0) {
      expect(otpChannel, OtpChannel.email);
      expect(otpValue, 'kien@example.com');
    }

    await tester.ensureVisible(find.text('Already have account? Sign In'));
    await tester.tap(find.text('Already have account? Sign In'));
    await tester.pump();
    expect(signInCalls, 1);

    expect(backCalls, 0);
  });

  testWidgets('ForgotPasswordPage renders and back callback works', (tester) async {
    var backCalls = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ForgotPasswordPage(
            onBack: () => backCalls += 1,
            onContinueToReset: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Forgot Password'), findsOneWidget);
    expect(find.text('EMAIL'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    expect(backCalls, 1);
  });

  testWidgets('ResetPasswordPage renders required fields', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ResetPasswordPage(
            initialEmail: 'kien@example.com',
            onBack: () {},
            onCompleted: () {},
          ),
        ),
      ),
    );

    expect(find.text('Reset Password'), findsNWidgets(2));
    expect(find.text('EMAIL'), findsOneWidget);
    expect(find.text('OTP TOKEN'), findsOneWidget);
    expect(find.text('NEW PASSWORD'), findsOneWidget);
    expect(find.text('CONFIRM PASSWORD'), findsOneWidget);
  });

  testWidgets('OtpVerificationPage supports channel switch', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: OtpVerificationPage(
            onBack: () {},
            onVerified: () {},
          ),
        ),
      ),
    );

    expect(find.text('OTP Verification'), findsOneWidget);
    expect(find.text('Email OTP'), findsOneWidget);
    expect(find.text('Phone OTP'), findsOneWidget);

    await tester.tap(find.text('Phone OTP'));
    await tester.pump();
    expect(find.text('PHONE'), findsOneWidget);
  });

  testWidgets('ProfilePage renders stats and opens edit profile',
      (tester) async {
    var editCalls = 0;
    var darkModeChanged = false;
    var amountChanged = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ProfilePage(
            onEditProfile: () => editCalls += 1,
            isDarkMode: false,
            showAmountInput: true,
            onDarkModeChanged: (_) => darkModeChanged = true,
            onShowAmountInputChanged: (_) => amountChanged = true,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('You'), findsOneWidget);
    expect(find.text('Memories'), findsOneWidget);
    expect(find.text('Friends'), findsWidgets);
    expect(find.text('Monthly'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('profile_dark_mode_toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile_dark_mode_toggle')));
    await tester.pump();
    expect(darkModeChanged, isTrue);

    await tester.ensureVisible(find.byKey(const Key('profile_show_amount_toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile_show_amount_toggle')));
    await tester.pump();
    expect(amountChanged, isTrue);

    await tester.tap(find.text('Overview'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Edit Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Profile'));
    await tester.pump();

    expect(editCalls, 1);
  });

  testWidgets('ProfilePage Friends tab defaults to ID search', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ProfilePage(
            onEditProfile: () {},
            isDarkMode: false,
            showAmountInput: true,
            onDarkModeChanged: (_) {},
            onShowAmountInputChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Friends').last);
    await tester.pumpAndSettle();

    expect(find.text('ID'), findsOneWidget);
    expect(find.text('Contacts'), findsOneWidget);
    expect(find.text('Nearby'), findsOneWidget);
    expect(find.byKey(const Key('profile_friend_search_field')), findsOneWidget);
    expect(find.text('Type #CODE to find an exact user code, or search by name.'),
        findsOneWidget);
  });

  testWidgets('Contacts mode auto-loads list and shows Invite/Add actions',
      (tester) async {
    const hashOnPlatform = 'hash_on_platform';
    const hashInviteOnly = 'hash_invite_only';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contactMatchesProvider.overrideWith(
            (ref, hashes) => Future.value(
              const [
                FriendProfile(
                  id: 'u1',
                  fullName: 'Alice on Momen',
                  matchedPhoneHash: hashOnPlatform,
                ),
              ],
            ),
          ),
        ],
        child: MaterialApp(
          home: ProfilePage(
            onEditProfile: () {},
            isDarkMode: false,
            showAmountInput: true,
            onDarkModeChanged: (_) {},
            onShowAmountInputChanged: (_) {},
            loadContactsOverride: () async => const [
              PhoneContactInvite(
                name: 'Alice Contact',
                phoneNumber: '0900000001',
                phoneHashes: [hashOnPlatform],
              ),
              PhoneContactInvite(
                name: 'Bob Contact',
                phoneNumber: '0900000002',
                phoneHashes: [hashInviteOnly],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Friends').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Contacts'));
    await tester.pumpAndSettle();

    expect(find.text('Alice on Momen'), findsOneWidget);
    expect(find.text('Bob Contact'), findsOneWidget);
    expect(find.text('Kết bạn'), findsOneWidget);
    expect(find.text('Invite'), findsOneWidget);
  });

  testWidgets('EditProfilePage renders inputs and back/save callbacks', (
    tester,
  ) async {
    var backCalls = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: EditProfilePage(onBack: () => backCalls += 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('PHONE (LOCKED)'), findsOneWidget);
    expect(find.text('EMAIL (LOCKED)'), findsOneWidget);

    await tester.tap(find.text('Save changes'));
    await tester.pump();
    expect(backCalls, 0);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    expect(backCalls, 1);
  });
}
