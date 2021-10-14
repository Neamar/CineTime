import 'package:amplitude_flutter/amplitude.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static const _amplitudeKey = 'af30e5f865dd7eb9442d6a491cbac02f';
  static const _amplitudeDevKey = '845fcba9d80e7ead8619bba849d7243e';

  static final _amplitude = Amplitude.getInstance();

  static Future<void> init() async {
    await _amplitude.init(kReleaseMode ? _amplitudeKey : _amplitudeDevKey);
    await _amplitude.setServerUrl('https://api.eu.amplitude.com');
  }

  static Future<void> trackEvent(String eventName, [Map<String, dynamic>? properties]) => _amplitude.logEvent(eventName, eventProperties: properties);
}