import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/history_item.dart';
import '../services/history_service.dart';

final historyProvider =
    AsyncNotifierProvider<
        HistoryNotifier,
        List<HistoryItem>>(
  HistoryNotifier.new,
);

class HistoryNotifier
    extends AsyncNotifier<
        List<HistoryItem>> {

  final HistoryService _service =
      HistoryService();

  @override
  Future<List<HistoryItem>>
      build() async {

    final data =
        await _service.getHistory();

    return data
        .map<HistoryItem>(
          (e) =>
              HistoryItem.fromJson(e),
        )
        .toList();
  }

  Future<void> refresh()
      async {

    state =
        const AsyncLoading();

    state =
        await AsyncValue.guard(
      () async {

        final data =
            await _service
                .getHistory();

        return data
            .map<HistoryItem>(
              (e) =>
                  HistoryItem
                      .fromJson(e),
            )
            .toList();
      },
    );
  }

  Future<void>
      clearHistory() async {

    await _service.clearHistory();

    state =
        const AsyncData([]);
  }
}