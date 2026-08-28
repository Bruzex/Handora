import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/order.dart';
import '../theme/palette.dart';
import '../theme/shadows.dart';

class RecentOrders extends StatelessWidget {
  final String title, statusLabel, whatsappLabel;
  final Language language;
  final List<Order> orders;
  final VoidCallback? onManage;

  const RecentOrders({
    super.key,
    required this.title,
    required this.statusLabel,
    required this.whatsappLabel,
    required this.language,
    required this.orders,
    this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    if (orders.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.ink500)),
          const SizedBox(height: 16),
          Center(child: Text('No orders yet', style: TextStyle(color: AppColors.ink500, fontSize: 16))),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.ink500)),
        const SizedBox(height: 12),
        ...orders.map((o) => _orderTile(o, dark)),
      ],
    );
  }

  Widget _orderTile(Order o, bool dark) {
    final name = language == Language.hi ? o.productHi : o.productEn;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.ink800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dark ? AppColors.ink700 : AppColors.ink200),
        boxShadow: kCardShadow,
      ),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(o.thumbnail, width: 80, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.saffron50, borderRadius: BorderRadius.circular(100)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.saffron600, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(statusLabel.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.saffron700)),
              ]),
            ),
            const SizedBox(height: 8),
            Text('${o.quantity}x $name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.3, color: dark ? Colors.white : AppColors.ink900)),
            const SizedBox(height: 2),
            Text('${o.formattedAmount} · ${o.placedAt}', style: const TextStyle(fontSize: 16, color: AppColors.ink500)),
          ])),
        ]),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onManage,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: dark ? AppColors.ink800 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.saffron600, width: 2),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.chat_rounded, size: 24, color: AppColors.saffron700),
              const SizedBox(width: 10),
              Text(whatsappLabel, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.saffron700)),
            ]),
          ),
        ),
      ]),
    );
  }
}
