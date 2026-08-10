import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Describes one tip SKU. The [id] must match a consumable in-app product
/// you create in the Google Play Console (Monetize → Products → In-app
/// products). Prices/tier names are set in the Console; here we only pin the
/// SKU ids and the friendly text shown in the donation sheet.
@immutable
class DonationTier {
  const DonationTier({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
  });
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
}

/// Tip tiers surfaced in the donation sheet, ordered small → large. These
/// three SKU ids must exist verbatim in the Play Console for the playstore
/// flavor to display prices.
const List<DonationTier> kDonationTiers = <DonationTier>[
  DonationTier(
    id: 'tip_small',
    label: 'Small tip',
    subtitle: 'Buy me a coffee',
    icon: Icons.local_cafe,
  ),
  DonationTier(
    id: 'tip_medium',
    label: 'Medium tip',
    subtitle: 'Buy me a few coffees',
    icon: Icons.favorite,
  ),
  DonationTier(
    id: 'tip_large',
    label: 'Large tip',
    subtitle: 'Buy me lunch',
    icon: Icons.emoji_events,
  ),
];

/// State machine powering the donation sheet.
sealed class DonationState {
  const DonationState();
}

/// Initial state — products have not been queried yet.
class DonationIdle extends DonationState {
  const DonationIdle();
}

/// Querying product details from the store.
class DonationLoading extends DonationState {
  const DonationLoading();
}

/// Product details loaded; user can pick a tier.
class DonationReady extends DonationState {
  const DonationReady(this.products);
  final Map<String, ProductDetails> products;
  ProductDetails? operator [](String id) => products[id];
}

/// A purchase is in flight. The same [products] map is retained so the sheet
/// can keep showing prices while a single tier shows a spinner.
class DonationProcessing extends DonationState {
  const DonationProcessing(this.productId, this.products);
  final String? productId;
  final Map<String, ProductDetails> products;
  ProductDetails? operator [](String id) => products[id];
}

/// A purchase succeeded; the sheet shows a thank-you and dismisses.
class DonationSuccess extends DonationState {
  const DonationSuccess();
}

/// Loading failed or the purchase was rejected by the store.
class DonationError extends DonationState {
  const DonationError(this.message);
  final String message;
}

/// Tiny Riverpod-managed controller wrapping [InAppPurchase].
///
/// Lifecycle:
///   * On creation, subscribes to [InAppPurchase.instance.purchaseStream] and
///     queries the [kDonationTiers] SKUs so the sheet opens ready.
///   * [buy] fires a consumable purchase (auto-consumed); the stream drives
///     the transition to [DonationSuccess] / [DonationError] / back to ready.
///   * Disposed with the provider; the stream subscription is cancelled.
class IapDonationController extends ChangeNotifier {
  IapDonationController();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  DonationState _state = const DonationIdle();
  DonationState get state => _state;

  void _setState(DonationState s) {
    _state = s;
    notifyListeners();
  }

  Future<void> init() async {
    _sub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object e, StackTrace st) =>
          debugPrint('iap purchase stream error: $e'),
    );
    await load();
  }

  /// (Re)queries the store for the tier SKUs and transitions to
  /// [DonationReady], or [DonationError] if the query fails / returns no SKUs.
  Future<void> load() async {
    _setState(const DonationLoading());
    try {
      final res = await _iap.queryProductDetails(
        kDonationTiers.map((t) => t.id).toSet(),
      );
      if (res.error != null) {
        _setState(DonationError(res.error!.message));
        return;
      }
      final map = <String, ProductDetails>{
        for (final p in res.productDetails) p.id: p,
      };
      if (map.isEmpty) {
        _setState(
          const DonationError(
            'Tips are unavailable right now. Try again later.',
          ),
        );
        return;
      }
      _setState(DonationReady(map));
    } catch (e) {
      _setState(DonationError(e.toString()));
    }
  }

  /// Initiates a consumable purchase for [productId]. Only callable from the
  /// ready state — the UI disables interaction otherwise.
  Future<void> buy(String productId) async {
    final s = _state;
    if (s is! DonationReady) return;
    final product = s.products[productId];
    if (product == null) return;
    _setState(DonationProcessing(productId, s.products));
    final param = PurchaseParam(productDetails: product);
    final ok = await _iap.buyConsumable(
      purchaseParam: param,
      autoConsume: true,
    );
    if (!ok) {
      // The platform rejected the purchase flow (e.g. user dismissed the
      // bottom sheet before confirming). Drop back to ready so the user can
      // retry without the stream ever firing.
      _setState(DonationReady(s.products));
    }
  }

  void _onPurchases(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      _handlePurchase(p);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails p) async {
    switch (p.status) {
      case PurchaseStatus.pending:
        // Still in flight; the UI is already in DonationProcessing. The store
        // will deliver a follow-up event when it resolves.
        break;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // Auto-consumed consumable. Ack the purchase to the store if the
        // plugin still asks us to.
        if (p.pendingCompletePurchase) {
          try {
            await _iap.completePurchase(p);
          } catch (e) {
            debugPrint('iap completePurchase failed: $e');
          }
        }
        _setState(const DonationSuccess());
        break;
      case PurchaseStatus.error:
        _setState(DonationError(p.error?.message ?? 'Purchase failed.'));
        break;
      case PurchaseStatus.canceled:
        // Restore whatever products we had loaded so the sheet stays usable.
        final products = (_state is DonationProcessing)
            ? (_state as DonationProcessing).products
            : <String, ProductDetails>{};
        _setState(
          products.isEmpty ? const DonationIdle() : DonationReady(products),
        );
        // Reload to refresh the ready state if we had nothing cached.
        if (products.isEmpty) await load();
        break;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// One-per-process controller. Initialised eagerly when first read by the
/// donation sheet, which is opened from Settings only on the playstore flavor.
final iapDonationProvider = ChangeNotifierProvider<IapDonationController>((
  ref,
) {
  final c = IapDonationController();
  c.init();
  return c;
});
