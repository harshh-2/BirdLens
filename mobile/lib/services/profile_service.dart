import '../models/profile.dart';
import 'dio_client.dart';

class ProfileService {

  Future<UserProfile>
      getProfile() async {
    final response =
        await DioClient.dio.get(
      "/user",
    );
    return UserProfile.fromJson(
      response.data,
    );
  }
}