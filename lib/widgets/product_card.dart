import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/product.dart';
import '../theme/palette.dart';
import '../theme/shadows.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final DashboardStrings strings;
  final Language language;

  const ProductCard({
    super.key,
    required this.product,
    required this.strings,
    required this.language,
  });

  Widget _buildImage(String image) {
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: AppColors.saffron50,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.saffron600,
                ),
              ),
            ),
          );
        },
        errorBuilder: (_, error, stackTrace) => Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.grey),
          ),
        ),
      );
    } else if (image.startsWith('assets/')) {
      return Image.asset(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.grey),
          ),
        ),
      );
    } else if (image.isNotEmpty && File(image).existsSync()) {
      return Image.file(File(image), fit: BoxFit.cover);
    } else {
      return Container(
        color: AppColors.saffron50,
        child: const Center(
          child: Icon(Icons.inventory_2_rounded, color: AppColors.saffron600, size: 36),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = product.status == ProductStatus.live;
    final name = language == Language.hi ? product.nameHi : product.nameEn;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: dark ? AppColors.ink800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dark ? AppColors.ink700 : AppColors.ink200),
        boxShadow: kCardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: _buildImage(product.image),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: live ? AppColors.green50 : AppColors.ink200.withAlpha(153),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: live ? AppColors.green600 : AppColors.ink500,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      live ? strings.statusLive : strings.statusDraft,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: live ? AppColors.green800 : AppColors.ink700,
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: dark ? Colors.white : AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.formattedPrice,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: dark ? Colors.white : AppColors.ink900,
                  ),
                ),
                const Spacer(),

                // Action button — filled for live, outlined for draft
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: live ? AppColors.saffron600 : (dark ? AppColors.ink800 : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: live ? null : Border.all(color: AppColors.saffron600, width: 2),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(
                      live ? Icons.mic_rounded : Icons.edit_rounded,
                      size: 16,
                      color: live ? Colors.white : AppColors.saffron700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      live ? strings.editVoiceInfo : strings.completeListing,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: live ? Colors.white : AppColors.saffron700,
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
