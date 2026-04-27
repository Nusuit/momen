import 'package:flutter/material.dart';
import 'package:momen/core/constants/app_sizes.dart';
import 'package:momen/features/feed/presentation/pages/feed_page.dart';
import 'package:momen/features/spending/presentation/pages/dashboard_page.dart';

enum _FeedMoneyTab { feed, money }

class FeedMoneyPage extends StatefulWidget {
  const FeedMoneyPage({super.key});

  @override
  State<FeedMoneyPage> createState() => _FeedMoneyPageState();
}

class _FeedMoneyPageState extends State<FeedMoneyPage> {
  _FeedMoneyTab _activeTab = _FeedMoneyTab.feed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.p16,
            AppSizes.p12,
            AppSizes.p16,
            AppSizes.p8,
          ),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<_FeedMoneyTab>(
                  segments: const [
                    ButtonSegment<_FeedMoneyTab>(
                      value: _FeedMoneyTab.feed,
                      icon: Icon(Icons.calendar_month),
                      label: Text('Calendar'),
                    ),
                    ButtonSegment<_FeedMoneyTab>(
                      value: _FeedMoneyTab.money,
                      icon: Icon(Icons.pie_chart),
                      label: Text('Money'),
                    ),
                  ],
                  selected: {_activeTab},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _activeTab = selection.first;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _activeTab == _FeedMoneyTab.feed
                ? const FeedPage(key: ValueKey('feed_panel'))
                : const DashboardPage(key: ValueKey('money_panel')),
          ),
        ),
      ],
    );
  }
}
