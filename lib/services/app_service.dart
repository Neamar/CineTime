import 'api_client.dart';

class AppService {
  //#region Init
  static final AppService instance = AppService();

  final ApiClient apiClient = ApiClient();
  static ApiClient get api => instance.apiClient;
  //#endregion
}