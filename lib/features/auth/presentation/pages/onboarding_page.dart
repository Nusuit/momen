import 'dart:ui';
import 'package:flutter/material.dart';

// UI Constants from Stitch Design
const _bgColor = Color(0xFF131313);
const _primaryColor = Color(0xFFEAC16F);
const _primaryLight = Color(0xFFFFDFA3);
const _textColor = Color(0xFFE2E2E2);
const _textVariantColor = Color(0xFFD1C5B3);

const _img1 = 'https://hocvientaichinh.com.vn/wp-content/uploads/2018/05/cong-cu-quan-ly-tai-chinh-ca-nhan.jpg';
const _img2 = 'https://static.vinwonders.com/2023/01/du-lich-cung-ban-be-11.jpeg';
const _img3 = 'https://lh4.googleusercontent.com/KGInVu1OhDN8ACm-yjfaxrTrbbpaEdzrQhtVgabz-a1KdpjJ5P4Lup5_1wbHc26vYU92fuL-_ylQgXFsWxi0KuxNa-nhvylqTREWnxRIkOP8ozZLqjtEQCcZMHgdhLeTmdMCMvk';

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

  void _nextPage() {
    if (_currentIndex == 2) {
      widget.onComplete();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: MediaQuery.of(context).size.width * 0.1,
            right: MediaQuery.of(context).size.width * 0.1,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.08),
                    blurRadius: 100,
                    spreadRadius: 50,
                  )
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentIndex > 0)
                        GestureDetector(
                          onTap: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Icon(Icons.arrow_back, color: _primaryColor),
                        )
                      else
                        const SizedBox(width: 24),
                      GestureDetector(
                        onTap: widget.onComplete,
                        child: const Text(
                          'SKIP',
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    children: const [
                      _Slide1(),
                      _Slide2(),
                      _Slide3(),
                    ],
                  ),
                ),
                
                // Footer (Indicators & Button)
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          bool isActive = index == _currentIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 5),
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
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_primaryLight, _primaryColor],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ]
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: _nextPage,
                            child: Center(
                              child: Text(
                                _currentIndex == 2 ? 'Get Started' : 'Continue',
                                style: const TextStyle(
                                  color: Color(0xFF402D00),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Optional: Sign Up link if needed
                      if (_currentIndex == 2)
                        TextButton(
                          onPressed: widget.onSignUp,
                          child: Text(
                            'Create Account instead',
                            style: TextStyle(
                              color: _textColor.withOpacity(0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 48), // Spacer to keep height consistent
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildCard extends StatelessWidget {
  const _BuildCard({
    required this.imageUrl,
    required this.width,
    required this.height,
    this.opacity = 1.0,
    this.isCenter = false,
    this.overlay,
  });

  final String imageUrl;
  final double width;
  final double height;
  final double opacity;
  final bool isCenter;
  final Widget? overlay;

  static const ColorFilter _grayscaleFilter = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isCenter ? 48 : 40),
        boxShadow: [
          if (isCenter)
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 40,
              offset: const Offset(0, 20),
            )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isCenter ? 48 : 40),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: opacity < 1.0 
                  ? _grayscaleFilter 
                  : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
              child: Opacity(
                opacity: opacity,
                child: Image.network(imageUrl, fit: BoxFit.cover),
              ),
            ),
            if (overlay != null) overlay!,
          ],
        ),
      ),
    );
  }
}

class _Slide1 extends StatelessWidget {
  const _Slide1();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: const Offset(-60, -10),
                child: Transform.rotate(
                  angle: -12 * 3.14159 / 180,
                  child: const _BuildCard(imageUrl: _img1, width: 170, height: 230, opacity: 0.4),
                ),
              ),
              Transform.translate(
                offset: const Offset(60, 10),
                child: Transform.rotate(
                  angle: 12 * 3.14159 / 180,
                  child: const _BuildCard(imageUrl: _img2, width: 170, height: 230, opacity: 0.4),
                ),
              ),
              _BuildCard(
                imageUrl: _img3,
                width: 210,
                height: 290,
                isCenter: true,
                overlay: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(color: _primaryColor, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'VISUAL HISTORY',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Capture Spending through the Lens',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: _textColor, height: 1.15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Turn boring receipts into vivid visual memories. Just snap, enter the amount, and save your journey.',
                  style: TextStyle(fontSize: 16, color: _textColor.withOpacity(0.8), height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Slide2 extends StatelessWidget {
  const _Slide2();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Transform.translate(
                offset: const Offset(-65, -15),
                child: Transform.rotate(
                  angle: -12 * 3.14159 / 180,
                  child: const _BuildCard(imageUrl: _img3, width: 170, height: 240, opacity: 0.6),
                ),
              ),
              Transform.translate(
                offset: const Offset(65, 15),
                child: Transform.rotate(
                  angle: 12 * 3.14159 / 180,
                  child: const _BuildCard(imageUrl: _img1, width: 170, height: 240, opacity: 0.6),
                ),
              ),
              _BuildCard(
                imageUrl: _img2,
                width: 200,
                height: 280,
                isCenter: true,
                overlay: Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
              // Glass Card
              Positioned(
                bottom: 20,
                right: -20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      width: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFF353535).withOpacity(0.4),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: _primaryColor, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              const Text('UPCOMING', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1.2)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text('Gala Dinner', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 2),
                          const Text('20:00 • Ballroom A', style: TextStyle(fontSize: 10, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Connect Anonymously with Friends',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: _textColor, height: 1.15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Share your lifestyle and spending habits with your circle in total privacy. No one knows it\'s you.',
                  style: TextStyle(fontSize: 16, color: _textColor.withOpacity(0.8), height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Slide3 extends StatelessWidget {
  const _Slide3();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: const Offset(-60, 10),
                child: Transform.rotate(
                  angle: -12 * 3.14159 / 180,
                  child: const _BuildCard(imageUrl: _img2, width: 160, height: 210, opacity: 0.6),
                ),
              ),
              Transform.translate(
                offset: const Offset(60, -10),
                child: Transform.rotate(
                  angle: 12 * 3.14159 / 180,
                  child: const _BuildCard(imageUrl: _img3, width: 160, height: 210, opacity: 0.6),
                ),
              ),
              const _BuildCard(
                imageUrl: _img1,
                width: 190,
                height: 260,
                isCenter: true,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: _textColor, height: 1.15),
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
        ),
      ],
    );
  }
}
