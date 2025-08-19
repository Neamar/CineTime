import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/default_tracking.dart';
import 'package:amplitude_flutter/events/base_event.dart';
import 'package:cinetime/main.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static const _amplitudeKey = 'af30e5f865dd7eb9442d6a491cbac02f';
  static const _amplitudeDevKey = '845fcba9d80e7ead8619bba849d7243e';

  static final Amplitude _instance = Amplitude(Configuration(
    apiKey: kReleaseMode ? _amplitudeKey : _amplitudeDevKey,
    enableCoppaControl: true,
    defaultTracking: const DefaultTrackingOptions(
      sessions: true,
    ),
  ));

  static Future<void> init() async {
    // amplitude_flutter plugin requires Android API 21+.
    // See https://github.com/amplitude/Amplitude-Flutter/issues/24
    if (App.androidSdkVersion < 21) return;

    // Initialize Amplitude
    await _instance.isBuilt;
  }

  static Future<void> trackEvent(String eventName, [Map<String, dynamic>? properties]) =>
      _instance.track(BaseEvent(eventName, eventProperties: properties));
}
