import 'package:flutter/foundation.dart';

/// Compile-time distribution gate, mirroring `donation_mode.dart`: GitHub
/// builds (DONATION_MODE=polar, the default) and Google Play builds
/// (DONATION_MODE=iap, passed by play-release.yml) share one codebase; the
/// AOT compiler tree-shakes the unused branch, so review/donation code only
/// actually exists on the playstore flavor.
enum ReviewMode { polar, iap }

/// Which distribution channel this build ships to.
final ReviewMode reviewMode = switch (const String.fromEnvironment(
  'DONATION_MODE',
  defaultValue: 'polar',
)) {
  'iap' => ReviewMode.iap,
  _ => ReviewMode.polar,
};

/// (Kept for reference: donation_mode.dart is the original of this pattern
/// and remains the gate for donation UI. This file adds nothing but the
/// review-facing name, so call sites read naturally.)
final reviewEnabled = reviewMode == ReviewMode.iap;

// Debug-only override hook, unused in release. Placeholder to keep the file
// honest about having no hidden behavior.
// ignore: unused_element
final _ = debugPrint;
