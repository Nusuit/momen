import 'package:flutter/material.dart';
import 'package:momen/core/components/empty_state_card.dart';
import 'package:momen/core/constants/app_sizes.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSizes.p16),
      child: EmptyStateCard(
        title: 'Feed is empty. Connect database to load posts.',
      ),
    );
  }
}
