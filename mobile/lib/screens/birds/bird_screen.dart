import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:birdlens/models/bird.dart';
import 'package:birdlens/themes/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birdlens/providers/favorites_provider.dart';
class BirdScreen extends ConsumerStatefulWidget {

  final Bird bird;
  final double? confidence;

  const BirdScreen({
    super.key,
    required this.bird,
    this.confidence,
  });

  @override
  ConsumerState<BirdScreen> createState() =>
      _BirdScreenState();
}

class _BirdScreenState
    extends ConsumerState<BirdScreen> {
  bool _favoriteLoading = false;

  Future<void> toggleFavorite() async {
    if (_favoriteLoading) return;

    setState(() {
      _favoriteLoading = true;
    });

    try {
      final favoriteIds = ref.read(
        favoriteIdsProvider,
      );

      final isFavorite =
          favoriteIds.contains(
            widget.bird.id,
          );

      final notifier = ref.read(
        favoritesProvider.notifier,
      );

      if (isFavorite) {
        await notifier.removeFavorite(
          widget.bird.id,
        );
      } else {
        await notifier.addFavorite(
          widget.bird.id,
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Failed to update favorite",
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _favoriteLoading = false;
        });
      }
    }
  }

 @override
Widget build(BuildContext context) {
  final favoriteIds =
    ref.watch(
      favoriteIdsProvider,
    );

final isFavorite =
    favoriteIds.contains(
      widget.bird.id,
    );
  return Scaffold(
    backgroundColor: colors['background'],

    body: CustomScrollView(
      slivers: [

        SliverAppBar(
          expandedHeight: 320.h,
          pinned: true,
          backgroundColor: Colors.white,

          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),

            actions: [
          _favoriteLoading
      ? const Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.red,
            ),
          ),
        )
      : IconButton(
          icon: Icon(
            isFavorite
                ? Icons.favorite
                : Icons.favorite_border,
            color: Colors.red,
          ),
          onPressed: toggleFavorite,
        ),
],

          flexibleSpace: FlexibleSpaceBar(
            background: Image.network(
              widget.bird.imageUrl,
              fit: BoxFit.cover,

              errorBuilder:
                  (_, __, ___) {
                return Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 80,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(20.w),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  widget.bird.name
                      .replaceAll("_", " "),
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8.h),

                Text(
                  widget.bird.scientificName,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontStyle:
                        FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),

                SizedBox(height: 20.h),

if (widget.confidence != null) ...[
  Container(
    padding: EdgeInsets.symmetric(
      horizontal: 16.w,
      vertical: 10.h,
    ),
    decoration: BoxDecoration(
      color: Colors.green.shade100,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      "${widget.confidence!.toStringAsFixed(1)}% Match",
      style: const TextStyle(
        fontWeight: FontWeight.w600,
      ),
    ),
  ),

  SizedBox(height: 30.h),
] else ...[
  SizedBox(height: 10.h),
],

                Text(
                  "About",
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                SizedBox(height: 10.h),

                Text(
                  widget.bird.description,
                  style: TextStyle(
                    height: 1.6,
                    fontSize: 15.sp,
                  ),
                ),

                SizedBox(height: 25.h),

                Text(
                  "Habitat",
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                SizedBox(height: 12.h),

                Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.all(16.w),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: Row(
                    children: [

                      const Icon(
                        Icons.forest,
                      ),

                      SizedBox(width: 12.w),

                      Expanded(
                        child: Text(
                          widget.bird.habitat,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 25.h),

                Text(
                  "Conservation Status",
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                SizedBox(height: 12.h),

                Chip(
                  label: Text(
                    widget.bird
                        .conservationStatus,
                  ),
                ),

                SizedBox(height: 40.h),

                SizedBox(
                  width: double.infinity,
                  height: 55.h,

                  child:
                      ElevatedButton.icon(
                    icon: _favoriteLoading
    ? const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.red,
        ),
      )
    : Icon(
        isFavorite
            ? Icons.favorite
            : Icons.favorite_border,
      ),
                    label: Text(
                      isFavorite
                          ? "Remove From Favorites"
                          : "Add To Favorites",
                    ),
                    onPressed: _favoriteLoading
                        ? null
                        : toggleFavorite,
                  ),
                ),

                SizedBox(height: 12.h),

                SizedBox(
                  width: double.infinity,
                  height: 55.h,

                  child:
                      OutlinedButton.icon(
                    icon: const Icon(
                      Icons.camera_alt,
                    ),
                    label: const Text(
                      "Scan Another Bird",
                    ),
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },
                  ),
                ),

                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}}