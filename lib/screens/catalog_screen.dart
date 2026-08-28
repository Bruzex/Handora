import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../models/product.dart';
import '../providers/app_state.dart';
import '../providers/data_provider.dart';
import '../screens/capture_screen.dart';
import '../theme/palette.dart';
import '../theme/shadows.dart';
import '../widgets/product_card.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  void _openCapture(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CaptureScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final data = context.watch<DataProvider>();
    final s = app.strings;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final products = data.products;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title with live count
          Text.rich(TextSpan(
            text: s.catalogTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: dark ? Colors.white : AppColors.ink900,
            ),
            children: [
              const TextSpan(text: ' '),
              TextSpan(
                text: '(${data.productCount})',
                style: const TextStyle(color: AppColors.ink500),
              ),
            ],
          )),
          const SizedBox(height: 16),

          // "+ Add New Product" button — opens AI Capture screen
          GestureDetector(
            onTap: () => _openCapture(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.saffron600,
                borderRadius: BorderRadius.circular(16),
                boxShadow: kLiftShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_rounded, size: 24, color: Colors.white),
                  const SizedBox(width: 10),
                  const Icon(Icons.mic_rounded, size: 24, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    '+ ${s.addNewProduct}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2-column product grid from DB
          _buildProductGrid(products, s, app.language),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products, DashboardStrings s, Language lang) {
    final rows = <Widget>[];
    for (var i = 0; i < products.length; i += 2) {
      final hasNext = i + 1 < products.length;
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: ProductCard(product: products[i], strings: s, language: lang)),
            const SizedBox(width: 12),
            Expanded(child: hasNext
                ? ProductCard(product: products[i + 1], strings: s, language: lang)
                : const SizedBox.shrink()),
          ]),
        ),
      ));
    }
    return Column(children: rows);
  }
}
