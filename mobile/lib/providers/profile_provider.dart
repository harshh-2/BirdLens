import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import '../services/profile_service.dart';

final profileProvider =
    AsyncNotifierProvider<
        ProfileNotifier,
        UserProfile>(
  ProfileNotifier.new,
);

class ProfileNotifier
    extends AsyncNotifier<
        UserProfile> {

  final ProfileService _service =
      ProfileService();

  @override
  Future<UserProfile>
      build() async {

    return await _service
        .getProfile();
  }

  Future<void> refresh()
      async {

    ref.invalidateSelf();

    await future;
  }
}