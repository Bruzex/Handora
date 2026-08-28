import 'package:flutter/material.dart';
import '../theme/palette.dart';

class BusinessOverview extends StatelessWidget {
  final String title, salesLabel, salesValue, productsLabel, productsValue;

  const BusinessOverview({
    super.key,
    required this.title,
    required this.salesLabel,
    required this.salesValue,
    required this.productsLabel,
    required this.productsValue,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.ink500),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Metric(Icons.currency_rupee_rounded, salesLabel, salesValue, emphasis: true, dark: dark)),
          const SizedBox(width: 12),
          Expanded(child: _Metric(Icons.inventory_2_rounded, productsLabel, productsValue, dark: dark)),
        ]),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool emphasis;
  final bool dark;

  const _Metric(this.icon, this.label, this.value, {this.emphasis = false, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final bg = emphasis
        ? (dark ? AppColors.saffron600.withAlpha(30) : AppColors.saffron50)
        : (dark ? AppColors.ink800 : Colors.white);
    final border = emphasis ? AppColors.saffron200 : (dark ? AppColors.ink700 : AppColors.ink200);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: emphasis ? AppColors.saffron600 : AppColors.ink500),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.3, color: AppColors.ink700)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(
          fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5,
          color: emphasis ? AppColors.saffron700 : (dark ? Colors.white : AppColors.ink900),
        )),
      ]),
    );
  }
}
