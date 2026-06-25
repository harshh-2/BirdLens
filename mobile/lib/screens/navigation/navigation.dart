import 'package:flutter/material.dart';
import 'package:birdlens/themes/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import '../home/home.dart';
import '../favorites/favorites.dart';
import '../history/history.dart';
import '../profile/profile.dart';
import 'package:birdlens/services/image_picker_service.dart';
import 'package:birdlens/services/bird_service.dart';
import 'package:birdlens/models/bird.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birdlens/providers/history_provider.dart';
import 'package:birdlens/widgets/prediction_widget.dart';
import 'package:birdlens/providers/navigation_provider.dart';
class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() =>
      _MainNavigationState();
}

class _MainNavigationState
    extends ConsumerState<MainNavigation> {

Future<void> handlePrediction(
  Future<XFile?> Function() picker,
) async {

  final image = await picker();

  if (image == null) return;

  try {

    showDialog(
  context: context,
  barrierDismissible: false,
  builder: (_) =>
      const LoadingDialog(
    title: "Identifying Bird...",
    subtitle:
        "Analyzing image using AI",
  ),
);

    final result =
        await BirdService()
            .predictBird(image);
    
    await ref
    .read(
      historyProvider.notifier,
    )
    .refresh();

    final bird =
        Bird.fromJson(
      result["bird"],
    );

    final confidence =
        (result["confidence"] as num)
            .toDouble();
    
    

    if (
      Navigator.of(
        context,
        rootNavigator: true,
      ).canPop()
    ) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pop();
    }

    if (!mounted) return;

    Navigator.pushNamed(
      context,
      "/birdDetails",
      arguments: {
        "bird": bird,
        "confidence": confidence,
      },
    );

  } catch (e) {
    if (
      Navigator.of(
        context,
        rootNavigator: true,
      ).canPop()
    ) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pop();
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          "Failed to identify bird. Please try again.",
        ),
      ),
    );
  }
}


  final List<Widget> screens = [
    Home(),
    Favorites(),
    History(),
    Profile(),
  ];


Widget navItem({
  required IconData icon,
  required String label,
  required int index,
  required int currentIndex,
}) {
  final isSelected =
      currentIndex == index;

  return InkWell(
    onTap: () {
  ref
      .read(
        navigationProvider.notifier,
      )
      .changeTab(index);
},

    child: SizedBox(
      width: 70,

      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [

          AnimatedContainer(
            duration:
                const Duration(
              milliseconds: 250,
            ),

            height: 3,
            width:
                isSelected
                    ? 28
                    : 0,

            decoration:
                BoxDecoration(
              color:
                  colors['primary'],
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Icon(
            icon,
            color: isSelected
                ? colors['primary']
                : colors['textLight'],
          ),

          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected
                  ? colors['primary']
                  : colors['textLight'],
            ),
          ),
        ],
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    final currentIndex =
    ref.watch(
      navigationProvider,
    );
    return Scaffold(
      body: IndexedStack(
  index: currentIndex,
  children: screens,
),

      floatingActionButton:
          FloatingActionButton(
          heroTag: "scanButton",
          backgroundColor: colors['primary'],
          elevation: 10,
          onPressed: () {
          showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(20),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [

                ListTile(
                  leading:
                      const Icon(
                    Icons.camera_alt,
                  ),
                  title: const Text(
                    "Take Photo",
                  ),
                  onTap: () async{
                    Navigator.pop(context);
                    await handlePrediction(ImagePickerService.pickFromCamera,); // open camera
                  },
                ),
                ListTile(
                  leading:
                      const Icon(
                    Icons.photo,
                  ),
                  title: const Text(
                    "Choose from Gallery",
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await handlePrediction(ImagePickerService.pickFromGallery,);             // open gallery
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  },
  child: Icon(
    Icons.camera_alt,
    color: colors['white'],
  ),
),

      floatingActionButtonLocation:
          FloatingActionButtonLocation
              .centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape:
            const CircularNotchedRectangle(),

        notchMargin: 8,

        color: colors['card'],

        elevation: 15,

        child: SizedBox(
          height: 65,

          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceAround,

            children: [

              navItem(
                icon: Icons.home,
                label: "Home",
                index: 0,
                currentIndex: currentIndex,
              ),

              navItem(
                icon: Icons.favorite,
                label: "Favorites",
                index: 1,
                currentIndex: currentIndex,
              ),

              const SizedBox(
                width: 50,
              ),

              navItem(
                icon: Icons.history,
                label: "History",
                index: 2,
                currentIndex: currentIndex,
              ),

              navItem(
                icon: Icons.person,
                label: "Profile",
                index: 3,
                currentIndex: currentIndex,
              ),
            ],
          ),
        ),
      ),
    );
  }
}