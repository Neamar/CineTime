import 'package:cinetime/main.dart';
import 'package:cinetime/services/analytics_service.dart';
import 'package:cinetime/services/storage_service.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

/// Asks for a Play Store review, with the native in-app popup (after positive actions) and a fallback banner.
/// See https://developer.android.com/guide/playcore/in-app-review for the rules to follow:
/// no question before the popup, never alter it, and no button may trigger [InAppReview.requestReview].
class ReviewService {
  //#region Rules
  /// Debug only (ignored in release mode): skip the count and delay thresholds, but still make the real calls.
  static bool forceEligible = false;
  static bool get _force => !kReleaseMode && forceEligible;

  /// Number of dialogs closed after a positive action required before the popup is requested
  static const _popupMinActionCount = 2;

  /// Time since the app was first seen required before the popup is requested (let the user discover the app first)
  static const _popupMinAppAge = Duration(days: 4);

  /// Time since the last request (popup or banner click) required before the popup is requested again
  static const _popupMinDelay = Duration(days: 120);

  /// Number of dialogs closed after a positive action required before the banner is displayed
  static const _bannerMinActionCount = 4;

  /// Time since the last request (popup or banner click) required before the banner is displayed
  static const _bannerMinDelay = Duration(days: 30);

  /// Time before the banner is displayed again after being dismissed (about 6 months)
  static const _bannerDismissDelay = Duration(days: 182);

  /// Time before the banner is displayed or the popup is requested again after the banner was clicked (1 year): the user already went to the store
  static const _bannerClickDelay = Duration(days: 365);

  /// Time to let the dialog closing animation end before requesting the popup
  static const _closeAnimationDuration = Duration(milliseconds: 400);

  static final _review = InAppReview.instance;

  /// Only one request per session
  static bool _requestedThisSession = false;
  //#endregion

  //#region Init
  /// Remember when the app was first seen.
  /// Users updating the app already know it, so they are considered as installed for long enough (but still need to do the actions).
  static Future<void> init() async {
    try {
      if (StorageService.readReviewFirstSeenAt() != null) return;

      final now = DateTime.now();
      // If the user already has provider data (selected/favorite theaters, hidden movies), it means they updated the app, so consider them as installed for long enough to be eligible for the popup.
      await StorageService.saveReviewFirstSeenAt(StorageService.hasProviderData ? now.subtract(_popupMinAppAge) : now);
    } catch (e, s) {
      reportError(e, s);
    }
  }
  //#endregion

  //#region Popup
  /// To call when a showtime dialog is closed.
  /// [positiveAction] tells whether the user did at least one positive action in it (share, calendar, ticketing): several actions count for one.
  static Future<void> onShowtimeDialogClosed({required bool positiveAction}) async {
    if (!positiveAction) return;

    try {
      final actionCount = StorageService.readReviewActionCount() + 1;
      await StorageService.saveReviewActionCount(actionCount);
      if (!_isPopupEligible(actionCount)) return;

      _requestedThisSession = true;   // Before any await, so another dialog closed meanwhile can't request again
      await Future.delayed(_closeAnimationDuration);
      if (!await _review.isAvailable()) return;
      await _review.requestReview();    // May display nothing, because of Google's quota
      await StorageService.saveReviewLastRequestAt(DateTime.now());
      await AnalyticsService.trackEvent('Review requested', {'actionCount': actionCount});
    } catch (e, s) {
      reportError(e, s);
    }
  }

  static bool _isPopupEligible(int actionCount) {
    if (App.androidSdkVersion < 21 || _requestedThisSession) return false;
    if (_force) return true;

    final now = DateTime.now();
    final firstSeenAt = StorageService.readReviewFirstSeenAt();
    final lastRequestAt = StorageService.readReviewLastRequestAt();
    final bannerClickedAt = StorageService.readReviewBannerClickedAt();
    return actionCount >= _popupMinActionCount
      && firstSeenAt != null && now.difference(firstSeenAt) >= _popupMinAppAge
      && (lastRequestAt == null || now.difference(lastRequestAt) >= _popupMinDelay)
      && (bannerClickedAt == null || now.difference(bannerClickedAt) >= _bannerClickDelay);
  }
  //#endregion

  //#region Banner
  /// Fallback for users who never got (or ignored) the popup.
  /// In forced mode, the count and delay thresholds are skipped, but a click or dismiss still hides the banner.
  static bool get shouldShowBanner {
    try {
      final now = DateTime.now();
      final clickedAt = StorageService.readReviewBannerClickedAt();
      if (clickedAt != null && (_force || now.difference(clickedAt) < _bannerClickDelay)) return false;
      final dismissedAt = StorageService.readReviewBannerDismissedAt();
      if (dismissedAt != null && (_force || now.difference(dismissedAt) < _bannerDismissDelay)) return false;
      if (_force) return true;

      final lastRequestAt = StorageService.readReviewLastRequestAt();
      return StorageService.readReviewActionCount() >= _bannerMinActionCount
        && (lastRequestAt == null || now.difference(lastRequestAt) >= _bannerMinDelay);
    } catch (e, s) {
      reportError(e, s);
      return false;
    }
  }

  static Future<void> onBannerShown() async {
    try {
      await AnalyticsService.trackEvent('Review banner shown');
    } catch (e, s) {
      reportError(e, s);
    }
  }

  /// Open the store listing. Counts as a request, so the popup is not displayed right after.
  static Future<void> onBannerClicked() async {
    try {
      final now = DateTime.now();
      await StorageService.saveReviewBannerClickedAt(now);
      await StorageService.saveReviewLastRequestAt(now);
      await AnalyticsService.trackEvent('Review banner clicked');
      await _review.openStoreListing();
    } catch (e, s) {
      reportError(e, s);
    }
  }

  static Future<void> onBannerDismissed() async {
    try {
      await StorageService.saveReviewBannerDismissedAt(DateTime.now());
      await AnalyticsService.trackEvent('Review banner dismissed');
    } catch (e, s) {
      reportError(e, s);
    }
  }
  //#endregion
}
