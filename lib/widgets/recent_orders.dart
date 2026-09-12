import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/order.dart';
import '../theme/palette.dart';
import '../theme/shadows.dart';
import 'order_details_modal.dart';

class RecentOrders extends StatelessWidget {
  final String title;
  final Language language;
  final List<Order> orders;

  const RecentOrders({
    super.key,
    required this.title,
    required this.language,
    required this.orders,
  });

  void _openOrderDetails(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OrderDetailsModal(order: order),
    );
  }

  Widget _buildThumbnail(String image) {
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return Image.network(image, width: 80, height: 80, fit: BoxFit.cover);
    } else if (image.startsWith('assets/')) {
      return Image.asset(image, width: 80, height: 80, fit: BoxFit.cover);
    } else {
      return Container(
        width: 80,
        height: 80,
        color: AppColors.saffron50,
        child: const Icon(Icons.inventory_2_rounded, color: AppColors.saffron600),
      );
    }
  }

  Color _getStatusColor(String status) {
    return switch (status.toLowerCase()) {
      'new' || 'new_order' => AppColors.amber600,
      'processing' => const Color(0xFF2563EB),
      'shipped' => const Color(0xFF9333EA),
      'delivered' => AppColors.green600,
      'cancelled' => AppColors.red600,
      _ => AppColors.ink500,
    };
  }

  String _getStatusLabel(String status, Language lang) {
    final s = kStrings[lang] ?? kStrings[Language.en]!;
    return switch (status.toLowerCase()) {
      'new' || 'new_order' => s.orderStatusNew,
      'processing' => s.orderStatusProcessing,
      'shipped' => s.orderStatusShipped,
      'delivered' => s.orderStatusDelivered,
      'cancelled' => s.orderStatusCancelled,
      _ => status,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = kStrings[language] ?? kStrings[Language.en]!;
    final dark = Theme.of(context).brightness == Brightness.dark;

    if (orders.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.ink500,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                s.noOrders,
                style: const TextStyle(color: AppColors.ink500, fontSize: 16),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.ink500,
              ),
            ),
            Text(
              '${orders.length} ${language == Language.en ? "orders" : "ऑर्डर"}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.saffron600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...orders.map((o) => _orderTile(context, o, s, dark)),
      ],
    );
  }

  Widget _orderTile(BuildContext context, Order o, DashboardStrings s, bool dark) {
    final isIndic = language != Language.en;
    final name = (isIndic && o.productHi.isNotEmpty) ? o.productHi : o.productEn;
    final statusColor = _getStatusColor(o.status);
    final statusLabel = _getStatusLabel(o.status, language);

    return GestureDetector(
      onTap: () => _openOrderDetails(context, o),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark ? AppColors.ink800 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: dark ? AppColors.ink700 : AppColors.ink200),
          boxShadow: kCardShadow,
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _buildThumbnail(o.thumbnail),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status badge & Order ID
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(dark ? 40 : 25),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: statusColor.withAlpha(80)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '#${o.id}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: dark ? Colors.white60 : AppColors.ink500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Product Name
                      Text(
                        '${o.quantity}x $name',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: dark ? Colors.white : AppColors.ink900,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Buyer & Time
                      Text(
                        '${o.buyerName} • ${o.placedAt}',
                        style: const TextStyle(fontSize: 13, color: AppColors.ink500),
                      ),
                      const SizedBox(height: 4),

                      // Amount
                      Text(
                        o.formattedAmount,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.saffron600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Open Order / WhatsApp Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: dark ? AppColors.ink900 : AppColors.saffron50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: dark ? AppColors.ink700 : AppColors.saffron200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_rounded,
                    size: 18,
                    color: Color(0xFF25D366),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    switch (language) {
                      Language.hi => 'ऑर्डर प्रबंधित करें व WhatsApp पर भेजें',
                      Language.mr => 'ऑर्डर व्यवस्थापित करा व WhatsApp वर पाठवा',
                      Language.ta => 'ஆர்டரை நிர்வகித்து WhatsApp இல் அனுப்பவும்',
                      Language.te => 'ఆర్డర్ నిర్వహించి WhatsApp లో పంపండి',
                      Language.gu => 'ઓર્ડર મેનેજ કરો અને WhatsApp મોકલો',
                      Language.bn => 'অর্ডার পরিচালনা করুন ও WhatsApp এ পাঠান',
                      Language.en => 'Manage & WhatsApp Buyer',
                    },
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.white : AppColors.ink900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
