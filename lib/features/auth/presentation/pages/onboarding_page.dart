import 'dart:ui';
import 'package:flutter/material.dart';

// UI Constants
const _bgColor = Color(0xFF131313);
const _primaryColor = Color(0xFFEAC16F);
const _primaryLight = Color(0xFFFFDFA3);
const _textColor = Color(0xFFE2E2E2);

// Local asset images — guaranteed to display, no internet needed
const _img1 = 'assets/onboarding/ob1_finance.png';
const _img2 = 'assets/onboarding/ob2_friends.png';
const _img3 = 'assets/onboarding/ob3_dashboard.png';
const _img4 = 'assets/onboarding/ob4_luxury.png';
const _img5 = 'assets/onboarding/ob5_coffee.png';
const _img6 = 'assets/onboarding/ob6_city.png';
const _img7 = 'assets/onboarding/ob7_nature.png';
const _img8 = 'assets/onboarding/ob8_watch.png';

// Each column gets its own unique image list for the Slide 4 mosaic
const _col1 = [_img1, _img5, _img7, _img3];
const _col2 = [_img6, _img2, _img8, _img4];
const _col3 = [_img3, _img7, _img1, _img5];
const _col4 = [_img8, _img4, _img6, _img2];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    required this.onComplete,
    required this.onSignUp,
    super.key,
  });

  final VoidCallback onComplete;
  final VoidCallback onSignUp;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Onboarding Content
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            children: const [
              _Slide1(),
              _Slide2(),
              _Slide3(),
              _Slide4(),
            ],
          ),
          
          // Header Overlay (Back & Skip)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button appears after slide 1
                  if (_currentIndex > 0)
                    GestureDetector(
                      onTap: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Icon(Icons.arrow_back, color: _primaryColor, size: 28),
                    )
                  else
                    const SizedBox(width: 28),
                  
                  // Skip button hidden on last page
                  if (_currentIndex < 3)
                    GestureDetector(
                      onTap: widget.onComplete,
                      child: const Text(
                        'SKIP',
                        style: TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 2.0,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),
          ),
          
          // Footer (Indicators & Continue)
          if (_currentIndex < 3)
            Positioned(
              bottom: 48,
              left: 32,
              right: 32,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      bool isActive = index == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 12 : 8,
                        height: isActive ? 12 : 8,
                        decoration: BoxDecoration(
                          color: isActive ? _primaryColor : const Color(0xFF353535),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  _ContinueButton(onTap: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutQuart,
                    );
                  }),
                ],
              ),
            ),

          // Slide 4 specific buttons are inside _Slide4 for precise layout
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide 1: Capture Spending
// ─────────────────────────────────────────────────────────────────────────────
class _Slide1 extends StatelessWidget {
  const _Slide1();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 120),
        Expanded(
          flex: 5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _Card(url: _img1, rotation: -12, offset: const Offset(-60, 0), opacity: 0.4),
              _Card(url: _img2, rotation: 12, offset: const Offset(60, 0), opacity: 0.4),
              const _Card(url: _img3, isMain: true, width: 220, height: 300),
              const Positioned(bottom: 24, child: _GlassBadge(label: 'VISUAL HISTORY')),
            ],
          ),
        ),
        _TextInfo(
          title: 'Capture Spending\nthrough the Lens',
          body: 'Turn boring receipts into vivid visual memories. Just snap, enter the amount, and save your journey.',
        ),
        const Spacer(flex: 3),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide 2: Connect Anonymously
// ─────────────────────────────────────────────────────────────────────────────
class _Slide2 extends StatelessWidget {
  const _Slide2();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 120),
        Expanded(
          flex: 5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const _Card(url: _img3, rotation: -12, offset: Offset(-60, 0), opacity: 0.6),
              const _Card(url: _img1, rotation: 12, offset: Offset(60, 0), opacity: 0.6),
              const _Card(url: _img2, isMain: true, width: 210, height: 290),
              Positioned(
                bottom: 40,
                right: 30,
                child: _GlassInfoCard(),
              ),
            ],
          ),
        ),
        _TextInfo(
          title: 'Connect Anonymously\nwith Friends',
          body: 'Share your lifestyle and spending habits with your circle in total privacy. No one knows it\'s you.',
        ),
        const Spacer(flex: 3),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide 3: Mastering Finances
