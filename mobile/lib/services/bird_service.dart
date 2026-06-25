import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:birdlens/services/dio_client.dart';
import 'package:birdlens/models/bird.dart';
class BirdService {

  Future<Map<String, dynamic>>
      predictBird(XFile image) async {
    try {
      final bytes = await image.readAsBytes();

      final formData =
          FormData.fromMap({
        "image":
            MultipartFile.fromBytes(
          bytes,
          filename: image.name,
        ),
      });

      final response =
          await DioClient.dio.post(
        "/birds/predict",
        data: formData,
      );
      return response.data;
    } on DioException catch (e) {
      rethrow;
    }
  }
  Future<Bird> getBirdDetails(
  String birdId,
) async {

  final response =
      await DioClient.dio.get(
    "/birds/$birdId",
  );

  return Bird.fromJson(
    response.data,
  );
}
}
