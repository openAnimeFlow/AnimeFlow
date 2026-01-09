import 'package:anime_flow/http/api_path.dart';
import 'package:anime_flow/http/dio/dio_request.dart';

class Request {
  static Future<Map<String, dynamic>> getReleases() async {
    return await dioRequest
        .get(CommonApi.githubReleases)
        .then((onValue) => onValue.data);
  }
}