// ─────────────────────────────────────────────────────────────────────────────
class _Slide3 extends StatelessWidget {
  const _Slide3();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 120),
        const Expanded(
          flex: 5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _Card(url: _img2, rotation: -12, offset: Offset(-60, 0), opacity: 0.6),
              _Card(url: _img3, rotation: 12, offset: Offset(60, 0), opacity: 0.6),
              _Card(url: _img1, isMain: true, width: 200, height: 280),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: _textColor, height: 1.1),
                  children: [
                    TextSpan(text: 'MasteringFinances\n'),
                    TextSpan(text: 'made Fun', style: TextStyle(color: _primaryColor)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Track your monthly budget through intuitive Dashboards and enjoy personalized visual Recap reels.',
                style: TextStyle(fontSize: 16, color: _textColor.withOpacity(0.8), height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const Spacer(flex: 3),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide 4: Memon Splash (Mosaic Design)
// ─────────────────────────────────────────────────────────────────────────────
class _Slide4 extends StatelessWidget {
  const _Slide4();
  @override
  Widget build(BuildContext context) {
    final onboarding = context.findAncestorStateOfType<_OnboardingPageState>()!;
    
    return Stack(
      children: [
        // Background Mosaic Strips (4 columns, each with unique images)
        Positioned.fill(
          bottom: 200,
          child: ClipRect(
            child: ShaderMask(
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.black, Colors.black.withOpacity(0)],
                stops: const [0, 0.6, 1.0],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: Row(
                children: [
                  _Strip(images: _col1, offset: -0.1),
                  _Strip(images: _col2, offset: -0.3),
                  _Strip(images: _col3, offset: -0.05),
                  _Strip(images: _col4, offset: -0.22),
                ],
              ),
            ),
          ),
        ),
        
        // Centered Logo & Text
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              const SizedBox(height: 20),
              CustomPaint(
                size: const Size(110, 100),
                painter: _MemonLogoPainter(),
              ),
              const SizedBox(height: 24),
              const Text(
                'MEMON',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: _textColor, letterSpacing: 4),
              ),
              Text(
                'Track your money, preserve your memories',
                style: TextStyle(fontSize: 14, color: _textColor.withOpacity(0.6), fontWeight: FontWeight.w300),
              ),
            ],
          ),
        ),
        
        // Bottom Buttons
        Positioned(
          bottom: 120,
          left: 32,
          right: 32,
          child: Column(
            children: [
              _PrimaryButton(label: 'Get Started', onTap: onboarding.widget.onSignUp),
              const SizedBox(height: 16),
              _SecondaryButton(label: 'Sign In', onTap: onboarding.widget.onComplete),
              const SizedBox(height: 24),
              Text(
                'CURATING YOUR DIGITAL LEGACY SINCE 2024',
                style: TextStyle(color: _textColor.withOpacity(0.3), fontSize: 10, letterSpacing: 2.0),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Components
// ─────────────────────────────────────────────────────────────────────────────

class _Strip extends StatelessWidget {
  const _Strip({required this.images, required this.offset});
  final List<String> images;
  final double offset;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OverflowBox(
          alignment: Alignment.topCenter,
          maxHeight: double.infinity,
          child: Transform.translate(
            offset: Offset(0, offset * 200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: images.map((url) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Opacity(
                    opacity: 0.7,
                    child: Image.asset(url, fit: BoxFit.cover, width: double.infinity, height: 180),
                  ),
                ),
              )).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemonLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gold = const Color(0xFFEAC16F);
    final black = const Color(0xFF131313);
    final paint = Paint()..color = gold;

    // Camera body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.28, size.width, size.height * 0.65),
      const Radius.circular(12),
    );
    canvas.drawRRect(bodyRect, paint);

    // Viewfinder bump (top center)
    final bumpPath = Path()
      ..moveTo(size.width * 0.32, size.height * 0.28)
      ..lineTo(size.width * 0.38, size.height * 0.08)
      ..quadraticBezierTo(size.width * 0.41, 0, size.width * 0.45, 0)
      ..lineTo(size.width * 0.55, 0)
      ..quadraticBezierTo(size.width * 0.59, 0, size.width * 0.62, size.height * 0.08)
      ..lineTo(size.width * 0.68, size.height * 0.28)
      ..close();
    canvas.drawPath(bumpPath, paint);

    // Flash button (top right)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.72, size.height * 0.08, size.width * 0.16, size.height * 0.14),
        const Radius.circular(3),
      ),
      paint,
    );

    // Lens outer ring (black)
    final cx = size.width * 0.48;
    final cy = size.height * 0.61;
    canvas.drawCircle(Offset(cx, cy), size.width * 0.265, Paint()..color = black);

    // Lens inner ring (gold)
    canvas.drawCircle(Offset(cx, cy), size.width * 0.215, paint);

    // Lens center (black)
    canvas.drawCircle(Offset(cx, cy), size.width * 0.165, Paint()..color = black);

    // Dollar sign in lens
    final tp = TextPainter(
      text: TextSpan(
        text: '\$',
        style: TextStyle(
          color: gold,
          fontSize: size.width * 0.22,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class _Card extends StatelessWidget {
  const _Card({required this.url, this.rotation = 0, this.offset = Offset.zero, this.opacity = 1.0, this.isMain = false, this.width = 170, this.height = 230});
  final String url;
  final double rotation;
  final Offset offset;
  final double opacity;
  final bool isMain;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: rotation * 3.14159 / 180,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isMain ? 48 : 40),
              boxShadow: isMain ? [BoxShadow(color: Colors.black54, blurRadius: 40, offset: const Offset(0, 20))] : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isMain ? 48 : 40),
              child: Image.asset(url, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }
}

class _TextInfo extends StatelessWidget {
  const _TextInfo({required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: _textColor, height: 1.1)),
          const SizedBox(height: 16),
          Text(body, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: _textColor.withOpacity(0.8), height: 1.5)),
        ],
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
          child: Row(
            children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: _primaryColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          width: 140,
          decoration: BoxDecoration(color: const Color(0xFF353535).withOpacity(0.4), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('UPCOMING', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white70)),
              SizedBox(height: 4),
              Text('Gala Dinner', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
              Text('20:00 • Ballroom A', style: TextStyle(fontSize: 10, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 64,
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [_primaryLight, _primaryColor]), borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]),
        child: const Center(child: Text('Continue', style: TextStyle(color: Color(0xFF402D00), fontSize: 18, fontWeight: FontWeight.w900))),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 64,
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [_primaryLight, _primaryColor]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]),
        child: Center(child: Text(label, style: const TextStyle(color: Color(0xFF402D00), fontSize: 18, fontWeight: FontWeight.w900))),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});
  final String label; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 64,
        decoration: BoxDecoration(border: Border.all(color: _primaryColor.withOpacity(0.4), width: 2), borderRadius: BorderRadius.circular(20)),
        child: Center(child: Text(label, style: const TextStyle(color: _primaryColor, fontSize: 18, fontWeight: FontWeight.w900))),
      ),
    );
  }
}
