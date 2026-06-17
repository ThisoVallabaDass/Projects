import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/offers_service.dart';
import '../theme/theme.dart';

class CustomerOfferWidgets {
  // Horizontal scrollable offer banner for vendor shops
  static Widget offerBanner({
    required String vendorId,
    double height = 120,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      height: height,
      padding: padding,
      child: StreamBuilder<List<OfferModel>>(
        stream: OffersService().getActiveVendorOffers(vendorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingBanner();
          }

          final offers = snapshot.data ?? [];
          if (offers.isEmpty) return const SizedBox.shrink();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: offers.length,
            itemBuilder: (context, index) => _buildOfferCard(offers[index]),
          );
        },
      ),
    );
  }

  // Featured offers carousel for homepage
  static Widget featuredOffersCarousel({
    double height = 160,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 16),
  }) {
    return Container(
      height: height,
      child: StreamBuilder<List<OfferModel>>(
        stream: OffersService().getFeaturedOffers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingBanner();
          }

          final offers = snapshot.data ?? [];
          if (offers.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: padding,
                child: Row(
                  children: [
                    Icon(Icons.local_fire_department, color: TinyTrailsColors.accent, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Hot Deals',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: padding,
                  itemCount: offers.length,
                  itemBuilder: (context, index) => _buildFeaturedOfferCard(offers[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Compact offer chip for cart/checkout
  static Widget offerChip({
    required OfferModel offer,
    VoidCallback? onTap,
    bool showCode = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [TinyTrailsColors.primary, TinyTrailsColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: TinyTrailsColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_offer, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              showCode ? offer.promoCode : _formatDiscountText(offer),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Coupon application widget for cart/checkout
  static Widget couponInputWidget({
    required String vendorId,
    required String userId,
    required double orderAmount,
    required List<String> productIds,
    required Function(CouponValidationResult) onCouponApplied,
  }) {
    return _CouponInputWidget(
      vendorId: vendorId,
      userId: userId,
      orderAmount: orderAmount,
      productIds: productIds,
      onCouponApplied: onCouponApplied,
    );
  }

  // Offer countdown timer
  static Widget offerCountdown({
    required DateTime endDate,
    TextStyle? textStyle,
  }) {
    return StreamBuilder<String>(
      stream: Stream.periodic(const Duration(seconds: 1), (_) {
        final remaining = endDate.difference(DateTime.now());
        if (remaining.isNegative) return 'Expired';

        final days = remaining.inDays;
        final hours = remaining.inHours % 24;
        final minutes = remaining.inMinutes % 60;
        final seconds = remaining.inSeconds % 60;

        if (days > 0) return '${days}d ${hours}h left';
        if (hours > 0) return '${hours}h ${minutes}m left';
        return '${minutes}m ${seconds}s left';
      }),
      builder: (context, snapshot) {
        return Text(
          snapshot.data ?? '',
          style: textStyle ?? TextStyle(
            fontSize: 12,
            color: TinyTrailsColors.accent,
            fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }

  // Helper methods
  static Widget _buildOfferCard(OfferModel offer) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [TinyTrailsColors.primary, TinyTrailsColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: TinyTrailsColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    offer.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatDiscountText(offer),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              offer.description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    offer.promoCode,
                    style: TextStyle(
                      color: TinyTrailsColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                offerCountdown(
                  endDate: offer.endDate,
                  textStyle: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildFeaturedOfferCard(OfferModel offer) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TinyTrailsColors.accent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: TinyTrailsColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.local_offer,
                    color: TinyTrailsColors.accent,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatDiscountText(offer),
                    style: TextStyle(
                      color: TinyTrailsColors.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              offer.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              offer.description,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  offer.promoCode,
                  style: TextStyle(
                    fontSize: 10,
                    color: TinyTrailsColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                offerCountdown(
                  endDate: offer.endDate,
                  textStyle: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildLoadingBanner() {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          width: 280,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static String _formatDiscountText(OfferModel offer) {
    switch (offer.type) {
      case OfferType.percentage:
        return '${offer.discountValue.toInt()}% OFF';
      case OfferType.fixedAmount:
        return '₹${offer.discountValue.toInt()} OFF';
      case OfferType.freeDelivery:
        return 'FREE DELIVERY';
      case OfferType.buyOneGetOne:
        return 'BOGO';
      default:
        return '${offer.discountValue.toInt()}% OFF';
    }
  }
}

// Coupon input widget implementation
class _CouponInputWidget extends StatefulWidget {
  final String vendorId;
  final String userId;
  final double orderAmount;
  final List<String> productIds;
  final Function(CouponValidationResult) onCouponApplied;

  const _CouponInputWidget({
    required this.vendorId,
    required this.userId,
    required this.orderAmount,
    required this.productIds,
    required this.onCouponApplied,
  });

  @override
  State<_CouponInputWidget> createState() => _CouponInputWidgetState();
}

class _CouponInputWidgetState extends State<_CouponInputWidget> {
  final TextEditingController _couponController = TextEditingController();
  final OffersService _offersService = OffersService();

  bool _isValidating = false;
  CouponValidationResult? _lastResult;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer_outlined, color: TinyTrailsColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Have a coupon?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Available coupons preview
          StreamBuilder<List<OfferModel>>(
            stream: _offersService.getActiveVendorOffers(widget.vendorId),
            builder: (context, snapshot) {
              final offers = snapshot.data ?? [];
              if (offers.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available offers:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 35,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: offers.length,
                      itemBuilder: (context, index) => CustomerOfferWidgets.offerChip(
                        offer: offers[index],
                        onTap: () {
                          _couponController.text = offers[index].promoCode;
                          _validateCoupon();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
          // Coupon input
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _couponController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Enter coupon code',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (_) {
                    if (_lastResult != null) {
                      setState(() {
                        _lastResult = null;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isValidating ? null : _validateCoupon,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TinyTrailsColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: _isValidating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Apply'),
              ),
            ],
          ),
          // Result display
          if (_lastResult != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _lastResult!.isValid
                    ? TinyTrailsColors.success.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _lastResult!.isValid
                      ? TinyTrailsColors.success
                      : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _lastResult!.isValid ? Icons.check_circle : Icons.error,
                    color: _lastResult!.isValid
                        ? TinyTrailsColors.success
                        : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _lastResult!.isValid
                          ? 'Coupon applied! You save ₹${_lastResult!.discountAmount!.toInt()}'
                          : _lastResult!.error!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _lastResult!.isValid
                            ? TinyTrailsColors.success
                            : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _validateCoupon() async {
    if (_couponController.text.trim().isEmpty) return;

    setState(() {
      _isValidating = true;
    });

    try {
      final result = await _offersService.validateCoupon(
        promoCode: _couponController.text.trim(),
        userId: widget.userId,
        vendorId: widget.vendorId,
        orderAmount: widget.orderAmount,
        productIds: widget.productIds,
      );

      setState(() {
        _lastResult = result;
        _isValidating = false;
      });

      // Notify parent
      widget.onCouponApplied(result);

      // Haptic feedback
      if (result.isValid) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.selectionClick();
      }

    } catch (e) {
      setState(() {
        _lastResult = CouponValidationResult(
          isValid: false,
          error: 'Failed to validate coupon',
        );
        _isValidating = false;
      });
    }
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }
}