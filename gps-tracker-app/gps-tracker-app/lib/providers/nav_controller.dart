import 'package:flutter/foundation.dart';

/// Bottom-navigation state. 0 Home · 1 Route · 2 Map · 3 Vehicle · 4 Profile
class NavController extends ChangeNotifier {
  int index = 0;

  void go(int i) {
    if (i == index) return;
    index = i;
    notifyListeners();
  }
}
