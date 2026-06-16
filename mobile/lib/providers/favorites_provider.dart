import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/favorite_item.dart';
import '../services/favorite_service.dart';

final favoritesProvider =
    AsyncNotifierProvider<
        FavoritesNotifier,
        List<FavoriteItem>>(
  FavoritesNotifier.new,
);

class FavoritesNotifier
    extends AsyncNotifier<
        List<FavoriteItem>> {

  final FavoritesService _service =
      FavoritesService();

  @override
  Future<List<FavoriteItem>>
      build() async {

    final data =
        await _service
            .getFavorites();

    return data
        .map<FavoriteItem>(
          (e) =>
              FavoriteItem
                  .fromJson(e),
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
                .getFavorites();

        return data
            .map<FavoriteItem>(
              (e) =>
                  FavoriteItem
                      .fromJson(e),
            )
            .toList();
      },
    );
  }

  Future<void> addFavorite(
    String birdId,
  ) async {

    await _service
        .addFavorite(
      birdId,
    );

    await refresh();
  }

  Future<void>
      removeFavorite(
    String birdId,
  ) async {

    await _service
        .removeFavorite(
      birdId,
    );

    await refresh();
  }
}
final favoriteIdsProvider =
    Provider<Set<String>>((ref) {

  final favorites =
      ref.watch(
        favoritesProvider,
      );

  return favorites.when(
    data: (items) => items
        .map(
          (e) => e.birdId,
        )
        .toSet(),

    loading: () => <String>{},

    error: (_, __) => <String>{},
  );
});