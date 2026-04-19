import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final showAmountInputProvider =
    NotifierProvider<ShowAmountInputController, bool>(
  ShowAmountInputController.new,
);

class ShowAmountInputController extends Notifier<bool> {
  static const _showAmountInputKey = 'show_amount_input';

  @override
  bool build() {
    _restorePreference();
    return true;
  }

  Future<void> _restorePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getBool(_showAmountInputKey);
    if (savedValue == null) {
      return;
    }
    state = savedValue;
  }

  Future<void> setShowAmountInput(bool enabled) async {
    if (enabled == state) {
      return;
    }

    state = enabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showAmountInputKey, enabled);
  }
}
