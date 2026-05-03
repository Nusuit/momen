import 'package:flutter/material.dart';
import 'package:momen/core/constants/app_sizes.dart';
import 'package:momen/features/spending/presentation/pages/dashboard_page.dart';
import 'package:momen/features/spending/presentation/pages/spending_calendar_page.dart';

enum _FeedMoneyTab { calendar, money }

class FeedMoneyPage extends StatefulWidget {
  const FeedMoneyPage({super.key});

  @override
  State<FeedMoneyPage> createState() => _FeedMoneyPageState();
}

class _FeedMoneyPageState extends State<FeedMoneyPage> {
  _FeedMoneyTab _activeTab = _FeedMoneyTab.calendar;

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
                      value: _FeedMoneyTab.calendar,
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
            child: _activeTab == _FeedMoneyTab.calendar
                ? SpendingCalendarPage(
                    key: const ValueKey('calendar_panel'),
                    onOpenMoney: () {
                      setState(() => _activeTab = _FeedMoneyTab.money);
                    },
                  )
                : const DashboardPage(key: ValueKey('money_panel')),
          ),
        ),
      ],
    );
  }
}
