import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import 'package:loopweek/data/services/settings_service.dart';

/// Launches the Google Play review dialog. A separate interface so unit
/// tests can substitute a fake — the real one touches a platform channel,
/// which must never load during widget smoke tests.
abstract class ReviewLauncher {
  /// True when this device can show the Play review dialog.
  Future<bool> isAvailable();

  /// Opens the quota-limited Play in-app review dialog.
  Future<void> requestReview();

  /// Opens the Play Store listing in the Play app (no quota).
  Future<void> openStoreListing();
}

/// The real launcher, backed by the in_app_review plugin.
class PlayReviewLauncher implements ReviewLauncher {
  const PlayReviewLauncher();

  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();

  @override
  Future<void> requestReview() => InAppReview.instance.requestReview();

  @override
  Future<void> openStoreListing() =>
      InAppReview.instance.openStoreListing();
}

/// Decides when to ask for a Play rating, and asks.
///
/// Fires only at earned moments — the caller decides what counts (Loopweek:
/// completing the third task in a session, dismissing the fresh-week ritual
/// banner). All other gating lives here:
///
/// - Playstore flavor only: [donationMode] — the github flavor never carries
///   an active review flow, mirroring the donation-mode split.
/// - 30-day cooldown after ANY attempt (dialog shown or declined — the API
///   exposes no outcome, so every attempt costs the full cooldown),
///   persisted in SharedPreferences via [SettingsService].
/// - Once per session, so a burst of task check-offs can only ever reach
///   the dialog once before the cooldown takes over.
///
/// Data-layer service per the app architecture: no BuildContext, no UI.
/// Every call is fire-and-forget safe — [maybeAskForReview] never throws
/// (platform-channel failures are logged and swallowed), so triggering it
/// right after a task completion can never surface an error to the user or
/// block the toggle's await chain (ANR lens: nothing on the platform
/// channel sits under a UI gesture's critical path).
class ReviewService {
  ReviewService({
    required SettingsService settings,
    ReviewLauncher? launcher,
    DateTime Function()? clock,
  }) : _settings = settings,
       _launcher = launcher ?? const PlayReviewLauncher(),
       _now = clock ?? DateTime.now;

  final SettingsService _settings;
  final ReviewLauncher _launcher;
  final DateTime Function() _now;

  /// Quota guard mirror: Google throttles requestReview() unpredictably and
  /// silently, so the app enforces its own visible rule instead.
  static const _cooldown = Duration(days: 30);

  /// Set on the first earned moment that passes all gates this session.
  bool _askedThisSession = false;

  /// True when the user can currently be asked: earned moments should call
  /// [maybeAskForReview] and ignore the answer; this getter exists for the
  /// settings row, which needs a stable target at any time.
  bool get canAskThisSession => !_askedThisSession;

  /// Evaluated at an earned moment. Returns true if the review dialog was
  /// actually requested (all gates passed); callers may ignore it.
  Future<bool> maybeAskForReview() async {
    if (donationMode != DonationMode.iap) return false;
    if (_askedThisSession) return false;
    final last = _settings.reviewLastAttemptMs;
    final now = _now().millisecondsSinceEpoch;
    if (last != null && now - last < _cooldown.inMilliseconds) {
      return false;
    }
    try {
      if (!await _launcher.isAvailable()) return false;
      // Mark BEFORE awaiting the dialog: requestReview() resolves when the
      // dialog closes (or is silently skipped by Play), and a decline or a
      // process death mid-dialog must still arm the cooldown.
      _askedThisSession = true;
      await _settings.setReviewLastAttemptMs(now);
      await _launcher.requestReview();
      return true;
    } catch (e) {
      // Play Review is unavailable on some devices/F-Droid-style setups or
      // fails transiently. Never propagate — the earned moment just ends.
      debugPrint('Review flow failed: $e');
      return false;
    }
  }

  /// Settings row: user explicitly asked for the rating screen. Bypasses the
  /// earned-moment gates (it IS the user's decision) but still records the
  /// attempt so the automatic prompt stays on the same 30-day rhythm.
  Future<void> openRatingScreen() async {
    try {
      if (await _launcher.isAvailable()) {
        await _settings.setReviewLastAttemptMs(
          _now().millisecondsSinceEpoch,
      );
        await _launcher.requestReview();
      } else {
        await _launcher.openStoreListing();
      }
    } catch (e) {
      debugPrint('Rating screen failed: $e');
      // Last resort: the plain store listing still lets them rate.
      try {
        await _launcher.openStoreListing();
      } catch (e2) {
        debugPrint('Store listing also failed: $e2');
      }
    }
  }
}