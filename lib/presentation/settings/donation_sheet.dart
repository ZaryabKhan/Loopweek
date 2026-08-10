import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:loopweek/core/donation/iap_donation_service.dart';
import 'package:loopweek/core/haptics/haptics_service.dart';

/// Opens the tiered-playstore donation sheet. Only invoked from Settings on
/// the `iap` build (see [donationMode]).
Future<void> showDonationSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const _DonationSheet(),
  );
}

class _DonationSheet extends ConsumerStatefulWidget {
  const _DonationSheet();

  @override
  ConsumerState<_DonationSheet> createState() => _DonationSheetState();
}

class _DonationSheetState extends ConsumerState<_DonationSheet> {
  @override
  void initState() {
    super.initState();
    final c = ref.read(iapDonationProvider);
    if (c.state is DonationIdle || c.state is DonationError) {
      WidgetsBinding.instance.addPostFrameCallback((_) => c.load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = ref.watch(iapDonationProvider);
    final state = c.state;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Support Loopweek', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Pick a one-time tip. Tips keep Loopweek free and open-source.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          switch (state) {
            DonationIdle() || DonationLoading() => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            DonationError(:final message) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 40,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      Haptics.light();
                      c.load();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
            DonationReady(:final products) => Column(
              children: kDonationTiers
                  .map(
                    (t) => _TierTile(
                      tier: t,
                      price: products[t.id]?.price,
                      enabled: products[t.id] != null,
                      onTap: () {
                        Haptics.medium();
                        c.buy(t.id);
                      },
                    ),
                  )
                  .toList(),
            ),
            DonationProcessing(:final productId, :final products) => Column(
              children: kDonationTiers.map((t) {
                final processing = t.id == productId;
                return _TierTile(
                  tier: t,
                  price: products[t.id]?.price,
                  enabled: false,
                  isProcessing: processing,
                  onTap: () {},
                );
              }).toList(),
            ),
            DonationSuccess() => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(
                    Icons.favorite,
                    size: 44,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text('Thank you!', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Your tip helps keep Loopweek free for everyone.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Haptics.light();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          },
        ],
      ),
    );
  }
}

/// A single tappable tier row. Disabled when the SKU has not loaded yet or
/// while a purchase is in flight.
class _TierTile extends StatelessWidget {
  const _TierTile({
    required this.tier,
    required this.price,
    required this.enabled,
    required this.onTap,
    this.isProcessing = false,
  });

  final DonationTier tier;
  final String? price;
  final bool enabled;
  final bool isProcessing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final leadingColor = enabled
        ? theme.colorScheme.primary
        : theme.disabledColor;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      enabled: enabled,
      leading: SizedBox(
        width: 28,
        height: 28,
        child: isProcessing
            ? CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              )
            : Icon(tier.icon, color: leadingColor),
      ),
      title: Text(
        tier.label,
        style: theme.textTheme.titleMedium?.copyWith(
          color: enabled ? onSurface : theme.disabledColor,
        ),
      ),
      subtitle: Text(
        tier.subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: enabled
              ? onSurface.withValues(alpha: 0.6)
              : theme.disabledColor,
        ),
      ),
      trailing: price == null
          ? null
          : Text(
              price!,
              style: theme.textTheme.titleMedium?.copyWith(
                color: enabled
                    ? theme.colorScheme.primary
                    : theme.disabledColor,
              ),
            ),
      onTap: onTap,
    );
  }
}
