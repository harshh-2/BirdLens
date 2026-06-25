import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/profile_provider.dart';
import '../../providers/history_provider.dart';
import 'package:birdlens/providers/auth_provider.dart';
class Profile extends ConsumerWidget {
  const Profile({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final profile =
        ref.watch(
      profileProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile",
        ),
      ),

      body: profile.when(
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

        data: (user) {
          return RefreshIndicator(
        onRefresh: () async {
       await ref.read(profileProvider.notifier,).refresh();
         },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.all(
              16,
            ),

            child: Column(
              children: [

                CircleAvatar(
                  radius: 45,

                  child: Text(
                    user.username
                        .substring(
                      0,
                      1,
                    )
                        .toUpperCase(),

                    style:
                        const TextStyle(
                      fontSize: 32,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(
                  height: 12.h,
                ),

                Text(
                  user.username,

                  style:
                      TextStyle(
                    fontSize: 24.sp,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                SizedBox(
                  height: 4.h,
                ),

                Text(
                  user.email,

                  style:
                      TextStyle(
                    color:
                        Colors.grey,
                    fontSize: 14.sp,
                  ),
                ),

                SizedBox(
                  height: 8.h,
                ),

                Text(
                  "Member since ${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}",

                  style:
                      TextStyle(
                    color: Colors
                        .grey
                        .shade600,
                  ),
                ),

                SizedBox(
                  height: 30.h,
                ),

                Align(
                  alignment:
                      Alignment
                          .centerLeft,

                  child: Text(
                    "Statistics",

                    style:
                        TextStyle(
                      fontSize:
                          20.sp,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                ),

                SizedBox(
                  height: 16.h,
                ),

                GridView.count(
                  shrinkWrap: true,

                  physics:
                      const NeverScrollableScrollPhysics(),

                  crossAxisCount:
                      2,

                  crossAxisSpacing:
                      12,

                  mainAxisSpacing:
                      12,

                  childAspectRatio:
                      1.4,

                  children: [

                    _StatCard(
                      icon:
                          Icons.history,
                      value: user
                          .totalScans
                          .toString(),
                      label:
                          "Scans",
                    ),

                    _StatCard(
                      icon:
                          Icons.favorite,
                      value: user
                          .favorites
                          .toString(),
                      label:
                          "Favorites",
                    ),

                    _StatCard(
                      icon:
                          Icons.pets,
                      value: user
                          .uniqueSpecies
                          .toString(),
                      label:
                          "Species",
                    ),

                    _StatCard(
                      icon: Icons
                          .calendar_month,
                      value:
                          "${user.createdAt.year}",
                      label:
                          "Joined",
                    ),
                  ],
                ),

                SizedBox(
                  height: 30.h,
                ),

                Align(
                  alignment:
                      Alignment
                          .centerLeft,

                  child: Text(
                    "Actions",

                    style:
                        TextStyle(
                      fontSize:
                          20.sp,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                ),

                SizedBox(
                  height: 12.h,
                ),

                Card(
                  child: Column(
                    children: [

                      ListTile(
                        leading:
                            const Icon(
                          Icons
                              .delete_outline,
                        ),

                        title:
                            const Text(
                          "Clear History",
                        ),

                        onTap:
                            () async {

                          final confirm =
                              await showDialog<bool>(
                            context:
                                context,

                            builder:
                                (_) {
                              return AlertDialog(
                                title:
                                    const Text(
                                  "Clear History?",
                                ),

                                content:
                                    const Text(
                                  "Delete all scan history?",
                                ),

                                actions: [

                                  TextButton(
                                    onPressed:
                                        () {
                                      Navigator.pop(
                                        context,
                                        false,
                                      );
                                    },

                                    child:
                                        const Text(
                                      "Cancel",
                                    ),
                                  ),

                                  TextButton(
                                    onPressed:
                                        () {
                                      Navigator.pop(
                                        context,
                                        true,
                                      );
                                    },

                                    child:
                                        const Text(
                                      "Delete",
                                    ),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirm !=
                              true) {
                            return;
                          }

                          await ref
                              .read(
                                historyProvider
                                    .notifier,
                              )
                              .clearHistory();
                        },
                      ),

                      const Divider(
                        height: 1,
                      ),

                      ListTile(
                        leading:
                            const Icon(
                          Icons.logout,
                          color:
                              Colors.red,
                        ),

                        title:
                            const Text(
                          "Logout",
                        ),

                       onTap: () async {
  await ref
      .read(
        authProvider.notifier,
      )
      .logout();

  if (!context.mounted) return;

  Navigator.pushNamedAndRemoveUntil(
    context,
    "/signIn",
    (route) => false,
  );
},
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  height: 30.h,
                ),
              ],
            ),
          ),
          );
        },
      ),
    );
  }
}

class _StatCard
    extends StatelessWidget {

  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black12,
            blurRadius: 6,
          ),
        ],
      ),

      child: Column(
        mainAxisAlignment:
            MainAxisAlignment
                .center,

        children: [

          Icon(icon),

          const SizedBox(
            height: 8,
          ),

          Text(
            value,

            style:
                const TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(label),
        ],
      ),
    );
  }
}