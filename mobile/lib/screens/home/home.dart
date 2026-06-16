import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/history_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/bird_service.dart';
import 'package:birdlens/providers/navigation_provider.dart';
class Home extends ConsumerWidget {
  const Home({
    super.key,
  });

  Future<void> openBird(
    BuildContext context,
    String birdId, {
    double? confidence,
  }) async {
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
        birdId,
      );

      if (!context.mounted) {
        return;
      }

      Navigator.pop(context);

      Navigator.pushNamed(
        context,
        "/birdDetails",
        arguments: {
          "bird": bird,
          "confidence": confidence,
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
  }

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final history =
        ref.watch(
      historyProvider,
    );

    final favorites =
        ref.watch(
      favoritesProvider,
    );

    final profile =
        ref.watch(
      profileProvider,
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref
                .read(
                  historyProvider.notifier,
                )
                .refresh(),

            ref
                .read(
                  favoritesProvider.notifier,
                )
                .refresh(),

            ref
                .read(
                  profileProvider.notifier,
                )
                .refresh(),
          ]);
        },

        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          padding:
              const EdgeInsets.all(16),

          children: [

            const SizedBox(
              height: 12,
            ),

            const Text(
              "BirdLens",
              style: TextStyle(
                fontSize: 30,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              "Discover birds around you",
              style: TextStyle(
                color:
                    Colors.grey.shade600,
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            profile.when(
              loading: () =>
                  const Center(
                child:
                    CircularProgressIndicator(),
              ),

              error:
                  (_, __) =>
                      const SizedBox(),

              data: (profile) {
                return Row(
                  children: [

                    Expanded(
                      child: _StatCard(
                        title:
                            "Scans",
                        value: profile
                            .totalScans
                            .toString(),
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: _StatCard(
                        title:
                            "Favorites",
                        value: profile
                            .favorites
                            .toString(),
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: _StatCard(
                        title:
                            "Species",
                        value: profile
                            .uniqueSpecies
                            .toString(),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(
              height: 30,
            ),
Row(
  mainAxisAlignment:
      MainAxisAlignment.spaceBetween,
  children: [

    const Text(
      "Recent Scans",
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    TextButton(
      onPressed: () {
        ref
            .read(
              navigationProvider.notifier,
            )
            .changeTab(2);
      },

      child: const Text(
        "View All",
      ),
    ),
  ],
),

            const SizedBox(
              height: 12,
            ),

            history.when(
              loading: () =>
                  const Center(
                child:
                    CircularProgressIndicator(),
              ),

              error:
                  (_, __) =>
                      const Text(
                "Failed to load history",
              ),

              data: (items) {

                if (items.isEmpty) {
                  return const Text(
                    "No scans yet",
                  );
                }

                return SizedBox(
                  height: 170,

                  child: ListView.builder(
                    scrollDirection:
                        Axis.horizontal,

                    itemCount:
                        items.length > 5
                            ? 5
                            : items.length,

                    itemBuilder:
                        (
                      context,
                      index,
                    ) {
                      final item =
                          items[index];

                      return GestureDetector(
                        onTap: () {
                          openBird(
                            context,
                            item.birdId,
                            confidence:
                                item.confidence,
                          );
                        },

                        child: Container(
                          width: 150,

                          margin:
                              const EdgeInsets.only(
                            right: 12,
                          ),

                          child: Card(
                            clipBehavior:
                                Clip.antiAlias,

                            child: Column(
                              children: [

                                Expanded(
                                  child:
                                      Image.network(
                                    item.imageUrl,
                                    width:
                                        double.infinity,
                                    fit:
                                        BoxFit.cover,
                                  ),
                                ),

                                Padding(
                                  padding:
                                      const EdgeInsets.all(
                                    8,
                                  ),

                                  child: Text(
                                    item.name.replaceAll("_"," "),
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(
              height: 30,
            ),

            Row(
  mainAxisAlignment:
      MainAxisAlignment.spaceBetween,
  children: [

    const Text(
      "Favorites",
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    TextButton(
      onPressed: () {
        ref
            .read(
              navigationProvider.notifier,
            )
            .changeTab(1);
      },

      child: const Text(
        "View All",
      ),
    ),
  ],
),

            const SizedBox(
              height: 12,
            ),

            favorites.when(
              loading: () =>
                  const Center(
                child:
                    CircularProgressIndicator(),
              ),

              error:
                  (_, __) =>
                      const Text(
                "Failed to load favorites",
              ),

              data: (items) {

                if (items.isEmpty) {
                  return const Text(
                    "No favorites yet",
                  );
                }

                return SizedBox(
                  height: 170,

                  child: ListView.builder(
                    scrollDirection:
                        Axis.horizontal,

                    itemCount:
                        items.length > 5
                            ? 5
                            : items.length,

                    itemBuilder:
                        (
                      context,
                      index,
                    ) {
                      final item =
                          items[index];

                      return GestureDetector(
                        onTap: () {
                          openBird(
                            context,
                            item.birdId,
                          );
                        },

                        child: Container(
                          width: 150,

                          margin:
                              const EdgeInsets.only(
                            right: 12,
                          ),

                          child: Card(
                            clipBehavior:
                                Clip.antiAlias,

                            child: Column(
                              children: [

                                Expanded(
                                  child:
                                      Image.network(
                                    item.imageUrl,
                                    width:
                                        double.infinity,
                                    fit:
                                        BoxFit.cover,
                                  ),
                                ),

                                Padding(
                                  padding:
                                      const EdgeInsets.all(
                                    8,
                                  ),

                                  child: Text(
                                    item.name.replaceAll("_"," "),
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(
              height: 30,
            ),

            const Text(
              "About BirdLens",
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  16,
                ),

                child: Text(
                  "BirdLens is an AI-powered bird identification app that helps users recognize bird species from photos. Scan birds, build your personal observation history, save favorites, and explore detailed species information.",
                  style: TextStyle(
                    color:
                        Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            Center(
              child: Text(
                "Made by Harsh",
                style: TextStyle(
                  color:
                      Colors.grey.shade600,
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard
    extends StatelessWidget {

  final String title;
  final String value;

  const _StatCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical: 18,
        ),

        child: Column(
          children: [

            Text(
              value,
              style:
                  const TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(title),
          ],
        ),
      ),
    );
  }
}