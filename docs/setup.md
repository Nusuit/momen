# Setup Guide - Momen

Tai lieu nay giup ban kiem tra nhanh truoc khi chay app tren Android/iOS.
Muc tieu: nhin vao checklist la biet da du dieu kien chua.

## 1) Pre-run Checklist (Tong quan)

Danh dau tung muc truoc khi flutter run:

- [ ] Flutter SDK da cai va dung version yeu cau
- [ ] Chay thanh cong: flutter --version
- [ ] Chay thanh cong: flutter doctor -v
- [ ] Chay thanh cong: flutter pub get
- [ ] Da co it nhat 1 thiet bi hien trong: flutter devices
- [ ] Da co day du thong tin runtime (SUPABASE_URL, SUPABASE_ANON_KEY)
- [ ] Neu bat Crashlytics: da setup Firebase files cho tung platform

## 2) Flutter + Toolchain can co

### Bat buoc cho moi may

- Flutter SDK (du an hien tai dung Flutter 3.38.x hoac tuong thich)
- Dart SDK (di kem Flutter)
- Git

Lenh de check nhanh:

flutter --version
flutter doctor -v
flutter devices

Neu flutter doctor bao loi, sua het loi quan trong truoc khi chay app.

## 3) Runtime config va API key can chuan bi

Du an doc bien runtime tu dart-define:

- SUPABASE_URL
- SUPABASE_ANON_KEY
- ENABLE_FIREBASE_CRASHLYTICS (optional)

### Toi thieu de app khoi dong voi backend

Can co:

- SUPABASE_URL: URL project Supabase
- SUPABASE_ANON_KEY: Anon key cua Supabase

Vi du run:

flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key

### Neu muon bat Crashlytics

Can co them:

- Firebase project da tao
- Android: google-services.json
- iOS: GoogleService-Info.plist

Sau do run:

flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key --dart-define=ENABLE_FIREBASE_CRASHLYTICS=true

## 4) Android Checklist

### Android toolchain

- [ ] Android Studio da cai
- [ ] Android SDK da cai day du
- [ ] Android SDK Platform + Build Tools hop le
- [ ] Android license da accept

Lenh:

flutter doctor --android-licenses

### Device cho Android

Chon 1 trong 2:

- [ ] Emulator dang chay (tu Android Studio Device Manager)
- [ ] Phone that co USB debugging bat

Check:

flutter devices

Neu khong thay device:

- Kiem tra cap USB (neu dung phone that)
- Kiem tra USB debugging
- Kiem tra adb devices

### Chay app Android

- [ ] Da flutter pub get
- [ ] Da thay Android device trong flutter devices
- [ ] Da truyen SUPABASE_URL va SUPABASE_ANON_KEY

Lenh:

flutter run -d <android_device_id> --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...

## 5) iOS Checklist

Luu y: build/chay iOS yeu cau macOS + Xcode. Neu ban dang o Windows thi khong the run iOS local.

### iOS toolchain (chi macOS)

- [ ] Xcode da cai
- [ ] Xcode Command Line Tools da cai
- [ ] CocoaPods da cai
- [ ] Chay thanh cong: pod --version
- [ ] Chay thanh cong: flutter doctor -v (khong loi iOS)

### Device cho iOS (chi macOS)

Chon 1 trong 2:

- [ ] iOS Simulator dang chay
- [ ] iPhone that da trust may + provisioning dung

Check:

flutter devices

### Chay app iOS

- [ ] Da flutter pub get
- [ ] Da thay iOS device trong flutter devices
- [ ] Da truyen SUPABASE_URL va SUPABASE_ANON_KEY
- [ ] Neu bat Crashlytics: da them GoogleService-Info.plist

Lenh:

flutter run -d <ios_device_id> --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...

## 6) Quick health-check truoc khi run

Dung cac lenh sau de check nhanh chat luong truoc khi chay:

flutter pub get
flutter analyze
flutter test --coverage
./scripts/coverage_gate.cmd -MinCoverage 80

## 7) Troubleshooting nhanh

### Khong thay device trong flutter devices

- Dong/mo lai emulator
- Thu lai cap USB
- Chay lai flutter doctor -v
- Chay adb devices (Android)

### App chay len nhung khong vao duoc backend

- Check lai SUPABASE_URL
- Check lai SUPABASE_ANON_KEY
- Dam bao URL/anokey dung project environment

### Bat Crashlytics nhung loi

- Dam bao da them file Firebase dung platform
- Chi bat ENABLE_FIREBASE_CRASHLYTICS=true khi da setup Firebase xong

## 8) One-command run mau

Android:

flutter run -d <android_device_id> --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key

iOS (macOS):

flutter run -d <ios_device_id> --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
