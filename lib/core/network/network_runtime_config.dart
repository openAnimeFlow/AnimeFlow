/// Runtime values supplied by the application to the network layer.
class NetworkRuntimeConfig {
  NetworkRuntimeConfig._();

  static String appVersion = '1.0.0';

  static void configure({required String appVersion}) {
    NetworkRuntimeConfig.appVersion = appVersion;
  }
}
