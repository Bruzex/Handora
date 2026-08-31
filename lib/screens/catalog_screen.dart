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
import '../widgets/shimmer_product_card.dart';

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

          // Offline Sync Banner (shown when unsynced items exist in SQLite)
          if (data.hasPendingSync) ...[
            GestureDetector(
              onTap: data.isSyncing ? null : () => data.syncOfflineProducts(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: dark ? AppColors.ink800 : AppColors.amber100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.amber600.withAlpha(dark ? 120 : 180),
                    width: 1.5,
                  ),
                  boxShadow: kCardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.amber600.withAlpha(dark ? 60 : 30),
                        shape: BoxShape.circle,
                      ),
                      child: data.isSyncing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.amber600,
                              ),
                            )
                          : const Icon(
                              Icons.cloud_sync_rounded,
                              size: 22,
                              color: AppColors.amber600,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.isSyncing
                                ? (app.language == Language.hi
                                    ? 'क्लाउड पर सिंक हो रहा है...'
                                    : 'Syncing to cloud...')
                                : (app.language == Language.hi
                                    ? '${data.pendingSyncCount} प्रोडक्ट्स सिंक होना बाकी हैं। अभी सिंक करें।'
                                    : '${data.pendingSyncCount} items pending cloud sync. Tap to sync now.'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: dark ? Colors.white : AppColors.ink900,
                              height: 1.3,
                            ),
                          ),
                          if (!data.isSyncing) ...[
                            const SizedBox(height: 2),
                            Text(
                              app.language == Language.hi
                                  ? 'इंटरनेट कनेक्ट होने पर अपने आप सिंक होगा'
                                  : 'Will auto-sync when online',
                              style: TextStyle(
                                fontSize: 12,
                                color: dark ? Colors.white60 : AppColors.ink500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!data.isSyncing)
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.amber600,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

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

          // 2-column product grid (with shimmer card at top if AI processing)
          _buildProductGrid(products, s, app.language, data.isProcessingAi),
        ],
      ),
    );
  }

  Widget _buildProductGrid(
    List<Product> products,
    DashboardStrings s,
    Language lang,
    bool isProcessingAi,
  ) {
    final List<Widget> cardWidgets = [];

    // Prepend shimmer card at the top if Vision AI is actively processing
    if (isProcessingAi) {
      cardWidgets.add(const ShimmerProductCard());
    }

    for (final p in products) {
      cardWidgets.add(ProductCard(product: p, strings: s, language: lang));
    }

    final rows = <Widget>[];
    for (var i = 0; i < cardWidgets.length; i += 2) {
      final hasNext = i + 1 < cardWidgets.length;
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cardWidgets[i]),
              const SizedBox(width: 12),
              Expanded(
                child: hasNext
                    ? cardWidgets[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ));
    }
    return Column(children: rows);
  }
}
