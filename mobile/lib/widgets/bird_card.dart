import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birdlens/providers/favorites_provider.dart';
class BirdCard extends ConsumerWidget {

  final String birdId;
  final String name;
  final String habitat;
  final String imageUrl;
  final VoidCallback? onTap;
  const BirdCard({
    super.key,
    required this.birdId,
    required this.name,
    required this.habitat,
    required this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final favoriteIds =
    ref.watch(
      favoriteIdsProvider,
    );

final isFavorite =
    favoriteIds.contains(
      birdId,
    );
    return InkWell(
      borderRadius:
          BorderRadius.circular(18),
      onTap: onTap , 
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(18),

          boxShadow: [
            BoxShadow(
              color:
                  Colors.black12,
              blurRadius: 8,
              offset:
                  const Offset(0, 2),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Expanded(
              flex: 7,

              child: Stack(
                children: [

                  ClipRRect(
                    borderRadius:
                        const BorderRadius.only(
                      topLeft:
                          Radius.circular(
                        18,
                      ),
                      topRight:
                          Radius.circular(
                        18,
                      ),
                    ),

                    child: Image.network(
                      imageUrl,

                      width:
                          double.infinity,

                      height:
                          double.infinity,

                      fit: BoxFit.cover,

                      errorBuilder:
                          (_, __, ___) {

                        return Container(
                          color:
                              Colors.grey
                                  .shade200,

                          child:
                              const Center(
                            child: Icon(
                              Icons.pets,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  Positioned(
                    top: 8,
                    right: 8,

                    child: CircleAvatar(
                      radius: 16,

                      backgroundColor:
                          Colors.white,

                      child: IconButton(
                        padding:
                            EdgeInsets.zero,

                        onPressed: () async {

  final notifier =
      ref.read(
        favoritesProvider.notifier,
      );

  if (isFavorite) {

    await notifier
        .removeFavorite(
      birdId,
    );

  } else {

    await notifier
        .addFavorite(
      birdId,
    );
  }
},
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite
                              : Icons
                                  .favorite_border,

                          color:
                              Colors.red,

                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

Expanded(
  flex: 3,
  child: Padding(
    padding: const EdgeInsets.all(8),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [

        Text(
          name.replaceAll("_", " "),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          habitat,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    ),
  ),
),
          ],
        ),
      ),
    );
  }
}