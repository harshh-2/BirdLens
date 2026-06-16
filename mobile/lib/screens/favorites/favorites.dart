import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birdlens/services/bird_service.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/bird_card.dart';

class Favorites extends ConsumerWidget {
  const Favorites({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final favorites =
        ref.watch(
      favoritesProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Favorites",
        ),
      ),

      body: favorites.when(
        loading: () =>
            const Center(
          child:
              CircularProgressIndicator(),
        ),

        error: (
          error,
          stack,
        ) =>
            Center(
          child: Text(
            error.toString(),
          ),
        ),

        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                "No favorite birds yet",
              ),
            );
          }
        return RefreshIndicator(
        onRefresh: () async {
       await ref.read(favoritesProvider.notifier,).refresh();
         },
            child: GridView.builder(
            padding:
                const EdgeInsets.all(
              12,
            ),

            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,

              crossAxisSpacing:
                  12,

              mainAxisSpacing:
                  12,

              childAspectRatio:
                  0.60,
            ),

            itemCount:
                items.length,

            itemBuilder:
                (
              context,
              index,
            ) {
              final item =
                  items[index];

              return BirdCard(
                birdId:
                    item.birdId,

                name:
                    item.name,

                habitat:
                    item.habitat,

                imageUrl:
                    item.imageUrl,

                  onTap: () async {

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {

    final bird =
        await BirdService()
            .getBirdDetails(
      item.birdId,
    );

    if (!context.mounted) return;

    Navigator.pop(context);

    Navigator.pushNamed(
      context,
      "/birdDetails",
      arguments: {
        "bird": bird,
      },
    );

  } catch (e) {

    if (Navigator.of(
      context,
      rootNavigator: true,
    ).canPop()) {
      Navigator.pop(context);
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          "Failed to load bird",
        ),
      ),
    );
  }
                },
              );
            },
          ),
        );
        },
      ),
    );
  }
}