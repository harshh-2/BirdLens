import 'package:birdlens/services/dio_client.dart';

class HistoryService {

  Future<List<dynamic>>
      getHistory() async {

    final response =
        await DioClient.dio.get(
      "/history",
    );

    return response.data;
  }

  Future<void>
      clearHistory() async {

    await DioClient.dio.delete(
      "/history",
    );
  }
}