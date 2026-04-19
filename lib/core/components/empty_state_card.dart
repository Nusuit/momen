import 'package:flutter/material.dart';
import 'package:momen/core/constants/app_sizes.dart';

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSizes.p24),
        margin: const EdgeInsets.all(AppSizes.p24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.r24),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}
