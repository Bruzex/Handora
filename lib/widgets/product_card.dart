import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../models/product.dart';
import '../providers/data_provider.dart';
import '../theme/palette.dart';
import '../theme/shadows.dart';
import 'edit_voice_info_modal.dart';

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

  void _openVoiceEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditVoiceInfoModal(product: product),
    );
  }

  void _showDeleteDialog(BuildContext context, String productName) {
    final isHi = language == Language.hi;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isHi ? 'उत्पाद हटाएं?' : 'Delete Product?',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          isHi
              ? 'क्या आप वाकई "$productName" को अपने कैटलॉग और ONDC से हटाना चाहते हैं?'
              : 'Are you sure you want to remove "$productName" from your catalog & ONDC?',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isHi ? 'रद्द करें' : 'Cancel',
              style: const TextStyle(color: AppColors.ink500, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<DataProvider>().deleteProduct(product.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isHi
                          ? 'उत्पाद कैटलॉग और ONDC से हटा दिया गया'
                          : 'Product removed from catalog & ONDC',
                    ),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(
              isHi ? 'हटाएं' : 'Delete',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final live = product.status == ProductStatus.live;
    final name = language == Language.hi ? product.nameHi : product.nameEn;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isSynced = product.isSynced;

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
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: _buildImage(product.image),
              ),

              // Unsynced / Offline badge indicator overlay
              if (!isSynced)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.amber600,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(50),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          language == Language.hi ? 'सिंक बाकी' : 'Offline',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Delete icon button top right
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _showDeleteDialog(context, name),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(120),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Status badge (Amber for unsynced, Green for Live on ONDC, Gray for Draft)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: !isSynced
                        ? AppColors.amber100
                        : (live ? AppColors.green50 : AppColors.ink200.withAlpha(153)),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: !isSynced
                            ? AppColors.amber600
                            : (live ? AppColors.green600 : AppColors.ink500),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      !isSynced
                          ? (language == Language.hi ? 'सिंक होना बाकी' : 'Pending Sync')
                          : (live ? strings.statusLive : strings.statusDraft),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: !isSynced
                            ? AppColors.amber600
                            : (live ? AppColors.green800 : AppColors.ink700),
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

                // Action button — opens Edit Voice Info modal
                GestureDetector(
                  onTap: () => _openVoiceEdit(context),
                  child: Container(
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
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
