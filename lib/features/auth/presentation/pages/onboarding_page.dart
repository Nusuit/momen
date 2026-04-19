import 'package:flutter/material.dart';
import 'package:momen/core/components/buttons/primary_button.dart';
import 'package:momen/core/constants/app_sizes.dart';

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
  int step = 0;

  static const List<_OnboardingSlide> slides = [
    _OnboardingSlide(
      title: 'Capture spending through the lens',
      description: 'Save money moments with context, not just numbers.',
      icon: Icons.camera_alt,
    ),
    _OnboardingSlide(
      title: 'Finance tracking that feels social',
      description: 'See dashboards and weekly recaps with friends.',
      icon: Icons.pie_chart,
    ),
    _OnboardingSlide(
      title: 'Share with privacy first',
      description: 'Post naturally and keep identity under control.',
      icon: Icons.lock,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final slide = slides[step];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p24),
          child: Column(
            children: [
              const Spacer(),
              CircleAvatar(
                radius: 44,
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: Icon(slide.icon, size: AppSizes.i32),
              ),
              const SizedBox(height: AppSizes.p24),
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSizes.p12),
              Text(
                slide.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  slides.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSizes.p4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == step
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.p24),
              PrimaryButton(
                label: step == slides.length - 1 ? 'Get Started' : 'Continue',
                onPressed: () {
                  if (step == slides.length - 1) {
                    widget.onComplete();
                    return;
                  }
                  setState(() => step += 1);
                },
              ),
              const SizedBox(height: AppSizes.p12),
              OutlinedButton(
                onPressed: widget.onSignUp,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}
