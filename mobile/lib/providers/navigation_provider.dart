import 'package:flutter_riverpod/flutter_riverpod.dart';

final navigationProvider =
    NotifierProvider<
        NavigationNotifier,
        int>(
  NavigationNotifier.new,
);

class NavigationNotifier
    extends Notifier<int> {

  @override
  int build() {
    return 0;
  }

  void changeTab(
    int index,
  ) {
    state = index;
  }
}