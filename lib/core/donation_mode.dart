/// Compile-time switch that selects how the "Support Loopweek" entry in
/// Settings is wired up.
///
/// The build pipeline passes `DONATION_MODE` via `--dart-define`:
///
///   * `polar` (default) — Settings shows the polar.sh "buy me a coffee" link.
///     Used for the GitHub flavor / open-source builds so contributors see the
///     existing external checkout.
///   * `iap`               — Settings shows Google Play in-app tip tiers
///     instead, and the polar.sh link is unreachable (the code path that
///     references [DevLinks.support] is eliminated by dead-branch pruning
///     under AOT). Used for the `playstore` flavor uploaded to Google Play,
///     which forbids external donation links for digital goods.
///
/// Because the value comes from [String.fromEnvironment], comparisons against
/// [donationMode] are compile-time constants: the unreachable branch is
/// tree-shaken in release builds so the secret polar URL never ends up in the
/// Play AAB even transitively.
enum DonationMode { polar, iap }

final DonationMode donationMode = switch (const String.fromEnvironment(
  'DONATION_MODE',
  defaultValue: 'polar',
)) {
  'iap' => DonationMode.iap,
  _ => DonationMode.polar,
};
