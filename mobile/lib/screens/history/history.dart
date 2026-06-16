import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birdlens/services/bird_service.dart';
import '../../providers/history_provider.dart';
import '../../widgets/bird_card.dart';

class History extends ConsumerWidget {
  const History({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final history =
        ref.watch(
      historyProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "History",
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_forever,
            ),

            onPressed: () async {
              final confirm =
                  await showDialog<bool>(
                context: context,
                builder: (_) {
                  return AlertDialog(
                    title: const Text(
                      "Clear History?",
                    ),

                    content: const Text(
                      "Delete all scan history?",
                    ),

                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            false,
                          );
                        },

                        child: const Text(
                          "Cancel",
                        ),
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            true,
                          );
                        },

                        child: const Text(
                          "Delete",
                        ),
                      ),
                    ],
                  );
                },
              );

              if (confirm != true) {
                return;
              }

              if (!context.mounted) {
                return;
              }

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(
                  child:
                      CircularProgressIndicator(),
                ),
              );

              try {
                await ref
                    .read(
                      historyProvider
                          .notifier,
                    )
                    .clearHistory();
              } catch (e) {
                if (!context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  SnackBar(
                    content: Text(
                      e.toString(),
                    ),
                  ),
                );
              } finally {
                if (context.mounted &&
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).canPop()) {
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pop();
                }
              }
            },
          ),
        ],
      ),

      body: history.when(
        loading: () =>
            const Center(
          child:
              CircularProgressIndicator(),
        ),

        error: (
          error,
          stack,
        ) =>
            const Center(
          child: Text(
            "Failed to load history",
          ),
        ),

        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                "No birds scanned yet",
              ),
            );
          }
          return RefreshIndicator(
        onRefresh: () async {
       await ref.read(historyProvider.notifier,).refresh();
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
                    "${item.confidence.toStringAsFixed(1)}% confidence",

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
        "confidence":
            item.confidence,
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