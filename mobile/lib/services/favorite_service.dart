import 'package:birdlens/services/dio_client.dart';

class FavoritesService {

  Future<List<dynamic>>
      getFavorites() async {

    final response =
        await DioClient.dio.get(
      "/favorites",
    );

    return response.data;
  }

  Future<void> addFavorite(
    String birdId,
  ) async {

    await DioClient.dio.post(
      "/favorites",
      data: {
        "bird_id": birdId,
      },
    );
  }

  Future<void> removeFavorite(
    String birdId,
  ) async {

    await DioClient.dio.delete(
      "/favorites",
      data: {
        "bird_id": birdId,
      },
    );
  }
}