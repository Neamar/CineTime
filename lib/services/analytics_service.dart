import 'package:amplitude_flutter/amplitude.dart';
import 'package:cinetime/main.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static const _amplitudeKey = 'af30e5f865dd7eb9442d6a491cbac02f';
  static const _amplitudeDevKey = '845fcba9d80e7ead8619bba849d7243e';

  static Amplitude? _amplitude;

  static Future<void> init() async {
    // amplitude_flutter plugin requires Android API 21+.
    // See https://github.com/amplitude/Amplitude-Flutter/issues/24
    if (App.androidSdkVersion < 21) return;

    _amplitude = Amplitude.getInstance();
    await _amplitude!.init(kReleaseMode ? _amplitudeKey : _amplitudeDevKey);
    //await _amplitude.setServerUrl('https://api.eu.amplitude.com');    // Setting EU server throw a silence "wrong apiKey" error
    await _amplitude!.enableCoppaControl();
    await _amplitude!.trackingSessionEvents(true);
  }

  static Future<void> trackEvent(String eventName, [Map<String, dynamic>? properties]) async =>
      await _amplitude?.logEvent(eventName, eventProperties: properties);
}
